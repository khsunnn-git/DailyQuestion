import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

import "../../design_system/design_system.dart";
import "../home/home_screen.dart";

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
  final void Function(String provider)? onSocialLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _isPasswordVisible = false;
  bool _showCredentialError = false;

  bool get _canSubmit {
    return _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  String get _emailText => _emailController.text.trim();
  String get _passwordText => _passwordController.text;
  bool get _hasEmailText => _emailText.isNotEmpty;
  bool get _hasPasswordText => _passwordText.isNotEmpty;
  bool get _isEmailValid =>
      _emailText.contains("@") && _emailText.contains(".");
  bool get _emailHasFormatError => _hasEmailText && !_isEmailValid;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_handleEmailFocusChange);
    _passwordFocusNode.addListener(_handlePasswordFocusChange);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode
      ..removeListener(_handleEmailFocusChange)
      ..dispose();
    _passwordFocusNode
      ..removeListener(_handlePasswordFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleEmailFocusChange() {
    setState(() {
      _emailFocused = _emailFocusNode.hasFocus;
    });
  }

  void _handlePasswordFocusChange() {
    setState(() {
      _passwordFocused = _passwordFocusNode.hasFocus;
    });
  }

  void _attemptLogin() {
    final bool emailValid = _isEmailValid;
    final bool passwordValid = _hasPasswordText;

    if (emailValid && passwordValid) {
      setState(() {
        _showCredentialError = false;
      });
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        );
      }
      return;
    }

    setState(() {
      _showCredentialError = true;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            "이메일주소 또는 비밀번호가 틀렸습니다.",
            style: AppTypography.captionMedium.copyWith(
              color: AppNeutralColors.white,
            ),
          ),
        ),
      );
  }

  void _clearEmail() {
    _emailController.clear();
    _emailFocusNode.requestFocus();
    setState(() {
      _showCredentialError = false;
    });
  }

  void _clearPassword() {
    _passwordController.clear();
    _passwordFocusNode.requestFocus();
    setState(() {
      _isPasswordVisible = false;
      _showCredentialError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: AppNeutralColors.white,
      body: Padding(
        padding: EdgeInsets.zero,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: <Widget>[
                          const SizedBox(height: 130),
                          Text(
                            "Daily Question",
                            style: AppTypography.headingLarge.copyWith(
                              color: AppNeutralColors.grey900,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              const _FieldLabel(text: "이메일"),
                              const SizedBox(height: 6),
                              _LoginTextField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                hintText: "이메일 형식으로 입력해주세요.",
                                focused: _emailFocused,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                state: _emailHasFormatError
                                    ? AppInputFieldState.error
                                    : (_isEmailValid
                                          ? AppInputFieldState.success
                                          : (_emailFocused
                                                ? AppInputFieldState.focus
                                                : AppInputFieldState
                                                      .defaultState)),
                                onChanged: (_) => setState(() {
                                  _showCredentialError = false;
                                }),
                                onSubmitted: (_) =>
                                    _passwordFocusNode.requestFocus(),
                                trailing: !_hasEmailText
                                    ? null
                                    : _emailHasFormatError
                                    ? const Padding(
                                        padding: EdgeInsets.only(right: 12),
                                        child: Icon(
                                          Icons.error_outline,
                                          size: 20,
                                          color: AppSemanticColors.error500,
                                        ),
                                      )
                                    : _isEmailValid
                                    ? Padding(
                                        padding: EdgeInsets.only(right: 12),
                                        child: Icon(
                                          Icons.check,
                                          size: 20,
                                          color: brand.c500,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          _InputIconAction(
                                            icon: Icons.close,
                                            onTap: _clearEmail,
                                            color: _emailFocused
                                                ? brand.c500
                                                : AppNeutralColors.grey500,
                                          ),
                                          const SizedBox(
                                            width: AppInputTokens.supportingGap,
                                          ),
                                        ],
                                      ),
                              ),
                              if (_emailHasFormatError) ...<Widget>[
                                const SizedBox(height: 6),
                                Row(
                                  children: <Widget>[
                                    const Icon(
                                      Icons.error_outline,
                                      size: 18,
                                      color: AppSemanticColors.error500,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "올바른 이메일 형식이 아닙니다",
                                      style: AppTypography.captionMedium
                                          .copyWith(
                                            color: AppSemanticColors.error500,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 24),
                              const _FieldLabel(text: "비밀번호"),
                              const SizedBox(height: 6),
                              _LoginTextField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                hintText: "비밀번호를 입력하세요.",
                                focused: _passwordFocused,
                                obscureText: !_isPasswordVisible,
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.go,
                                state: _showCredentialError
                                    ? AppInputFieldState.error
                                    : (_passwordFocused
                                          ? AppInputFieldState.focus
                                          : AppInputFieldState.defaultState),
                                onChanged: (_) => setState(() {
                                  _showCredentialError = false;
                                }),
                                onSubmitted: (_) => _attemptLogin(),
                                trailing: !_hasPasswordText
                                    ? null
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          _InputIconAction(
                                            icon: Icons.close,
                                            onTap: _clearPassword,
                                            color: _showCredentialError
                                                ? AppSemanticColors.error500
                                                : (_passwordFocused
                                                      ? brand.c500
                                                      : AppNeutralColors
                                                            .grey500),
                                          ),
                                          const SizedBox(
                                            width: AppInputTokens.supportingGap,
                                          ),
                                          _InputIconAction(
                                            icon: _isPasswordVisible
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            onTap: () {
                                              setState(() {
                                                _isPasswordVisible =
                                                    !_isPasswordVisible;
                                              });
                                            },
                                            color: _showCredentialError
                                                ? AppSemanticColors.error500
                                                : (_passwordFocused ||
                                                          _isPasswordVisible
                                                      ? brand.c500
                                                      : AppNeutralColors
                                                            .grey600),
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _canSubmit ? _attemptLogin : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brand.c500,
                                    disabledBackgroundColor: brand.c300,
                                    foregroundColor: AppNeutralColors.white,
                                    disabledForegroundColor: brand.c100,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.br8,
                                    ),
                                  ),
                                  child: Text(
                                    "로그인",
                                    style: AppTypography.buttonLarge.copyWith(
                                      color: AppNeutralColors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _LoginLinkRow(
                                onFindId: widget.onFindId,
                                onFindPassword: widget.onFindPassword,
                                onSignUp: widget.onSignUp,
                              ),
                            ],
                          ),
                          const SizedBox(height: 56),
                          _SocialLoginSection(
                            recentLoginProviders: widget.hasRecentSocialLogin
                                ? (widget.recentSocialLoginProviders ??
                                      <String>[
                                        widget.recentSocialLoginProvider ??
                                            "kakao",
                                      ])
                                : const <String>[],
                            onSocialLogin: widget.onSocialLogin,
                          ),
                        ],
                      ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.captionLarge.copyWith(
        color: AppNeutralColors.grey900,
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.focused,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.state = AppInputFieldState.defaultState,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool focused;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;
  final AppInputFieldState state;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return SizedBox(
      height: 58,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: AppInputTokens.mdTextStyle.copyWith(
          color: AppInputTokens.textColor(
            state,
            hasValue: controller.text.isNotEmpty,
          ),
        ),
        decoration: InputDecoration(
          hintText: focused ? null : hintText,
          hintStyle: AppInputTokens.mdTextStyle.copyWith(
            color: AppInputTokens.textColor(
              AppInputFieldState.defaultState,
              hasValue: false,
            ),
          ),
          contentPadding: AppInputTokens.fieldPadding.copyWith(
            top: 16,
            bottom: 16,
          ),
          suffixIcon: trailing == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: trailing,
                ),
          suffixIconConstraints: const BoxConstraints(minHeight: 24),
          border: OutlineInputBorder(
            borderRadius: AppRadius.br8,
            borderSide: BorderSide(
              color: AppInputTokens.borderColor(state, brand: brand),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.br8,
            borderSide: BorderSide(
              color: AppInputTokens.borderColor(state, brand: brand),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.br8,
            borderSide: BorderSide(
              color: AppInputTokens.borderColor(state, brand: brand),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginLinkRow extends StatelessWidget {
  const _LoginLinkRow({this.onFindId, this.onFindPassword, this.onSignUp});

  final VoidCallback? onFindId;
  final VoidCallback? onFindPassword;
  final VoidCallback? onSignUp;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _HoverLink(label: "아이디 찾기", onTap: onFindId),
        const _VerticalDivider(),
        _HoverLink(label: "비밀번호 찾기", onTap: onFindPassword),
        const _VerticalDivider(),
        _HoverLink(label: "회원가입", onTap: onSignUp),
      ],
    );
  }
}

class _HoverLink extends StatefulWidget {
  const _HoverLink({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  State<_HoverLink> createState() => _HoverLinkState();
}

class _HoverLinkState extends State<_HoverLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap ?? () {},
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _hovered
                      ? AppNeutralColors.grey900
                      : Colors.transparent,
                  width: 1,
                ),
              ),
            ),
            child: Text(
              widget.label,
              style: AppTypography.buttonSmall.copyWith(
                color: AppNeutralColors.grey900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppNeutralColors.grey300,
    );
  }
}

class _InputIconAction extends StatelessWidget {
  const _InputIconAction({required this.icon, required this.color, this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 16,
      child: SizedBox(
        width: AppInputTokens.actionIconSize,
        height: AppInputTokens.actionIconSize,
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _SocialLoginSection extends StatelessWidget {
  const _SocialLoginSection({
    required this.recentLoginProviders,
    this.onSocialLogin,
  });

  final List<String> recentLoginProviders;
  final void Function(String provider)? onSocialLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          "간편로그인",
          style: AppTypography.headingXSmall.copyWith(
            fontSize: 16,
            color: AppNeutralColors.grey900,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: 60,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _SocialIconButton(
                        path: "assets/images/login/ic_kakao.svg",
                        onTap: () => onSocialLogin?.call("kakao"),
                      ),
                      _SocialIconButton(
                        path: "assets/images/login/ic_naver.svg",
                        onTap: () => onSocialLogin?.call("naver"),
                      ),
                      _SocialIconButton(
                        path: "assets/images/login/ic_google.svg",
                        onTap: () => onSocialLogin?.call("google"),
                      ),
                      _SocialIconButton(
                        path: "assets/images/login/ic_apple.svg",
                        onTap: () => onSocialLogin?.call("apple"),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 31,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _TooltipSlot(show: recentLoginProviders.contains("kakao")),
                    _TooltipSlot(show: recentLoginProviders.contains("naver")),
                    _TooltipSlot(show: recentLoginProviders.contains("google")),
                    _TooltipSlot(show: recentLoginProviders.contains("apple")),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({required this.path, this.onTap});

  final String path;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 60,
        height: 60,
        child: SvgPicture.asset(
          path,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => Container(
            decoration: BoxDecoration(
              color: AppNeutralColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE3E5E8)),
            ),
          ),
        ),
      ),
    );
  }
}

class _TooltipSlot extends StatelessWidget {
  const _TooltipSlot({required this.show});

  final bool show;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppTooltipTokens.width,
      height: 31,
      child: Center(
        child: show
            ? const SizedBox(
                width: AppTooltipTokens.width,
                child: AppTooltipBubble(
                  text: "최근 로그인",
                  direction: AppBubbleDirection.upCenter,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
