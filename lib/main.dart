import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter/foundation.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:firebase_core/firebase_core.dart";

import "app_bootstrap.dart";
import "core/app_route_observer.dart";
import "design_system/design_system.dart";
import "features/auth/login_screen.dart";
import "features/home/home_screen.dart";
import "features/notifications/daily_question_notification_scheduler.dart";
import "features/profile/initial_terms_consent_screen.dart";
import "features/profile/nickname_complete_screen.dart";
import "features/profile/nickname_setup_screen.dart";
import "features/question/user_answer_backup_service.dart";
import "features/report/weekly_report_store.dart";
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

  static const Locale _appLocale = Locale("ko");
  static const bool _forceNicknameSetupPreview = false;
  static const String _debugPreviewScreen = String.fromEnvironment(
    "DEBUG_PREVIEW_SCREEN",
    defaultValue: "",
  );
  static const String _debugPreviewNickname = String.fromEnvironment(
    "DEBUG_PREVIEW_NICKNAME",
    defaultValue: "혜선",
  );
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeNotificationSchedulerSafely());
      unawaited(_prepareWeeklyReportSafely());
    });
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

  Future<void> _initializeNotificationSchedulerSafely() async {
    try {
      await initializeDailyQuestionNotificationScheduler();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          "[main] initializeDailyQuestionNotificationScheduler failed: $error",
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  Future<void> _prepareWeeklyReportSafely() async {
    try {
      await WeeklyReportStore.instance.prepareCurrentWeeklyReport();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint("[main] prepareCurrentWeeklyReport failed: $error");
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: <NavigatorObserver>[appRouteObserver],
      locale: DailyQuestionApp._appLocale,
      supportedLocales: const <Locale>[DailyQuestionApp._appLocale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
      home: _buildInitialScreen(),
    );
  }

  Widget _buildInitialScreen() {
    final String previewScreen =
        DailyQuestionApp._debugPreviewScreen.trim().isEmpty
        ? (kDebugMode ? "home" : "")
        : DailyQuestionApp._debugPreviewScreen;
    switch (_resolveDebugPreviewScreen(previewScreen)) {
      case _DebugPreviewScreen.home:
        return const HomeScreen();
      case _DebugPreviewScreen.login:
        return const LoginScreen(mode: LoginScreenMode.onboarding);
      case _DebugPreviewScreen.termsConsent:
        return const InitialTermsConsentScreen();
      case _DebugPreviewScreen.nicknameSetup:
        return const NicknameSetupScreen();
      case _DebugPreviewScreen.nicknameComplete:
        return const NicknameCompleteScreen(
          nickname: DailyQuestionApp._debugPreviewNickname,
        );
      case _DebugPreviewScreen.none:
        return DailyQuestionApp._forceNicknameSetupPreview
            ? const NicknameSetupScreen()
            : SplashScreen(
                firstDuration: Duration(milliseconds: 1400),
                secondDuration: Duration(milliseconds: 1400),
              );
    }
  }
}

enum _DebugPreviewScreen {
  none,
  home,
  login,
  termsConsent,
  nicknameSetup,
  nicknameComplete,
}

_DebugPreviewScreen _resolveDebugPreviewScreen(String raw) {
  switch (raw.trim().toLowerCase()) {
    case "home":
      return _DebugPreviewScreen.home;
    case "login":
      return _DebugPreviewScreen.login;
    case "terms":
    case "terms_consent":
      return _DebugPreviewScreen.termsConsent;
    case "nickname_setup":
      return _DebugPreviewScreen.nicknameSetup;
    case "nickname_complete":
      return _DebugPreviewScreen.nicknameComplete;
    default:
      return _DebugPreviewScreen.none;
  }
}
