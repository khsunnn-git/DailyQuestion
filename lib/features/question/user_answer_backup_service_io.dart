import "dart:async";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:isar/isar.dart";

import "../../core/kst_date_time.dart";
import "../../data/local_db/entities/answer_record_entity.dart";
import "../../data/local_db/local_database.dart";
import "today_question_store.dart";

const String _usersCollectionId = "users";
const String _answersCollectionId = "answers";

final _UserAnswerBackupCoordinator _userAnswerBackupCoordinator =
    _UserAnswerBackupCoordinator();

Future<void> startUserAnswerBackupService() {
  return _userAnswerBackupCoordinator.start();
}

Future<void> syncPendingUserAnswers({bool restoreRemoteOnConnect = false}) {
  return _userAnswerBackupCoordinator.syncPendingUserAnswers(
    restoreRemoteOnConnect: restoreRemoteOnConnect,
  );
}

Future<void> handleUserAnswerBackupAppLifecycleState(AppLifecycleState state) {
  return _userAnswerBackupCoordinator.handleAppLifecycleState(state);
}

class _UserAnswerBackupCoordinator {
  _UserAnswerBackupCoordinator({
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
      unawaited(syncPendingUserAnswers());
    }
  }

  Future<void> handleAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.resumed) {
      await syncPendingUserAnswers();
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
        syncPendingUserAnswers(
          restoreRemoteOnConnect: shouldRestoreRemoteOnConnect,
        ),
      );
    }
  }

  Future<void> syncPendingUserAnswers({
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
        await _syncPendingUserAnswersInternal(
          restoreRemoteOnConnect: shouldRestoreRemoteOnConnect,
        );
        shouldRestoreRemoteOnConnect = _queuedRestoreRemoteOnConnect;
      } while (_syncQueued);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint("[answer_backup] sync failed: $error");
        debugPrintStack(stackTrace: stackTrace);
      }
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> _syncPendingUserAnswersInternal({
    required bool restoreRemoteOnConnect,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      return;
    }

    final Isar isar = await LocalDatabase.instance.isar;
    final List<AnswerRecordEntity> existingEntities = await isar
        .answerRecordEntitys
        .where()
        .findAll();
    final bool hasVisibleLocalAnswers = existingEntities.any(
      (AnswerRecordEntity entity) => entity.deletedAt == null,
    );
    final bool restoredRemote =
        (restoreRemoteOnConnect || !hasVisibleLocalAnswers)
        ? await _mergeRemoteAnswers(isar: isar, uid: user.uid)
        : false;

    final List<AnswerRecordEntity> entities = await isar.answerRecordEntitys
        .where()
        .findAll();
    final List<AnswerRecordEntity> pending =
        entities.where(_isPendingEntity).toList(growable: false)
          ..sort((AnswerRecordEntity a, AnswerRecordEntity b) {
            return a.createdAt.compareTo(b.createdAt);
          });
    if (pending.isEmpty) {
      if (restoredRemote) {
        await TodayQuestionStore.instance.reloadFromDatabase();
      }
      return;
    }

    bool deletedLocally = false;
    for (final AnswerRecordEntity entity in pending) {
      if (entity.deletedAt != null) {
        await _remoteAnswerDoc(
          uid: user.uid,
          createdAtMillis: entity.createdAtMillis,
        ).delete();
        await _deleteLocalEntity(entity.id);
        deletedLocally = true;
        continue;
      }
      await _remoteAnswerDoc(
        uid: user.uid,
        createdAtMillis: entity.createdAtMillis,
      ).set(_entityToRemoteMap(entity), SetOptions(merge: true));
      await _markEntitySynced(entity.id);
    }

    if (restoredRemote || deletedLocally) {
      await TodayQuestionStore.instance.reloadFromDatabase();
    }
  }

  bool _isPendingEntity(AnswerRecordEntity entity) {
    return entity.remoteSyncStatus == null ||
        entity.remoteSyncStatus == answerRemoteSyncPendingUpsert ||
        entity.remoteSyncStatus == answerRemoteSyncPendingDelete;
  }

  Future<bool> _mergeRemoteAnswers({
    required Isar isar,
    required String uid,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection(_usersCollectionId)
        .doc(uid)
        .collection(_answersCollectionId)
        .get();
    if (snapshot.docs.isEmpty) {
      return false;
    }

    bool changed = false;
    await isar.writeTxn(() async {
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final AnswerRecordEntity incoming = _remoteDocToEntity(doc);
        final AnswerRecordEntity? existing = await isar.answerRecordEntitys
            .filter()
            .createdAtMillisEqualTo(incoming.createdAtMillis)
            .findFirst();
        if (existing != null) {
          if (existing.remoteSyncStatus == answerRemoteSyncPendingUpsert ||
              existing.remoteSyncStatus == answerRemoteSyncPendingDelete) {
            continue;
          }
          if (!incoming.updatedAt.isAfter(existing.updatedAt)) {
            continue;
          }
          incoming.id = existing.id;
        }
        changed = true;
        await isar.answerRecordEntitys.put(incoming);
      }
    });
    return changed;
  }

  Map<String, dynamic> _entityToRemoteMap(AnswerRecordEntity entity) {
    return <String, dynamic>{
      "createdAtMillis": entity.createdAtMillis,
      "createdAt": Timestamp.fromDate(entity.createdAt),
      "answer": entity.answer,
      "author": entity.author,
      "bucketTag": entity.bucketTag,
      "bucketTags": List<String>.from(entity.bucketTags),
      "isPublic": entity.isPublic,
      "questionSlot": entity.questionSlot,
      "questionDayOfYear": entity.questionDayOfYear,
      "questionDateKey": entity.questionDateKey,
      "questionText": entity.questionText,
      "moodScore5": entity.moodScore5,
      "energyScore5": entity.energyScore5,
      "stressScore5": entity.stressScore5,
      "updatedAtMillis": entity.updatedAt.millisecondsSinceEpoch,
      "updatedAt": FieldValue.serverTimestamp(),
    };
  }

  AnswerRecordEntity _remoteDocToEntity(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data();
    final Timestamp? createdAtTimestamp = data["createdAt"] as Timestamp?;
    final int createdAtMillis =
        (data["createdAtMillis"] as num?)?.toInt() ??
        createdAtTimestamp?.millisecondsSinceEpoch ??
        int.tryParse(doc.id) ??
        DateTime.now().millisecondsSinceEpoch;
    final Timestamp? updatedAtTimestamp = data["updatedAt"] as Timestamp?;
    final int updatedAtMillis =
        (data["updatedAtMillis"] as num?)?.toInt() ??
        updatedAtTimestamp?.millisecondsSinceEpoch ??
        createdAtMillis;
    return AnswerRecordEntity()
      ..createdAtMillis = createdAtMillis
      ..createdAt =
          createdAtTimestamp?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(createdAtMillis)
      ..answer = "${data["answer"] ?? ""}"
      ..author = "${data["author"] ?? ""}"
      ..bucketTag = data["bucketTag"] as String?
      ..bucketTags = (data["bucketTags"] is List)
          ? (data["bucketTags"] as List<dynamic>)
                .map((dynamic item) => "$item")
                .toList(growable: false)
          : <String>[]
      ..isPublic = data["isPublic"] == true
      ..questionSlot = (data["questionSlot"] as num?)?.toInt() ?? 0
      ..questionDayOfYear = (data["questionDayOfYear"] as num?)?.toInt()
      ..questionDateKey = "${data["questionDateKey"] ?? ""}"
      ..questionText = data["questionText"] as String?
      ..moodScore5 = (data["moodScore5"] as num?)?.toInt()
      ..energyScore5 = (data["energyScore5"] as num?)?.toInt()
      ..stressScore5 = (data["stressScore5"] as num?)?.toInt()
      ..updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedAtMillis)
      ..remoteSyncStatus = answerRemoteSyncSynced
      ..remoteSyncedAt = nowInKst()
      ..deletedAt = null;
  }

  Future<void> _markEntitySynced(Id entityId) async {
    final Isar isar = await LocalDatabase.instance.isar;
    await isar.writeTxn(() async {
      final AnswerRecordEntity? entity = await isar.answerRecordEntitys.get(
        entityId,
      );
      if (entity == null) {
        return;
      }
      entity.remoteSyncStatus = answerRemoteSyncSynced;
      entity.remoteSyncedAt = nowInKst();
      await isar.answerRecordEntitys.put(entity);
    });
  }

  Future<void> _deleteLocalEntity(Id entityId) async {
    final Isar isar = await LocalDatabase.instance.isar;
    await isar.writeTxn(() async {
      await isar.answerRecordEntitys.delete(entityId);
    });
  }

  DocumentReference<Map<String, dynamic>> _remoteAnswerDoc({
    required String uid,
    required int createdAtMillis,
  }) {
    return _firestore
        .collection(_usersCollectionId)
        .doc(uid)
        .collection(_answersCollectionId)
        .doc("$createdAtMillis");
  }
}
