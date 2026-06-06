import "dart:async";
import "dart:math" as math;

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:isar_community/isar.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../data/local_db/entities/daily_checkin_entity.dart";
import "../../data/local_db/local_database.dart";
import "../report/ai_report_regeneration_service.dart";
import "daily_checkin_store.dart";

const String _usersCollectionId = "users";
const String _dailyCheckinsCollectionId = "dailyCheckins";
const String _hasSyncedPrefsKey = "daily_checkin_backup_has_synced";

final _DailyCheckinBackupCoordinator _dailyCheckinBackupCoordinator =
    _DailyCheckinBackupCoordinator();

Future<void> startDailyCheckinBackupService() {
  return _dailyCheckinBackupCoordinator.start();
}

Future<void> syncDailyCheckinBackup({bool restoreRemoteOnConnect = false}) {
  return _dailyCheckinBackupCoordinator.syncDailyCheckinBackup(
    restoreRemoteOnConnect: restoreRemoteOnConnect,
  );
}

Future<void> deleteRemoteDailyCheckinBackup({String? uid}) {
  return _dailyCheckinBackupCoordinator.deleteRemoteDailyCheckinBackup(
    uid: uid,
  );
}

Future<void> handleDailyCheckinBackupAppLifecycleState(
  AppLifecycleState state,
) {
  return _dailyCheckinBackupCoordinator.handleAppLifecycleState(state);
}

