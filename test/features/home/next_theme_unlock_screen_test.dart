import "package:dailyquestion/design_system/design_system.dart";
import "package:dailyquestion/features/home/next_theme_unlock_screen.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("renders the next theme unlock screen copy", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.of(AppBrandTheme.green),
        home: const NextThemeUnlockScreen(),
      ),
    );

    expect(find.text("축하해요!\n새싹 테마가 열렸어요!"), findsOneWidget);
    expect(find.text("새로운 테마와 함께 기록을\n이어가보세요!"), findsOneWidget);
    expect(find.text("다음"), findsOneWidget);
  });

  testWidgets("moves to the fallback home when shown as the root route", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.of(AppBrandTheme.green),
        home: NextThemeUnlockScreen(
          fallbackHomeBuilder: (_) =>
              const Scaffold(body: Center(child: Text("그린 홈"))),
        ),
      ),
    );

    await tester.tap(find.text("다음"));
    await tester.pumpAndSettle();

    expect(find.text("그린 홈"), findsOneWidget);
  });

  testWidgets("returns to the previous route when presented on top of home", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.of(AppBrandTheme.green),
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NextThemeUnlockScreen(),
                      ),
                    );
                  },
                  child: const Text("열기"),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text("열기"));
    await tester.pumpAndSettle();
    expect(find.text("다음"), findsOneWidget);

    await tester.tap(find.text("다음"));
    await tester.pumpAndSettle();

    expect(find.text("열기"), findsOneWidget);
  });
}
