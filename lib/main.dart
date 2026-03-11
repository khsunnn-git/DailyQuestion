import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter/foundation.dart";
import "package:firebase_core/firebase_core.dart";

import "app_bootstrap.dart";
import "design_system/design_system.dart";
import "features/profile/nickname_setup_screen.dart";
import "features/question/user_answer_backup_service.dart";
import "features/splash/splash_screen.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebaseSafely();
  await _initializeAppDependenciesSafely();
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

Future<void> _initializeAppDependenciesSafely() async {
  try {
    await initializeAppDependencies().timeout(const Duration(seconds: 4));
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint("[main] initializeAppDependencies failed: $error");
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

Future<void> _initializeFirebaseSafely() async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    if (!kIsWeb) {
      rethrow;
    }
    // Web local runs may not have Firebase web options configured.
  }
}

class DailyQuestionApp extends StatefulWidget {
  const DailyQuestionApp({super.key});

  static const bool _forceNicknameSetupPreview = false;
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
  State<DailyQuestionApp> createState() => _DailyQuestionAppState();
}

class _DailyQuestionAppState extends State<DailyQuestionApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    handleUserAnswerBackupAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: DailyQuestionApp._systemUiStyle,
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: AppTheme.of(
        AppCharacterThemeMapper.fromCharacterName(
          DailyQuestionApp._selectedCharacterName,
        ),
      ),
      home: DailyQuestionApp._forceNicknameSetupPreview
          ? const NicknameSetupScreen()
          : SplashScreen(
              firstDuration: Duration(milliseconds: 1400),
              secondDuration: Duration(milliseconds: 1400),
            ),
    );
  }
}