class _DailyCheckinBackupCoordinator {
  _DailyCheckinBackupCoordinator({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  bool _started = false;
  bool _wasConnectedProvider = false;
  String? _lastObservedUserUid;
  bool _syncInProgress = false;
  bool _syncQueued = false;
  bool _queuedRestoreRemoteOnConnect = false;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    _lastObservedUserUid = _auth.currentUser?.uid;
    _wasConnectedProvider =
        _auth.currentUser != null && !_auth.currentUser!.isAnonymous;
    _auth.userChanges().listen(_handleAuthStateChanged);
    if (_wasConnectedProvider) {
      unawaited(syncDailyCheckinBackup(restoreRemoteOnConnect: true));
    }
  }

  Future<void> handleAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.resumed) {
      await syncDailyCheckinBackup();
    }
  }

  void _handleAuthStateChanged(User? user) {
    final bool isConnectedProvider = user != null && !user.isAnonymous;
    final String? nextUid = user?.uid;
    if (isConnectedProvider == _wasConnectedProvider &&
        nextUid == _lastObservedUserUid) {
      return;
    }

    final bool shouldRestoreRemoteOnConnect =
        isConnectedProvider && !_wasConnectedProvider;
    _wasConnectedProvider = isConnectedProvider;
    _lastObservedUserUid = nextUid;
    if (isConnectedProvider) {
      unawaited(
        syncDailyCheckinBackup(
          restoreRemoteOnConnect: shouldRestoreRemoteOnConnect,
        ),
      );
    }
  }

  Future<void> syncDailyCheckinBackup({
    bool restoreRemoteOnConnect = false,
  }) async {
    if (_syncInProgress) {
      _syncQueued = true;
      _queuedRestoreRemoteOnConnect =
          _queuedRestoreRemoteOnConnect || restoreRemoteOnConnect;
      return;
    }

    _syncInProgress = true;
    bool shouldRestoreRemoteOnConnect = restoreRemoteOnConnect;
    try {
      do {
        _syncQueued = false;
        _queuedRestoreRemoteOnConnect = false;
        await _syncDailyCheckinBackupInternal(
          restoreRemoteOnConnect: shouldRestoreRemoteOnConnect,
        );
        shouldRestoreRemoteOnConnect = _queuedRestoreRemoteOnConnect;
      } while (_syncQueued);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint("[daily_checkin_backup] sync failed: $error");
        debugPrintStack(stackTrace: stackTrace);
      }
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> deleteRemoteDailyCheckinBackup({String? uid}) async {
    final String? targetUid = uid ?? _auth.currentUser?.uid;
    if (targetUid == null || targetUid.isEmpty) {
      return;
    }
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _remoteCheckins(
      targetUid,
    ).get();
    await _deleteDocumentReferences(
      snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.reference,
          )
          .toList(growable: false),
    );
  }

  Future<void> _syncDailyCheckinBackupInternal({
    required bool restoreRemoteOnConnect,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      return;
    }

    final Isar isar = await LocalDatabase.instance.isar;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<DailyCheckinEntity> localCheckins = await isar
        .dailyCheckinEntitys
        .where()
        .findAll();
    final bool hasLocalCheckins = localCheckins.isNotEmpty;
    final bool hasSyncedBefore = prefs.getBool(_hasSyncedPrefsKey) ?? false;

    bool restored = false;
    if (!hasLocalCheckins && (!hasSyncedBefore || restoreRemoteOnConnect)) {
      restored = await _restoreRemoteCheckins(isar: isar, uid: user.uid);
      if (restored) {
        await prefs.setBool(_hasSyncedPrefsKey, true);
        await DailyCheckinStore.instance.reloadToday();
        unawaited(queueAiReportRegeneration());
        return;
      }
    }

    final List<DailyCheckinEntity> nextCheckins = await isar.dailyCheckinEntitys
        .where()
        .findAll();
    await _replaceRemoteCheckins(uid: user.uid, checkins: nextCheckins);
    await prefs.setBool(_hasSyncedPrefsKey, true);
  }

  Future<bool> _restoreRemoteCheckins({
    required Isar isar,
    required String uid,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _remoteCheckins(
      uid,
    ).get();
    if (snapshot.docs.isEmpty) {
      return false;
    }

    final List<DailyCheckinEntity> incoming = snapshot.docs
        .map(_remoteDocToEntity)
        .toList(growable: false);
    await isar.writeTxn(() async {
      for (final DailyCheckinEntity item in incoming) {
        final DailyCheckinEntity? existing = await isar.dailyCheckinEntitys
            .where()
            .dateKeyEqualTo(item.dateKey)
            .findFirst();
        if (existing != null && existing.updatedAt.isAfter(item.updatedAt)) {
          continue;
        }
        if (existing != null) {
          item.id = existing.id;
        }
        await isar.dailyCheckinEntitys.putByDateKey(item);
      }
    });
    return incoming.isNotEmpty;
  }

  Future<void> _replaceRemoteCheckins({
    required String uid,
    required List<DailyCheckinEntity> checkins,
  }) async {
    final CollectionReference<Map<String, dynamic>> remoteCheckins =
        _remoteCheckins(uid);
    final Set<String> nextIds = checkins.map(_checkinDocId).toSet();
    final QuerySnapshot<Map<String, dynamic>> snapshot = await remoteCheckins
        .get();
    final List<DocumentReference<Map<String, dynamic>>> staleRefs =
        <DocumentReference<Map<String, dynamic>>>[
          for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
              in snapshot.docs)
            if (!nextIds.contains(doc.id)) doc.reference,
        ];

    await _deleteDocumentReferences(staleRefs);
    for (int start = 0; start < checkins.length; start += 450) {
      final WriteBatch batch = _firestore.batch();
      final Iterable<DailyCheckinEntity> chunk = checkins.skip(start).take(450);
      for (final DailyCheckinEntity item in chunk) {
        batch.set(
          remoteCheckins.doc(_checkinDocId(item)),
          _entityToRemoteMap(item),
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
  }

  CollectionReference<Map<String, dynamic>> _remoteCheckins(String uid) {
    return _firestore
        .collection(_usersCollectionId)
        .doc(uid)
        .collection(_dailyCheckinsCollectionId);
  }

  String _checkinDocId(DailyCheckinEntity item) {
    return item.dateKey.replaceAll("/", "_");
  }

  Map<String, Object?> _entityToRemoteMap(DailyCheckinEntity item) {
    return <String, Object?>{
      "dateKey": item.dateKey,
      "createdAtMillis": item.createdAt.millisecondsSinceEpoch,
      "updatedAtMillis": item.updatedAt.millisecondsSinceEpoch,
      "moodIndex": item.moodIndex,
      "energyIndex": item.energyIndex,
      "stressIndex": item.stressIndex,
      "schemaVersion": 1,
    };
  }

  DailyCheckinEntity _remoteDocToEntity(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data();
    final DailyCheckinEntity item = DailyCheckinEntity()
      ..dateKey = _stringValue(data["dateKey"], fallback: doc.id)
      ..createdAt = _dateTimeValue(data["createdAtMillis"])
      ..updatedAt = _dateTimeValue(data["updatedAtMillis"])
      ..moodIndex = _indexValue(data["moodIndex"])
      ..energyIndex = _indexValue(data["energyIndex"])
      ..stressIndex = _indexValue(data["stressIndex"]);
    return item;
  }

  String _stringValue(Object? raw, {required String fallback}) {
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    return fallback;
  }

  DateTime _dateTimeValue(Object? raw) {
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    }
    if (raw is Timestamp) {
      return raw.toDate();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  int? _indexValue(Object? raw) {
    if (raw is int) {
      return raw >= 0 && raw <= 4 ? raw : null;
    }
    if (raw is num) {
      final int value = raw.toInt();
      return value >= 0 && value <= 4 ? value : null;
    }
    return null;
  }

  Future<void> _deleteDocumentReferences(
    List<DocumentReference<Map<String, dynamic>>> refs,
  ) async {
    for (int start = 0; start < refs.length; start += 450) {
      final WriteBatch batch = _firestore.batch();
      for (final DocumentReference<Map<String, dynamic>> ref
          in refs.skip(start).take(math.min(450, refs.length - start))) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }
}
