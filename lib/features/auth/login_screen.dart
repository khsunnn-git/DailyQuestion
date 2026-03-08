import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

import "../../design_system/design_system.dart";
import "../splash/splash_screen.dart";
import "auth_service.dart";
import "social_auth_provider.dart";
import "social_login_store.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.hasRecentSocialLogin = true,
    this.recentSocialLoginProvider,
    this.recentSocialLoginProviders,
    this.onLoginSuccess,
    this.onFindId,
    this.onFindPassword,
    this.onSignUp,
    this.onSocialLogin,
  });

  final bool hasRecentSocialLogin;
  final String? recentSocialLoginProvider;
  final List<String>? recentSocialLoginProviders;
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onFindId;
  final VoidCallback? onFindPassword;
  final VoidCallback? onSignUp;
  final Future<void> Function(String provider)? onSocialLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  SocialAuthProvider? _recentProvider;
  SocialAuthProvider? _activeProvider;

  @override
  void initState() {
    super.initState();
    _loadRecentProvider();
  }

  Future<void> _loadRecentProvider() async {
    if (!widget.hasRecentSocialLogin) {
      return;
    }
    SocialAuthProvider? provider = _recentProviderFromWidget();
    provider ??= await SocialLoginStore.instance.readRecentProvider();
    if (!mounted) {
      return;
    }
    setState(() {
      _recentProvider = provider;
    });
  }

  SocialAuthProvider? _recentProviderFromWidget() {
    final List<String> candidateIds = <String>[
      ...?widget.recentSocialLoginProviders,
      if (widget.recentSocialLoginProvider != null)
        widget.recentSocialLoginProvider!,
    ];
    for (final String id in candidateIds) {
      final SocialAuthProvider? provider = socialAuthProviderFromId(id);
      if (provider != null) {
        return provider;
      }
    }
    return null;
  }

  Future<void> _handleSocialLogin(SocialAuthProvider provider) async {
    if (_activeProvider != null) {
      return;
    }
    setState(() {
      _activeProvider = provider;
    });

    try {
      if (widget.onSocialLogin != null) {
        await widget.onSocialLogin!(provider.id);
      } else {
        await AuthService.instance.signInWithProvider(provider);
      }
      await SocialLoginStore.instance.saveRecentProvider(provider);
      if (!mounted) {
        return;
      }
      setState(() {
        _recentProvider = provider;
      });
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SplashScreen(
            isLoggedIn: true,
            firstDuration: const Duration(milliseconds: 320),
            secondDuration: const Duration(milliseconds: 320),
          ),
        ),
      );
    } on AuthActionException catch (error) {
      _showMessage(error.userMessage);
    } catch (_) {
      _showMessage("${provider.label} 로그인에 실패했어요. 잠시 후 다시 시도해주세요.");
    } finally {
      if (mounted) {
        setState(() {
          _activeProvider = null;
        });
      }
    }
  }

  void _handleSignUpTap() {
    if (widget.onSignUp != null) {
      widget.onSignUp!();
      return;
    }
    _showMessage("카카오, 네이버, 구글 로그인으로 바로 시작할 수 있어요.");
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            message,
            style: AppTypography.captionMedium.copyWith(
              color: AppNeutralColors.white,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double topSpacing = (constraints.maxHeight * 0.27).clamp(
              144.0,
              240.0,
            );
            final double titleSpacing = (constraints.maxHeight * 0.18).clamp(
              108.0,
              172.0,
            );
            final double bottomSpacing = (constraints.maxHeight * 0.12).clamp(
              32.0,
              80.0,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(height: topSpacing),
                    const _LoginHeroSection(),
                    SizedBox(height: titleSpacing),
                    _SocialLoginPanel(
                      recentProvider: _recentProvider,
                      activeProvider: _activeProvider,
                      onTap: _handleSocialLogin,
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    _SignUpLink(onTap: _handleSignUpTap),
                    SizedBox(height: bottomSpacing),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginHeroSection extends StatelessWidget {
  const _LoginHeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          "Daily Question",
          textAlign: TextAlign.center,
          style: AppTypography.headingLarge.copyWith(
            color: AppNeutralColors.grey900,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Text(
          "오늘의 질문으로\n내일의 나를 만나는 시간",
          textAlign: TextAlign.center,
          style: AppTypography.bodyMediumRegular.copyWith(
            color: AppNeutralColors.grey700,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SocialLoginPanel extends StatelessWidget {
  const _SocialLoginPanel({
    required this.recentProvider,
    required this.activeProvider,
    required this.onTap,
  });

  final SocialAuthProvider? recentProvider;
  final SocialAuthProvider? activeProvider;
  final Future<void> Function(SocialAuthProvider provider) onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        if (recentProvider != null)
          const Positioned(
            top: -37,
            right: 18,
            child: SizedBox(
              width: AppTooltipTokens.width,
              child: AppTooltipBubble(
                text: "최근 로그인",
                direction: AppBubbleDirection.downRight,
              ),
            ),
          ),
        Column(
          children: <Widget>[
            _SocialLoginButton(
              provider: SocialAuthProvider.kakao,
              isLoading: activeProvider == SocialAuthProvider.kakao,
              onTap: () => onTap(SocialAuthProvider.kakao),
            ),
            const SizedBox(height: AppSpacing.s8),
            _SocialLoginButton(
              provider: SocialAuthProvider.naver,
              isLoading: activeProvider == SocialAuthProvider.naver,
              onTap: () => onTap(SocialAuthProvider.naver),
            ),
            const SizedBox(height: AppSpacing.s8),
            _SocialLoginButton(
              provider: SocialAuthProvider.google,
              isLoading: activeProvider == SocialAuthProvider.google,
              onTap: () => onTap(SocialAuthProvider.google),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.provider,
    required this.isLoading,
    required this.onTap,
  });

  final SocialAuthProvider provider;
  final bool isLoading;
  final VoidCallback onTap;

  Color get _backgroundColor {
    switch (provider) {
      case SocialAuthProvider.kakao:
        return const Color(0xFFFFE617);
      case SocialAuthProvider.naver:
        return const Color(0xFF04C75B);
      case SocialAuthProvider.google:
        return AppNeutralColors.white;
    }
  }

  Color get _textColor {
    switch (provider) {
      case SocialAuthProvider.kakao:
      case SocialAuthProvider.google:
        return AppNeutralColors.grey800;
      case SocialAuthProvider.naver:
        return AppNeutralColors.white;
    }
  }

  BoxBorder? get _border {
    if (provider == SocialAuthProvider.google) {
      return Border.all(color: AppNeutralColors.grey100);
    }
    return null;
  }

  String get _assetPath {
    switch (provider) {
      case SocialAuthProvider.kakao:
        return "assets/images/login/ic_kakao.svg";
      case SocialAuthProvider.naver:
        return "assets/images/login/ic_naver.svg";
      case SocialAuthProvider.google:
        return "assets/images/login/ic_google.svg";
    }
  }

  Size get _iconSize {
    switch (provider) {
      case SocialAuthProvider.kakao:
        return const Size(18, 16.4);
      case SocialAuthProvider.naver:
        return const Size(14.7, 14.7);
      case SocialAuthProvider.google:
        return const Size(18, 18.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = isLoading;
    final Widget icon = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_textColor),
            ),
          )
        : SizedBox(
            width: _iconSize.width,
            height: _iconSize.height,
            child: SvgPicture.asset(_assetPath, fit: BoxFit.contain),
          );

    return Opacity(
      opacity: disabled ? 0.72 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: AppRadius.br8,
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: AppRadius.br8,
              border: _border,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  icon,
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    provider.loginLabel,
                    style: AppTypography.buttonMedium.copyWith(
                      color: _textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpLink extends StatelessWidget {
  const _SignUpLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.br16,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "회원가입하기",
                style: AppTypography.buttonSmall.copyWith(
                  color: AppNeutralColors.grey900,
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              const Icon(
                Icons.chevron_right,
                size: 24,
                color: AppNeutralColors.grey900,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
