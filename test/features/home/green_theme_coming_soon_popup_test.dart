import "package:dailyquestion/design_system/design_system.dart";
import "package:dailyquestion/features/home/green_theme_coming_soon_popup.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("renders the coming soon popup copy", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.of(AppBrandTheme.green),
        home: Scaffold(
          body: Center(
            child: GreenThemeComingSoonPopup(
              onCloseForToday: () {},
              onConfirm: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text("오늘은 닫기"), findsOneWidget);
    expect(find.text("NEW UPDATE"), findsOneWidget);
    expect(find.text("60번째 기록과 함께할"), findsOneWidget);
    expect(find.text("귀여운 새싹테마!"), findsOneWidget);
    expect(find.text("새로운 테마를 기다려볼까요?"), findsOneWidget);
    expect(find.text("확인"), findsOneWidget);
  });

  testWidgets("invokes the expected callbacks", (WidgetTester tester) async {
    int closeCallCount = 0;
    int confirmCallCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.of(AppBrandTheme.green),
        home: Scaffold(
          body: Center(
            child: GreenThemeComingSoonPopup(
              onCloseForToday: () => closeCallCount += 1,
              onConfirm: () => confirmCallCount += 1,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("오늘은 닫기"));
    await tester.pump();

    await tester.tap(find.text("확인"));
    await tester.pump();

    expect(closeCallCount, 1);
    expect(confirmCallCount, 1);
  });
}
