import "package:dailyquestion/features/profile/nickname_complete_screen.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets(
    "record start button can navigate after the completion route replaced the previous screen",
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: _LaunchNicknameCompleteScreen()),
      );

      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();

      expect(find.text("기록 시작하기"), findsOneWidget);

      await tester.tap(find.text("기록 시작하기"));
      await tester.pumpAndSettle();

      expect(find.text("home"), findsOneWidget);
    },
  );
}

class _LaunchNicknameCompleteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => NicknameCompleteScreen(
                  nickname: "테스트",
                  onStart: (BuildContext completeContext) {
                    Navigator.of(completeContext).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const _HomeScreenStub(),
                      ),
                    );
                  },
                ),
              ),
            );
          },
          child: const Text("open"),
        ),
      ),
    );
  }
}

class _HomeScreenStub extends StatelessWidget {
  const _HomeScreenStub();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("home")));
  }
}
