import "dart:math";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../core/kst_date_time.dart";
import "../moderation/public_record_moderation.dart";

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

  Future<void> _ensureAnonymousSignIn() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      return;
    }
    await auth.signInAnonymously();
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
    final String todayKey = kstDateKeyNow();

    final QuerySnapshot<Map<String, dynamic>> allMine = await db
        .collectionGroup("answers")
        .where("deviceAnonId", isEqualTo: anonId)
        .get();

    final List<DocumentReference<Map<String, dynamic>>> staleRefs =
        <DocumentReference<Map<String, dynamic>>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in allMine.docs) {
      final String? questionDateKey = doc.data()["questionDateKey"] as String?;
      if (questionDateKey != null && questionDateKey.compareTo(todayKey) < 0) {
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
