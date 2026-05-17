import "../../core/app_version_info.dart";
import "../../core/kst_date_time.dart";

class FeedbackSubmissionDraft {
  const FeedbackSubmissionDraft({required this.subject, required this.body});

  final String subject;
  final String body;

  static Future<FeedbackSubmissionDraft> fromForm({
    required String category,
    required String message,
    required String replyEmail,
    String? signedInEmail,
    String? userId,
  }) async {
    final AppVersionInfo versionInfo = await AppVersionInfo.load();
    return create(
      category: category,
      message: message,
      replyEmail: replyEmail,
      appVersion: versionInfo.rawVersion,
      signedInEmail: signedInEmail,
      userId: userId,
      createdAt: nowInKst(),
    );
  }

  static FeedbackSubmissionDraft create({
    required String category,
    required String message,
    required String replyEmail,
    required String appVersion,
    required DateTime createdAt,
    String? signedInEmail,
    String? userId,
  }) {
    final String timestamp = _formatKstTimestamp(createdAt);
    final String normalizedReplyEmail = _normalizeOptional(replyEmail);
    final String normalizedSignedInEmail = _normalizeOptional(signedInEmail);
    final String normalizedUserId = _normalizeOptional(userId);
    final String normalizedVersion = appVersion.trim().isEmpty
        ? "확인 불가"
        : appVersion.trim();
    final String trimmedMessage = message.trim();

    return FeedbackSubmissionDraft(
      subject: "[DailyQuestion 의견] $category",
      body: <String>[
        "카테고리: $category",
        "답변 받을 이메일: $normalizedReplyEmail",
        "로그인 이메일: $normalizedSignedInEmail",
        "사용자 UID: $normalizedUserId",
        "앱 버전: $normalizedVersion",
        "작성 시각(KST): $timestamp",
        "",
        "의견 내용",
        trimmedMessage,
      ].join("\n"),
    );
  }

  static String _normalizeOptional(String? value) {
    final String normalized = (value ?? "").trim();
    if (normalized.isEmpty) {
      return "없음";
    }
    return normalized;
  }

  static String _formatKstTimestamp(DateTime dateTime) {
    final DateTime kst = toKst(dateTime);
    final String mm = kst.month.toString().padLeft(2, "0");
    final String dd = kst.day.toString().padLeft(2, "0");
    final String hh = kst.hour.toString().padLeft(2, "0");
    final String min = kst.minute.toString().padLeft(2, "0");
    return "${kst.year}-$mm-$dd $hh:$min";
  }
}
