import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

import "../../design_system/design_system.dart";
import "nickname_setup_screen.dart";
import "user_profile_prefs.dart";

class InitialTermsConsentScreen extends StatefulWidget {
  const InitialTermsConsentScreen({super.key});

  @override
  State<InitialTermsConsentScreen> createState() =>
      _InitialTermsConsentScreenState();
}

class _InitialTermsConsentScreenState extends State<InitialTermsConsentScreen> {
  static const Color _listDividerColor = Color(0xFFE6E8EA);
  static const String _termsUrl = String.fromEnvironment(
    "TERMS_URL",
    defaultValue:
        "https://khsunnn-git.github.io/DailyQuestion/docs/policy/terms/",
  );
  static const String _privacyUrl = String.fromEnvironment(
    "PRIVACY_URL",
    defaultValue:
        "https://khsunnn-git.github.io/DailyQuestion/docs/policy/privacy/",
  );

  bool _agreedTerms = false;
  bool _agreedPrivacy = false;
  bool _isSaving = false;

  bool get _allRequiredAgreed => _agreedTerms && _agreedPrivacy;

  void _toggleAll(bool next) {
    setState(() {
      _agreedTerms = next;
      _agreedPrivacy = next;
    });
  }

  Future<void> _saveAndNext() async {
    if (!_allRequiredAgreed || _isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    await UserProfilePrefs.setInitialConsentAccepted(true);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const NicknameSetupScreen()),
    );
  }

  Future<void> _openTermsDetail() async {
    await _openPolicyUrl(_termsUrl, "이용약관");
  }

  Future<void> _openPrivacyDetail() async {
    await _openPolicyUrl(_privacyUrl, "개인정보처리방침");
  }

  Future<void> _openPolicyUrl(String rawUrl, String label) async {
    final Uri? uri = Uri.tryParse(rawUrl);
    if (uri == null ||
        !(uri.scheme == "http" || uri.scheme == "https") ||
        uri.host.isEmpty) {
      _showPolicyUrlError("$label URL이 올바르지 않아요.");
      return;
    }
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      _showPolicyUrlError("$label 페이지를 열지 못했어요.");
    }
  }

  void _showPolicyUrlError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: AppNeutralColors.white,
      body: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            right: 0,
            top: AppHeaderTokens.topInset,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s20),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: AppSpacing.s24,
                    height: AppSpacing.s24,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: AppSpacing.s24,
                        height: AppSpacing.s24,
                      ),
                      icon: const Icon(
                        Icons.arrow_back,
                        size: AppSpacing.s24,
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "이용동의",
                      textAlign: TextAlign.center,
                      style: AppTypography.headingXSmall.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s24, height: AppSpacing.s24),
                ],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.s20,
            right: AppSpacing.s20,
            top: 146,
            child: Text(
              "나를 찾아가게 되는 공간\n데일리퀘스천에\n오신걸 환영합니다!",
              style: AppTypography.headingLarge.copyWith(
                color: AppNeutralColors.grey900,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.s20,
          0,
          AppSpacing.s20,
          AppSpacing.s8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _AgreementRow(
              label: "약관 전체 동의",
              checked: _allRequiredAgreed,
              onTap: () => _toggleAll(!_allRequiredAgreed),
              withBottomBorder: true,
              dividerColor: _listDividerColor,
            ),
            _AgreementRow(
              label: "이용약관 동의(필수)",
              checked: _agreedTerms,
              onTap: () {
                setState(() {
                  _agreedTerms = !_agreedTerms;
                });
              },
              onChevronTap: _openTermsDetail,
            ),
            _AgreementRow(
              label: "개인정보 수집 및 이용 동의(필수)",
              checked: _agreedPrivacy,
              onTap: () {
                setState(() {
                  _agreedPrivacy = !_agreedPrivacy;
                });
              },
              onChevronTap: _openPrivacyDetail,
            ),
            const SizedBox(height: AppSpacing.s32),
            SizedBox(
              height: AppSpacing.s56,
              width: double.infinity,
              child: FilledButton(
                onPressed: _allRequiredAgreed && !_isSaving
                    ? _saveAndNext
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _allRequiredAgreed ? brand.c500 : brand.c300,
                  foregroundColor: _allRequiredAgreed
                      ? AppNeutralColors.white
                      : brand.c100,
                  disabledBackgroundColor: brand.c300,
                  disabledForegroundColor: brand.c100,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.s8),
                  ),
                  textStyle: AppTypography.buttonLarge,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: AppSpacing.s20,
                        height: AppSpacing.s20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppNeutralColors.white,
                        ),
                      )
                    : Text(
                        "다음",
                        style: AppTypography.buttonLarge.copyWith(
                          color: _allRequiredAgreed
                              ? AppNeutralColors.white
                              : brand.c100,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.label,
    required this.checked,
    required this.onTap,
    this.onChevronTap,
    this.withBottomBorder = false,
    this.dividerColor = AppNeutralColors.grey100,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;
  final VoidCallback? onChevronTap;
  final bool withBottomBorder;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: withBottomBorder
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: dividerColor)),
            )
          : null,
      child: Row(
        children: <Widget>[
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
                child: Row(
                  children: <Widget>[
                    _AgreementRadio(checked: checked),
                    const SizedBox(width: AppSpacing.s8),
                    Text(
                      label,
                      style: AppTypography.bodyMediumMedium.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onChevronTap != null)
            SizedBox(
              width: AppSpacing.s24,
              height: AppSpacing.s24,
              child: IconButton(
                onPressed: onChevronTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: AppSpacing.s24,
                  height: AppSpacing.s24,
                ),
                icon: const Icon(
                  Icons.chevron_right,
                  size: AppSpacing.s24,
                  color: AppNeutralColors.grey900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AgreementRadio extends StatelessWidget {
  const _AgreementRadio({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    if (checked) {
      return Container(
        width: AppSpacing.s24,
        height: AppSpacing.s24,
        decoration: BoxDecoration(shape: BoxShape.circle, color: brand.c500),
        child: const Center(
          child: Icon(Icons.check, size: 16, color: AppNeutralColors.white),
        ),
      );
    }
    return Container(
      width: AppSpacing.s24,
      height: AppSpacing.s24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppNeutralColors.grey900, width: 2),
      ),
    );
  }
}
