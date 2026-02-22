import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

import "../../design_system/design_system.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.hasRecentSocialLogin = true,
    this.onLoginSuccess,
    this.onFindId,
    this.onFindPassword,
    this.onSignUp,
    this.onSocialLogin,
  });

  final bool hasRecentSocialLogin;
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

  bool get _canSubmit {
    return _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

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
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final bool emailValid = email.contains("@");
    final bool passwordValid = password.isNotEmpty;

    if (emailValid && passwordValid) {
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      }
      return;
    }

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
    setState(() {});
  }

  void _clearPassword() {
    _passwordController.clear();
    _passwordFocusNode.requestFocus();
    setState(() {
      _isPasswordVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppNeutralColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 80),
                      Text(
                        "Daily Question",
                        style: AppTypography.headingLarge.copyWith(
                          color: AppNeutralColors.grey900,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 350),
                        child: Column(
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
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) =>
                                  _passwordFocusNode.requestFocus(),
                              trailing: _emailController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: _clearEmail,
                                      splashRadius: 18,
                                      color: AppNeutralColors.grey500,
                                    )
                                  : null,
                            ),
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
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => _attemptLogin(),
                              trailing: _passwordController.text.isNotEmpty
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 18,
                                          ),
                                          onPressed: _clearPassword,
                                          splashRadius: 18,
                                          color: AppNeutralColors.grey500,
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            _isPasswordVisible
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible =
                                                  !_isPasswordVisible;
                                            });
                                          },
                                          splashRadius: 18,
                                          color: AppNeutralColors.grey600,
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _canSubmit ? _attemptLogin : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppBrandThemes.blue.c500,
                                  foregroundColor: AppNeutralColors.white,
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
                      ),
                      const SizedBox(height: 56),
                      _SocialLoginSection(
                        showRecentLoginTooltip: widget.hasRecentSocialLogin,
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

  @override
  Widget build(BuildContext context) {
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
        style: AppTypography.bodyMediumMedium.copyWith(
          color: AppNeutralColors.grey900,
        ),
        decoration: InputDecoration(
          hintText: focused ? null : hintText,
          hintStyle: AppTypography.bodyMediumMedium.copyWith(
            color: AppNeutralColors.grey400,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: trailing == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: trailing,
                ),
          suffixIconConstraints: const BoxConstraints(minHeight: 32),
          border: OutlineInputBorder(
            borderRadius: AppRadius.br8,
            borderSide: const BorderSide(color: AppNeutralColors.grey300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.br8,
            borderSide: const BorderSide(color: AppNeutralColors.grey300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.br8,
            borderSide: BorderSide(color: AppBrandThemes.blue.c500),
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
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            widget.label,
            style: AppTypography.buttonSmall.copyWith(
              color: _hovered
                  ? AppBrandThemes.blue.c500
                  : AppNeutralColors.grey900,
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

class _SocialLoginSection extends StatelessWidget {
  const _SocialLoginSection({
    required this.showRecentLoginTooltip,
    this.onSocialLogin,
  });

  final bool showRecentLoginTooltip;
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
          width: 294,
          height: 95,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Row(
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
              if (showRecentLoginTooltip)
                const Positioned(
                  left: 0,
                  top: 67,
                  child: _RecentLoginTooltip(),
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

class _RecentLoginTooltip extends StatelessWidget {
  const _RecentLoginTooltip();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        CustomPaint(size: const Size(10, 6), painter: _TooltipArrowPainter()),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: AppNeutralColors.black.withValues(alpha: 0.8),
            borderRadius: AppRadius.br4,
          ),
          child: Text(
            "최근 로그인",
            style: AppTypography.captionSmall.copyWith(
              color: AppNeutralColors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppNeutralColors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
