import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

import "../../design_system/design_system.dart";
import "../navigation/main_tab_shell.dart";
import "../profile/initial_terms_consent_screen.dart";
import "../profile/nickname_setup_screen.dart";
import "../profile/user_profile_remote_service.dart";
import "../question/user_answer_backup_service.dart";
import "auth_service.dart";
import "social_auth_provider.dart";
import "social_login_store.dart";

enum LoginScreenMode { onboarding, accountConnect }

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onLoginSuccess,
    this.onFindId,
    this.onFindPassword,
    this.onSocialLogin,
    this.mode = LoginScreenMode.onboarding,
  });

  final VoidCallback? onLoginSuccess;
  final VoidCallback? onFindId;
  final VoidCallback? onFindPassword;
  final Future<void> Function(String provider)? onSocialLogin;
  final LoginScreenMode mode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  SocialAuthProvider? _activeProvider;

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
      await syncPendingUserAnswers(restoreRemoteOnConnect: true);
      await UserProfileRemoteService.instance.syncCurrentUserProfile();
      if (!mounted) {
        return;
      }
      if (widget.mode == LoginScreenMode.accountConnect &&
          widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
        return;
      }
      if (widget.mode == LoginScreenMode.accountConnect) {
        Navigator.of(context).maybePop();
        return;
      }

      final PostLoginDestination destination =
          await UserProfileRemoteService.instance.resolvePostLoginDestination();
      if (!mounted) {
        return;
      }
      switch (destination) {
        case PostLoginDestination.termsConsent:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const InitialTermsConsentScreen(),
            ),
          );
        case PostLoginDestination.nicknameSetup:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => NicknameSetupScreen(
                onCompleted: () {
                  Navigator.of(context).pushReplacement(MainTabShell.route());
                },
              ),
            ),
          );
        case PostLoginDestination.home:
          Navigator.of(context).pushReplacement(MainTabShell.route());
      }
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

  void _continueWithoutLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const InitialTermsConsentScreen(),
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
                      activeProvider: _activeProvider,
                      onTap: _handleSocialLogin,
                    ),
                    if (widget.mode == LoginScreenMode.onboarding) ...<Widget>[
                      const SizedBox(height: AppSpacing.s28),
                      _GuestContinueButton(onTap: _continueWithoutLogin),
                    ],
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
  const _SocialLoginPanel({required this.activeProvider, required this.onTap});

  final SocialAuthProvider? activeProvider;
  final Future<void> Function(SocialAuthProvider provider) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _SocialLoginButton(
          provider: SocialAuthProvider.google,
          isLoading: activeProvider == SocialAuthProvider.google,
          onTap: () => onTap(SocialAuthProvider.google),
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
        return const Size(18, 18.258);
    }
  }

  String get _buttonLabel => provider.loginLabel;

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
                    _buttonLabel,
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

class _GuestContinueButton extends StatelessWidget {
  const _GuestContinueButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppNeutralColors.grey700,
          textStyle: AppTypography.buttonMedium,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            Text("로그인 없이 사용해보기"),
            SizedBox(width: AppSpacing.s4),
            Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}
