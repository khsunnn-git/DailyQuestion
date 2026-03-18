import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

import "../../design_system/design_system.dart";
import "../navigation/main_tab_shell.dart";
import "../profile/initial_terms_consent_screen.dart";
import "../profile/nickname_setup_screen.dart";
import "../profile/user_profile_remote_service.dart";
import "../profile/user_profile_store.dart";
import "../question/user_answer_backup_service.dart";
import "auth_service.dart";
import "social_auth_provider.dart";

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
      await syncPendingUserAnswers(restoreRemoteOnConnect: true);
      try {
        await UserProfileRemoteService.instance.syncCurrentUserProfile();
      } catch (_) {
        // Keep the signed-in session even if remote profile sync is temporarily unavailable.
      }
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
          await _resolvePostLoginDestination();
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
                onCompleted: (BuildContext completionContext) {
                  Navigator.of(
                    completionContext,
                  ).pushReplacement(MainTabShell.route());
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

  Future<PostLoginDestination> _resolvePostLoginDestination() async {
    try {
      return await UserProfileRemoteService.instance
          .resolvePostLoginDestination();
    } catch (_) {
      final bool consentAccepted = await loadInitialConsentAccepted();
      final String? nickname = _normalizedNickname(await loadNickname());
      return resolveLocalPostLoginDestination(
        localConsentAccepted: consentAccepted,
        localNickname: nickname,
      );
    }
  }

  String? _normalizedNickname(String? nickname) {
    final String text = (nickname ?? "").trim();
    if (text.isEmpty) {
      return null;
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double heroTopSpacing = (constraints.maxHeight * 0.30)
                  .clamp(156.0, 248.0);
              final double bottomSpacing = (constraints.maxHeight * 0.06).clamp(
                28.0,
                46.0,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(height: heroTopSpacing),
                  const _LoginHeroSection(),
                  const Spacer(),
                  _LoginBottomSection(
                    mode: widget.mode,
                    activeProvider: _activeProvider,
                    onSocialLogin: _handleSocialLogin,
                    onContinueWithoutLogin: _continueWithoutLogin,
                  ),
                  SizedBox(height: bottomSpacing),
                ],
              );
            },
          ),
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

class _LoginBottomSection extends StatelessWidget {
  const _LoginBottomSection({
    required this.mode,
    required this.activeProvider,
    required this.onSocialLogin,
    required this.onContinueWithoutLogin,
  });

  final LoginScreenMode mode;
  final SocialAuthProvider? activeProvider;
  final Future<void> Function(SocialAuthProvider provider) onSocialLogin;
  final VoidCallback onContinueWithoutLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SocialLoginPanel(activeProvider: activeProvider, onTap: onSocialLogin),
        if (mode == LoginScreenMode.onboarding) ...<Widget>[
          const SizedBox(height: AppSpacing.s12),
          _GuestContinueButton(onTap: onContinueWithoutLogin),
          const SizedBox(height: AppSpacing.s24),
        ] else ...<Widget>[const SizedBox(height: AppSpacing.s24)],
        const _LoginInfoSection(),
      ],
    );
  }
}

class _LoginInfoSection extends StatelessWidget {
  const _LoginInfoSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppNeutralColors.grey100)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s20),
          child: Text(
            "처음 로그인하면 별도 회원가입 없이 바로 시작됩니다.\n계정이 연동되면 기존 데이터들이 자동 백업됩니다.",
            textAlign: TextAlign.center,
            style: AppTypography.captionSmall.copyWith(
              color: AppNeutralColors.grey800,
            ),
          ),
        ),
      ),
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
    return Center(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          minimumSize: const Size(183, 32),
          maximumSize: const Size(183, 32),
          fixedSize: const Size(183, 32),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s4,
            AppSpacing.s4,
            AppSpacing.s4,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: AppNeutralColors.grey900,
          textStyle: AppTypography.buttonSmall.copyWith(
            color: AppNeutralColors.grey900,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSpacing.s16)),
          ),
          overlayColor: AppNeutralColors.grey100,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            Text("로그인 없이 사용해보기"),
            Icon(Icons.keyboard_arrow_right, size: 24),
          ],
        ),
      ),
    );
  }
}
