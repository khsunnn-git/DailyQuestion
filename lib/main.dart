import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "design_system/design_system.dart";
import "features/splash/splash_screen.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  runApp(const DailyQuestionApp());
}

class DailyQuestionApp extends StatelessWidget {
  const DailyQuestionApp({super.key});

  static const String _selectedCharacterName = "물고기";
  static const SystemUiOverlayStyle _systemUiStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _systemUiStyle,
          child: child ?? const SizedBox.shrink(),
        );
      },
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
