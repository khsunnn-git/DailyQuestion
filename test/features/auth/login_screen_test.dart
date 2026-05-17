import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "package:dailyquestion/design_system/design_system.dart";
import "package:dailyquestion/features/auth/login_screen.dart";

void main() {
  testWidgets(
    "google login button keeps a stable semantics label while loading",
    (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();
      final SemanticsHandle semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1440, 3200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.of(AppBrandTheme.blue),
          home: LoginScreen(
            mode: LoginScreenMode.accountConnect,
            onSocialLogin: (_) => completer.future,
          ),
        ),
      );
      await tester.pump();

      expect(find.bySemanticsLabel("구글로 로그인"), findsOneWidget);

      await tester.tap(find.text("구글로 로그인"));
      await tester.pump();

      expect(find.bySemanticsLabel("구글로 로그인"), findsOneWidget);
      expect(find.text("구글로 로그인"), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
      semantics.dispose();
    },
  );
}
