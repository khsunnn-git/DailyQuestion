import "package:flutter/material.dart";

import "design_system/design_system.dart";
import "features/splash/splash_screen.dart";

void main() {
  runApp(const DailyQuestionApp());
}

class DailyQuestionApp extends StatelessWidget {
  const DailyQuestionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.of(AppBrandTheme.blue),
      home: SplashScreen(
        isLoggedIn: false,
        firstDuration: Duration(milliseconds: 1400),
        secondDuration: Duration(milliseconds: 1400),
      ),
    );
  }
}
