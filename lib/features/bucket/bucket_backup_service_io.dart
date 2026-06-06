import "dart:async";
import "dart:convert";
import "dart:math" as math;

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:isar_community/isar.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../data/local_db/entities/bucket_category_entity.dart";
import "../../data/local_db/entities/bucket_item_entity.dart";
import "../../data/local_db/local_database.dart";

const String _usersCollectionId = "users";
const String _bucketItemsCollectionId = "bucketItems";
const String _bucketCategoriesCollectionId = "bucketCategories";
const String _hasSyncedPrefsKey = "bucket_backup_has_synced";

final _BucketBackupCoordinator _bucketBackupCoordinator =
    _BucketBackupCoordinator();

Future<void> startBucketBackupService() {
  return _bucketBackupCoordinator.start();
}

Future<void> syncBucketBackup({bool restoreRemoteOnConnect = false}) {
  return _bucketBackupCoordinator.syncBucketBackup(
    restoreRemoteOnConnect: restoreRemoteOnConnect,
  );
}

Future<void> deleteRemoteBucketBackup({String? uid}) {
  return _bucketBackupCoordinator.deleteRemoteBucketBackup(uid: uid);
}

Future<void> handleBucketBackupAppLifecycleState(AppLifecycleState state) {
  return _bucketBackupCoordinator.handleAppLifecycleState(state);
}

class _BucketBackupCoordinator {
  _BucketBackupCoordinator({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
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
      unawaited(syncBucketBackup(restoreRemoteOnConnect: true));
    }
  }

