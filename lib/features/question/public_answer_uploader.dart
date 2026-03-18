import "dart:math";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../auth/auth_service.dart";
import "../moderation/public_record_moderation.dart";
import "public_answer_retention.dart";

class PublicAnswerPayload {
  const PublicAnswerPayload({
    required this.createdAt,
    required this.questionDateKey,
    required this.questionSlot,
    required this.answer,
    required this.author,
    this.questionText,
    required this.bucketTags,
    required this.isPublic,
  });

  final DateTime createdAt;
  final String questionDateKey;
  final int questionSlot;
  final String answer;
  final String author;
  final String? questionText;
  final List<String> bucketTags;
  final bool isPublic;
}

class PublicAnswerUploader {
  PublicAnswerUploader._();

  static final PublicAnswerUploader instance = PublicAnswerUploader._();
  static const String _anonIdKey = "public_answer_device_anon_id";
  static const String _collectionId = "public_answers";

  String? _cachedAnonId;

  Future<void> sync(PublicAnswerPayload payload) async {
    await _ensureAnonymousSignIn();
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String anonId = await _getOrCreateAnonId();
    final String docId = _docId(anonId, payload.createdAt);
    final DocumentReference<Map<String, dynamic>> doc = _daySlotCollection(
      payload.questionDateKey,
      payload.questionSlot,
    ).doc(docId);
    final ModerationResult moderation =
        PublicRecordModeration.classifyForUpload(payload.answer);

    if (!payload.isPublic) {
      await doc.delete();
      return;
    }

    await doc.set(<String, dynamic>{
      "authorUid": currentUser?.uid,
      "deviceAnonId": anonId,
      "anonymousName": payload.author,
      "answerText": payload.answer,
      "questionDateKey": payload.questionDateKey,
      "questionSlot": payload.questionSlot,
      "questionText": payload.questionText,
      "bucketTags": payload.bucketTags,
      "sentimentScore": moderation.score,
      "moderationStatus": moderation.status.name,
      "moderationReason": moderation.reason,
      "moderationSource": "local_heuristic",
      "moderatedAt": FieldValue.serverTimestamp(),
      "createdAt": Timestamp.fromDate(payload.createdAt),
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _deletePastAnswersForAnon(anonId);
  }

  Future<void> delete({
    required DateTime createdAt,
    required String questionDateKey,
    required int questionSlot,
  }) async {
    await _ensureAnonymousSignIn();
    final String anonId = await _getOrCreateAnonId();
    final String docId = _docId(anonId, createdAt);
    await _daySlotCollection(questionDateKey, questionSlot).doc(docId).delete();
  }

  Future<void> deleteAllOwnedAnswers({String? uid}) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final Set<String> seenPaths = <String>{};
    final List<DocumentReference<Map<String, dynamic>>> refs =
        <DocumentReference<Map<String, dynamic>>>[];

    final String? normalizedUid = uid?.trim().isEmpty ?? true
        ? null
        : uid!.trim();
    if (normalizedUid != null) {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await db
          .collectionGroup("answers")
          .where("authorUid", isEqualTo: normalizedUid)
          .get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        if (seenPaths.add(doc.reference.path)) {
          refs.add(doc.reference);
        }
      }
    }

    final String? anonId = await _readStoredAnonId();
    if (anonId != null && anonId.isNotEmpty) {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await db
          .collectionGroup("answers")
          .where("deviceAnonId", isEqualTo: anonId)
          .get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        if (seenPaths.add(doc.reference.path)) {
          refs.add(doc.reference);
        }
      }
    }

    if (refs.isEmpty) {
      return;
    }

    const int batchLimit = 450;
    for (int i = 0; i < refs.length; i += batchLimit) {
      final int end = min(i + batchLimit, refs.length);
      final WriteBatch batch = db.batch();
      for (final DocumentReference<Map<String, dynamic>> ref in refs.sublist(
        i,
        end,
      )) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  Future<void> clearDeviceAnonId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_anonIdKey);
    _cachedAnonId = null;
  }

  Future<void> _ensureAnonymousSignIn() async {
    await AuthService.instance.ensureSignedInUser();
  }

  Future<String> _getOrCreateAnonId() async {
    if (_cachedAnonId != null && _cachedAnonId!.isNotEmpty) {
      return _cachedAnonId!;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_anonIdKey);
    if (saved != null && saved.isNotEmpty) {
      _cachedAnonId = saved;
      return saved;
    }
    final String created = _createAnonId();
    await prefs.setString(_anonIdKey, created);
    _cachedAnonId = created;
    return created;
  }

  Future<String?> _readStoredAnonId() async {
    if (_cachedAnonId != null && _cachedAnonId!.isNotEmpty) {
      return _cachedAnonId;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_anonIdKey);
    if (saved != null && saved.isNotEmpty) {
      _cachedAnonId = saved;
      return saved;
    }
    return null;
  }

  String _createAnonId() {
    final Random random = Random.secure();
    final int millis = DateTime.now().millisecondsSinceEpoch;
    final int r1 = random.nextInt(1 << 32);
    final int r2 = random.nextInt(1 << 32);
    return "anon_${millis.toRadixString(36)}_${r1.toRadixString(36)}${r2.toRadixString(36)}";
  }

  String _docId(String anonId, DateTime createdAt) {
    return "${anonId}_${createdAt.millisecondsSinceEpoch}";
  }

  CollectionReference<Map<String, dynamic>> _daySlotCollection(
    String questionDateKey,
    int questionSlot,
  ) {
    return FirebaseFirestore.instance
        .collection(_collectionId)
        .doc(questionDateKey)
        .collection("slots")
        .doc("slot_$questionSlot")
        .collection("answers");
  }

  Future<void> _deletePastAnswersForAnon(String anonId) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    final QuerySnapshot<Map<String, dynamic>> allMine = await db
        .collectionGroup("answers")
        .where("deviceAnonId", isEqualTo: anonId)
        .get();

    final List<DocumentReference<Map<String, dynamic>>> staleRefs =
        <DocumentReference<Map<String, dynamic>>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in allMine.docs) {
      final String? questionDateKey = doc.data()["questionDateKey"] as String?;
      if (questionDateKey != null &&
          shouldDeletePublicAnswerDateKey(questionDateKey)) {
        staleRefs.add(doc.reference);
      }
    }
    if (staleRefs.isEmpty) {
      return;
    }

    const int batchLimit = 450;
    for (int i = 0; i < staleRefs.length; i += batchLimit) {
      final int end = (i + batchLimit < staleRefs.length)
          ? i + batchLimit
          : staleRefs.length;
      final WriteBatch batch = db.batch();
      for (final DocumentReference<Map<String, dynamic>> ref
          in staleRefs.sublist(i, end)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }
}
