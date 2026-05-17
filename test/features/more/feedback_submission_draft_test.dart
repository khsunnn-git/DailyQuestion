import "package:dailyquestion/features/more/feedback_submission_draft.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("builds a feedback draft with the expected metadata", () {
    final FeedbackSubmissionDraft draft = FeedbackSubmissionDraft.create(
      category: "기능 제안",
      message: "홈 공지 팝업이 귀여워요.",
      replyEmail: "reply@example.com",
      appVersion: "2.0.3+42",
      signedInEmail: "signed@example.com",
      userId: "user-123",
      createdAt: DateTime.utc(2026, 5, 8, 3, 15),
    );

    expect(draft.subject, "[DailyQuestion 의견] 기능 제안");
    expect(draft.body, contains("카테고리: 기능 제안"));
    expect(draft.body, contains("답변 받을 이메일: reply@example.com"));
    expect(draft.body, contains("로그인 이메일: signed@example.com"));
    expect(draft.body, contains("사용자 UID: user-123"));
    expect(draft.body, contains("앱 버전: 2.0.3+42"));
    expect(draft.body, contains("작성 시각(KST): 2026-05-08 12:15"));
    expect(draft.body, contains("홈 공지 팝업이 귀여워요."));
  });
}
