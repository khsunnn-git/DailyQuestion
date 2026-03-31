import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "package:dailyquestion/design_system/design_system.dart";
import "package:dailyquestion/features/question/today_question_answer_screen.dart";
import "package:dailyquestion/features/question/today_question_store.dart";

void main() {
  testWidgets("new answer screen starts with public toggle on", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.of(AppBrandTheme.blue),
        home: const TodayQuestionAnswerScreen(questionText: "오늘의 질문"),
      ),
    );
    await tester.pumpAndSettle();

    final AppIconToggle toggle = tester.widget<AppIconToggle>(
      find.byType(AppIconToggle),
    );
    expect(toggle.value, isTrue);
  });

  testWidgets("editing answer screen keeps existing public state", (
    WidgetTester tester,
  ) async {
    final TodayQuestionRecord record = TodayQuestionRecord(
      createdAt: DateTime(2026, 3, 31, 12),
      answer: "이미 작성한 답변",
      author: "나의 기록",
      isPublic: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.of(AppBrandTheme.blue),
        home: TodayQuestionAnswerScreen(
          editingRecord: record,
          questionText: "오늘의 질문",
        ),
      ),
    );
    await tester.pumpAndSettle();

    final AppIconToggle toggle = tester.widget<AppIconToggle>(
      find.byType(AppIconToggle),
    );
    expect(toggle.value, isFalse);
  });
}
