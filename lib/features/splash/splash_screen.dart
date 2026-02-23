import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

import "../../design_system/design_system.dart";
import "../auth/login_screen.dart";
import "../home/home_screen.dart";

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
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
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
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.8,
                  colors: <Color>[AppNeutralColors.white, brand.c100],
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
                    _SplashIcon(showSecondSplash: _showSecondSplash),
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
  const _SplashIcon({required this.showSecondSplash});

  final bool showSecondSplash;

  @override
  Widget build(BuildContext context) {
    if (showSecondSplash) {
      return SizedBox(
        width: 157,
        height: 82,
        child: Image.asset(
          "assets/images/splash/splash_logo_daily_question.png",
          fit: BoxFit.contain,
          errorBuilder: (_, error, stackTrace) => const Text(
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
        ),
      );
    }

    return const SizedBox(width: 53, height: 74, child: _SplashQuestionIcon());
  }
}

class _SplashQuestionIcon extends StatelessWidget {
  const _SplashQuestionIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      "assets/images/splash/splash_icon_question.svg",
      fit: BoxFit.contain,
      placeholderBuilder: (_) => const _SplashQuestionFallback(),
    );
  }
}

class _SplashQuestionFallback extends StatelessWidget {
  const _SplashQuestionFallback();

  @override
  Widget build(BuildContext context) {
    return const FittedBox(
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
    );
  }
}
