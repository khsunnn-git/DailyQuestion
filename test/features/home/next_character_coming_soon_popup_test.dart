import "package:dailyquestion/design_system/design_system.dart";
import "package:dailyquestion/features/home/home_character_assets.dart";
import "package:dailyquestion/features/home/next_character_coming_soon_popup.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Widget buildPopup({
    HomeCharacterType currentCharacterType = HomeCharacterType.fish,
    int remainingRecordCount = 5,
    VoidCallback? onCloseForToday,
    VoidCallback? onConfirm,
  }) {
    return MaterialApp(
      theme: AppTheme.of(currentCharacterType.brandTheme),
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: NextCharacterComingSoonPopup(
              currentCharacterType: currentCharacterType,
              remainingRecordCount: remainingRecordCount,
              onCloseForToday: onCloseForToday ?? () {},
              onConfirm: onConfirm ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets("renders the next character coming soon copy", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildPopup(remainingRecordCount: 5));

    expect(find.text("오늘은 닫기"), findsOneWidget);
    expect(find.text("NEW UPDATE"), findsOneWidget);
    expect(find.text("5번만 더 기록하면"), findsOneWidget);
    expect(find.text("새로운 테마가 열려요!"), findsOneWidget);
    expect(find.text("새로운 테마를 기다려볼까요?"), findsOneWidget);
    expect(find.text("확인"), findsOneWidget);
  });

  testWidgets("uses the last-record copy", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildPopup(
        currentCharacterType: HomeCharacterType.tree,
        remainingRecordCount: 1,
      ),
    );

    expect(find.text("다음 기록을 마치면"), findsOneWidget);
  });

  testWidgets("invokes the expected callbacks", (WidgetTester tester) async {
    int closeCallCount = 0;
    int confirmCallCount = 0;

    await tester.pumpWidget(
      buildPopup(
        onCloseForToday: () => closeCallCount += 1,
        onConfirm: () => confirmCallCount += 1,
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