  Future<void> handleAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.resumed) {
      await syncBucketBackup();
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
        syncBucketBackup(restoreRemoteOnConnect: shouldRestoreRemoteOnConnect),
      );
    }
  }

  Future<void> syncBucketBackup({bool restoreRemoteOnConnect = false}) async {
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
        await _syncBucketBackupInternal(
          restoreRemoteOnConnect: shouldRestoreRemoteOnConnect,
        );
        shouldRestoreRemoteOnConnect = _queuedRestoreRemoteOnConnect;
      } while (_syncQueued);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint("[bucket_backup] sync failed: $error");
        debugPrintStack(stackTrace: stackTrace);
      }
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> deleteRemoteBucketBackup({String? uid}) async {
    final String? targetUid = uid ?? _auth.currentUser?.uid;
    if (targetUid == null || targetUid.isEmpty) {
      return;
    }
    await _deleteCollection(
      _firestore
          .collection(_usersCollectionId)
          .doc(targetUid)
          .collection(_bucketItemsCollectionId),
    );
    await _deleteCollection(
      _firestore
          .collection(_usersCollectionId)
          .doc(targetUid)
          .collection(_bucketCategoriesCollectionId),
    );
  }

  Future<void> _syncBucketBackupInternal({
    required bool restoreRemoteOnConnect,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      return;
    }

    final Isar isar = await LocalDatabase.instance.isar;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<BucketItemEntity> localItems = await isar.bucketItemEntitys
        .where()
        .findAll();
    final List<BucketCategoryEntity> localCategories = await isar
        .bucketCategoryEntitys
        .where()
        .findAll();
    final bool hasLocalBuckets =
        localItems.isNotEmpty || localCategories.isNotEmpty;
    final bool hasSyncedBefore = prefs.getBool(_hasSyncedPrefsKey) ?? false;

    if (!hasLocalBuckets && !hasSyncedBefore) {
      final bool restored = await _restoreRemoteBuckets(
        isar: isar,
        uid: user.uid,
      );
      if (restored) {
        await prefs.setBool(_hasSyncedPrefsKey, true);
      }
      return;
    }

    if (restoreRemoteOnConnect && !hasLocalBuckets) {
      await _restoreRemoteBuckets(isar: isar, uid: user.uid);
    }

    final List<BucketItemEntity> nextItems = await isar.bucketItemEntitys
        .where()
        .findAll();
    final List<BucketCategoryEntity> nextCategories = await isar
        .bucketCategoryEntitys
        .where()
        .findAll();
    await _replaceRemoteBuckets(
      uid: user.uid,
      items: nextItems,
      categories: nextCategories,
    );
    await prefs.setBool(_hasSyncedPrefsKey, true);
  }

  Future<bool> _restoreRemoteBuckets({
    required Isar isar,
    required String uid,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> itemSnapshot = await _firestore
        .collection(_usersCollectionId)
        .doc(uid)
        .collection(_bucketItemsCollectionId)
        .get();
    final QuerySnapshot<Map<String, dynamic>> categorySnapshot =
        await _firestore
            .collection(_usersCollectionId)
            .doc(uid)
            .collection(_bucketCategoriesCollectionId)
            .get();
    if (itemSnapshot.docs.isEmpty && categorySnapshot.docs.isEmpty) {
      return false;
    }

    final List<BucketItemEntity> items = itemSnapshot.docs
        .map(_remoteItemDocToEntity)
        .toList(growable: false);
    final List<BucketCategoryEntity> categories = categorySnapshot.docs
        .map(_remoteCategoryDocToEntity)
        .toList(growable: false);

    await isar.writeTxn(() async {
      await isar.bucketItemEntitys.clear();
      if (items.isNotEmpty) {
        await isar.bucketItemEntitys.putAll(items);
      }
      await isar.bucketCategoryEntitys.clear();
      if (categories.isNotEmpty) {
        await isar.bucketCategoryEntitys.putAll(categories);
      }
    });
    return true;
  }

  Future<void> _replaceRemoteBuckets({
    required String uid,
    required List<BucketItemEntity> items,
    required List<BucketCategoryEntity> categories,
  }) async {
    final CollectionReference<Map<String, dynamic>> remoteItems = _firestore
        .collection(_usersCollectionId)
        .doc(uid)
        .collection(_bucketItemsCollectionId);
    final CollectionReference<Map<String, dynamic>> remoteCategories =
        _firestore
            .collection(_usersCollectionId)
            .doc(uid)
            .collection(_bucketCategoriesCollectionId);

    final Set<String> nextItemIds = items.map(_bucketItemDocId).toSet();
    final Set<String> nextCategoryIds = categories
        .map(_bucketCategoryDocId)
        .toSet();
    final List<DocumentReference<Map<String, dynamic>>> staleRefs =
        <DocumentReference<Map<String, dynamic>>>[];

    final QuerySnapshot<Map<String, dynamic>> itemSnapshot = await remoteItems
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in itemSnapshot.docs) {
      if (!nextItemIds.contains(doc.id)) {
        staleRefs.add(doc.reference);
      }
    }

    final QuerySnapshot<Map<String, dynamic>> categorySnapshot =
        await remoteCategories.get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in categorySnapshot.docs) {
      if (!nextCategoryIds.contains(doc.id)) {
        staleRefs.add(doc.reference);
      }
    }

    await _deleteDocumentReferences(staleRefs);
    final List<_RemoteWrite> writes = <_RemoteWrite>[
      ...items.map(
        (BucketItemEntity item) => _RemoteWrite(
          ref: remoteItems.doc(_bucketItemDocId(item)),
          data: _bucketItemToRemoteMap(item),
        ),
      ),
      ...categories.map(
        (BucketCategoryEntity category) => _RemoteWrite(
          ref: remoteCategories.doc(_bucketCategoryDocId(category)),
          data: _bucketCategoryToRemoteMap(category),
        ),
      ),
    ];
    await _writeDocuments(writes);
  }

  Map<String, dynamic> _bucketItemToRemoteMap(BucketItemEntity item) {
    return <String, dynamic>{
      "localId": item.id,
      "title": item.title,
      "category": item.category,
      "categoryColorValue": item.categoryColorValue,
      "createdAtMillis": item.createdAt.millisecondsSinceEpoch,
      "createdAt": Timestamp.fromDate(item.createdAt),
      "dueDateMillis": item.dueDate?.millisecondsSinceEpoch,
      "dueDate": item.dueDate == null
          ? null
          : Timestamp.fromDate(item.dueDate!),
      "isCompleted": item.isCompleted,
      "updatedAtMillis": item.updatedAt.millisecondsSinceEpoch,
      "updatedAt": Timestamp.fromDate(item.updatedAt),
      "remoteSyncedAt": FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _bucketCategoryToRemoteMap(BucketCategoryEntity item) {
    return <String, dynamic>{
      "localId": item.id,
      "name": item.name,
      "colorValue": item.colorValue,
      "remoteSyncedAt": FieldValue.serverTimestamp(),
    };
  }

  BucketItemEntity _remoteItemDocToEntity(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data();
    final int createdAtMillis =
        (data["createdAtMillis"] as num?)?.toInt() ??
        (data["createdAt"] as Timestamp?)?.toDate().millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;
    final int updatedAtMillis =
        (data["updatedAtMillis"] as num?)?.toInt() ??
        (data["updatedAt"] as Timestamp?)?.toDate().millisecondsSinceEpoch ??
        createdAtMillis;
    final int? dueDateMillis =
        (data["dueDateMillis"] as num?)?.toInt() ??
        (data["dueDate"] as Timestamp?)?.toDate().millisecondsSinceEpoch;
    return BucketItemEntity()
      ..id = (data["localId"] as num?)?.toInt() ?? Isar.autoIncrement
      ..title = "${data["title"] ?? ""}"
      ..category = "${data["category"] ?? ""}"
      ..categoryColorValue = (data["categoryColorValue"] as num?)?.toInt() ?? 0
      ..createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtMillis)
      ..dueDate = dueDateMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(dueDateMillis)
      ..isCompleted = data["isCompleted"] == true
      ..updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedAtMillis);
  }

  BucketCategoryEntity _remoteCategoryDocToEntity(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data();
    return BucketCategoryEntity()
      ..id = (data["localId"] as num?)?.toInt() ?? Isar.autoIncrement
      ..name = "${data["name"] ?? doc.id}"
      ..colorValue = (data["colorValue"] as num?)?.toInt() ?? 0;
  }

  String _bucketItemDocId(BucketItemEntity item) {
    return "${item.createdAt.millisecondsSinceEpoch}_${item.id}";
  }

  String _bucketCategoryDocId(BucketCategoryEntity item) {
    final String encoded = base64Url
        .encode(utf8.encode(item.name))
        .replaceAll("=", "");
    return encoded.isEmpty ? "default" : encoded;
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await collection.get();
    await _deleteDocumentReferences(
      snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.reference,
          )
          .toList(growable: false),
    );
  }

  Future<void> _deleteDocumentReferences(
    List<DocumentReference<Map<String, dynamic>>> refs,
  ) async {
    if (refs.isEmpty) {
      return;
    }
    const int batchLimit = 450;
    for (int i = 0; i < refs.length; i += batchLimit) {
      final int end = math.min(i + batchLimit, refs.length);
      final WriteBatch batch = _firestore.batch();
      for (final DocumentReference<Map<String, dynamic>> ref in refs.sublist(
        i,
        end,
      )) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  Future<void> _writeDocuments(List<_RemoteWrite> writes) async {
    if (writes.isEmpty) {
      return;
    }
    const int batchLimit = 450;
    for (int i = 0; i < writes.length; i += batchLimit) {
      final int end = math.min(i + batchLimit, writes.length);
      final WriteBatch batch = _firestore.batch();
      for (final _RemoteWrite write in writes.sublist(i, end)) {
        batch.set(write.ref, write.data, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }
}

class _RemoteWrite {
  const _RemoteWrite({required this.ref, required this.data});

  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic> data;
}
