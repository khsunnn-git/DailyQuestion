import "package:dailyquestion/features/profile/nickname_setup_screen.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("edit mode app bar back returns to the previous screen", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _NicknameEditLauncher()));

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    expect(find.text("닉네임 설정"), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text("settings"), findsOneWidget);
  });

  testWidgets("edit mode system back returns to the previous screen", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _NicknameEditLauncher()));

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    expect(find.text("닉네임 설정"), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text("settings"), findsOneWidget);
  });
}

class _NicknameEditLauncher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text("settings"),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NicknameSetupScreen(
                      isEditMode: true,
                      initialNicknameLoader: () async => "테스트",
                    ),
                  ),
                );
              },
              child: const Text("open"),
            ),
          ],
        ),
      ),
    );
  }
}
