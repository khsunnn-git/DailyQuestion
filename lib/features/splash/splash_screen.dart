import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/flutter_svg.dart";

import "../../design_system/design_system.dart";
import "../auth/login_screen.dart";

class SplashScreen extends StatefulWidget {
  SplashScreen({
    super.key,
    required this.isLoggedIn,
    this.firstDuration = const Duration(milliseconds: 1400),
    this.secondDuration = const Duration(milliseconds: 1400),
    this.onRouteHome,
    this.onRouteLogin,
  }) : assert(!firstDuration.isNegative),
       assert(firstDuration > Duration.zero),
       assert(!secondDuration.isNegative),
       assert(secondDuration > Duration.zero),
       assert(
         firstDuration + secondDuration <= const Duration(seconds: 5),
         "Total splash duration must be 5s or less.",
       );

  final bool isLoggedIn;
  final Duration firstDuration;
  final Duration secondDuration;
  final VoidCallback? onRouteHome;
  final VoidCallback? onRouteLogin;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _questionIconUrl =
      "http://localhost:3845/assets/2e67e91ec636008d496fd4d431c4bf4fa4535c03.svg";
  static const String _dailyQuestionLogoUrl =
      "http://localhost:3845/assets/7144d6a5c83720f0c87fdb9d90d41820b602630c.svg";

  Timer? _timer;
  bool _showSecondSplash = false;

  @override
  void initState() {
    super.initState();
    _startFirstPhase();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _routeNext() {
    if (!mounted) return;

    if (widget.isLoggedIn) {
      if (widget.onRouteHome != null) {
        widget.onRouteHome!();
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const _DemoHomeScreen()),
      );
      return;
    }

    if (widget.onRouteLogin != null) {
      widget.onRouteLogin!();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  void _startFirstPhase() {
    _timer = Timer(widget.firstDuration, () {
      if (!mounted) return;
      setState(() {
        _showSecondSplash = true;
      });
      _timer = Timer(widget.secondDuration, _routeNext);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.8,
                  colors: <Color>[
                    AppNeutralColors.white,
                    AppBrandThemes.blue.c100,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: AppNeutralColors.white.withValues(alpha: 0.24),
            ),
          ),
          Center(
            child: Transform.translate(
              offset: Offset(0, _showSecondSplash ? 0 : 4),
              child: SizedBox(
                width: 201,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _SplashIcon(
                      showSecondSplash: _showSecondSplash,
                      questionIconUrl: _questionIconUrl,
                      dailyQuestionLogoUrl: _dailyQuestionLogoUrl,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "오늘의 질문으로\n내일의 나를 만나는 시간",
                      style: TextStyle(
                        fontFamily: AppFontFamily.suit,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        color: AppNeutralColors.grey700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashIcon extends StatelessWidget {
  const _SplashIcon({
    required this.showSecondSplash,
    required this.questionIconUrl,
    required this.dailyQuestionLogoUrl,
  });

  final bool showSecondSplash;
  final String questionIconUrl;
  final String dailyQuestionLogoUrl;

  @override
  Widget build(BuildContext context) {
    if (showSecondSplash) {
      return SizedBox(
        width: 157,
        height: 82,
        child: Image.asset(
          "assets/images/splash/splash_logo_daily_question.png",
          fit: BoxFit.contain,
          errorBuilder: (_, error, stackTrace) {
            return _OptionalSvgAsset(
              assetPath: "assets/images/splash/splash_logo_daily_question.svg",
              networkUrl: dailyQuestionLogoUrl,
              width: 157,
              height: 82,
              fallback: const Text(
                "Daily\nQuestion",
                style: TextStyle(
                  fontFamily: AppFontFamily.suit,
                  color: AppAccentColors.sky,
                  fontSize: 56,
                  height: 0.88,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      );
    }

    return _OptionalSvgAsset(
      assetPath: "assets/images/splash/splash_icon_question.svg",
      networkUrl: questionIconUrl,
      width: 53,
      height: 74,
      fallback: SizedBox(
        width: 53,
        height: 74,
        child: FittedBox(
          child: Text(
            "?",
            style: TextStyle(
              fontFamily: AppFontFamily.suit,
              fontSize: 90,
              fontWeight: FontWeight.w800,
              color: AppAccentColors.sky,
              height: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionalSvgAsset extends StatelessWidget {
  const _OptionalSvgAsset({
    required this.assetPath,
    this.networkUrl,
    required this.width,
    required this.height,
    required this.fallback,
  });

  final String assetPath;
  final String? networkUrl;
  final double width;
  final double height;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString(assetPath),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          return SizedBox(
            width: width,
            height: height,
            child: SvgPicture.string(snapshot.data!, fit: BoxFit.contain),
          );
        }
        if (networkUrl != null && networkUrl!.isNotEmpty) {
          return SizedBox(
            width: width,
            height: height,
            child: SvgPicture.network(networkUrl!, fit: BoxFit.contain),
          );
        }
        return fallback;
      },
    );
  }
}

class _DemoHomeScreen extends StatelessWidget {
  const _DemoHomeScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("홈 화면")));
  }
}
