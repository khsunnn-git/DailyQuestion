import "package:cloud_firestore/cloud_firestore.dart";

import "feedback_submission_draft.dart";

class FeedbackSubmitException implements Exception {
  const FeedbackSubmitException({required this.userMessage});

  final String userMessage;
}

class FeedbackRepository {
  FeedbackRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> submit({
    required FeedbackSubmissionDraft draft,
    required String category,
    required String message,
    required String replyEmail,
    required String senderUid,
    String? senderEmail,
  }) async {
    try {
      await _firestore.collection("feedback").add(<String, dynamic>{
        "category": category,
        "message": message,
        "replyEmail": replyEmail.trim().isEmpty ? null : replyEmail.trim(),
        "subject": draft.subject,
        "body": draft.body,
        "senderUid": senderUid,
        "senderEmail": senderEmail,
        "status": "open",
        "source": "mobile_app",
        "createdAt": FieldValue.serverTimestamp(),
        "createdAtClient": Timestamp.now(),
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      if (error.code == "permission-denied") {
        throw const FeedbackSubmitException(
          userMessage: "의견 접수 권한이 없어요. 로그인 상태를 확인 후 다시 시도해주세요.",
        );
      }
      throw const FeedbackSubmitException(
        userMessage: "의견 접수에 실패했어요. 네트워크를 확인하고 다시 시도해주세요.",
      );
    }
  }
}
