import "dart:math";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:shared_preferences/shared_preferences.dart";

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
      "createdAt": Timestamp.fromDate(payload.createdAt),
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
}
