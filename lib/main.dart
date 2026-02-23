import "package:flutter/material.dart";

import "design_system/design_system.dart";
import "features/splash/splash_screen.dart";

void main() {
  runApp(const DailyQuestionApp());
}

class DailyQuestionApp extends StatelessWidget {
  const DailyQuestionApp({super.key});

  static const String _selectedCharacterName = "물고기";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.of(
        AppCharacterThemeMapper.fromCharacterName(_selectedCharacterName),
      ),
      home: SplashScreen(
        isLoggedIn: false,
        firstDuration: Duration(milliseconds: 1400),
        secondDuration: Duration(milliseconds: 1400),
      ),
    );
  }
}
