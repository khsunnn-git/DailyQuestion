import "package:dailyquestion/design_system/design_system.dart";
import "package:dailyquestion/features/home/home_character_assets.dart";
import "package:dailyquestion/features/home/home_character_select_screen.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    HomeCharacterSelectMode mode = HomeCharacterSelectMode.signup,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.of(AppBrandTheme.blue),
        home: HomeCharacterSelectScreen(mode: mode),
      ),
    );
  }

  ElevatedButton nextButton(WidgetTester tester) {
    return tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, "다음"),
    );
  }

  testWidgets("signup mode shows the Figma copy and every character", (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text("회원가입"), findsOneWidget);
    expect(find.text("나와 함께 여정을 시작할\n캐릭터를 선택해주세요!"), findsOneWidget);
    expect(find.text("60일간 함께 성장할 캐릭터를 선택하세요."), findsOneWidget);
    expect(find.text("테마는 60일마다 변경하실 수 있습니다."), findsOneWidget);
    for (final HomeCharacterType type in HomeCharacterType.values) {
      expect(
        find.bySemanticsLabel("${type.displayName} 캐릭터"),
        findsOneWidget,
        reason: type.name,
      );
    }
  });

  testWidgets("next button is enabled only after picking a character", (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester);
    expect(nextButton(tester).onPressed, isNull);

    await tester.tap(find.bySemanticsLabel("우파루파 캐릭터"));
    await tester.pump();

    expect(nextButton(tester).onPressed, isNotNull);
    expect(
      find.byKey(const ValueKey<String>("character-select-hero-axolotl")),
      findsOneWidget,
    );
  });

  testWidgets("next cycle mode has its own title and no back button", (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, mode: HomeCharacterSelectMode.nextCycle);

    expect(find.text("캐릭터 선택"), findsOneWidget);
    expect(find.text("다음 여정을 함께할\n캐릭터를 선택해주세요!"), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });
}
