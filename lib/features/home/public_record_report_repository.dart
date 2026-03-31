import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";

import "../auth/auth_service.dart";

class PublicRecordReportSubmitException implements Exception {
  const PublicRecordReportSubmitException({required this.userMessage});

  final String userMessage;
}

class PublicRecordReportRepository {
  PublicRecordReportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> submit({
    required String reason,
    required String targetId,
    required String targetType,
    required String questionDateKey,
    required String authorName,
    required String answerPreview,
  }) async {
    try {
      final User user = await _ensureSignedInUser();
      await _firestore.collection("reports").add(<String, dynamic>{
        "reason": reason,
        "targetId": targetId,
        "targetType": targetType,
        "questionDateKey": questionDateKey,
        "authorName": authorName,
        "answerPreview": answerPreview,
        "reporterUid": user.uid,
        "status": "open",
        "source": "mobile_app",
        "reportedAt": FieldValue.serverTimestamp(),
        "reportedAtClient": Timestamp.now(),
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      if (error.code == "permission-denied") {
        throw const PublicRecordReportSubmitException(
          userMessage: "신고 권한이 없어요. 로그인 상태를 확인 후 다시 시도해주세요.",
        );
      }
      throw const PublicRecordReportSubmitException(
        userMessage: "신고 접수에 실패했어요. 네트워크를 확인하고 다시 시도해주세요.",
      );
    }
  }

  Future<User> _ensureSignedInUser() async {
    try {
      return await AuthService.instance.ensureSignedInUser();
    } on AuthActionException catch (_) {
      throw const PublicRecordReportSubmitException(
        userMessage: "로그인이 필요해서 신고를 완료하지 못했어요. 다시 시도해주세요.",
      );
    }
  }
}
