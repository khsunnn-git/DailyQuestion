import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "../auth/login_screen.dart";
import "../profile/user_profile_prefs.dart";

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onCompleted});

  final Future<void> Function()? onCompleted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<_OnboardingStep> _steps = <_OnboardingStep>[
    _OnboardingStep(
      title: "하루 한 질문에\n답해보세요!",
      description: "지금 떠오르는 생각과 감정을 가볍게\n기록하며 나만의 하루를 남겨보세요.",
      buttonLabel: "다음",
      previewAssetPath: "assets/images/onboarding/onboarding1.webp",
    ),
    _OnboardingStep(
      title: "타인의 기록을\n확인해보세요",
      description: "다양한 사용자의 기록을 살펴보고\n새로운 경험과 영감을 발견해보세요.",
      buttonLabel: "다음",
      previewAssetPath: "assets/images/onboarding/onboarding2.webp",
    ),
    _OnboardingStep(
      title: "기록이 쌓이면\n캐릭터가 자라나요!",
      description: "기록할수록 캐릭터도 함께 성장해요.\n매일 기록하며 6단계 성장을 완성해보세요.",
      buttonLabel: "다음",
      previewAssetPath: "assets/images/onboarding/onboarding3.webp",
    ),
    _OnboardingStep(
      title: "질문을 통해 발견된\n버킷리스트를 설정하고 실천해요!",
      description: "질문으로 찾은 버킷리스트를\n저장하고 디데이를 설정해 실천해보세요.",
      buttonLabel: "준비 완료",
      previewAssetPath: "assets/images/onboarding/onboarding4.webp",
    ),
  ];

  late final PageController _pageController = PageController(keepPage: false);
  int _currentIndex = 0;
  bool _isCompleting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handlePrimaryAction() async {
    if (_isCompleting) {
      return;
    }

    if (_currentIndex < _steps.length - 1) {
      await _pageController.animateToPage(
        _currentIndex + 1,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    setState(() {
      _isCompleting = true;
    });
    await UserProfilePrefs.setOnboardingSeen(true);
    if (!mounted) {
      return;
    }

    if (widget.onCompleted != null) {
      await widget.onCompleted!();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(mode: LoginScreenMode.onboarding),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return PopScope<void>(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppNeutralColors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
            child: Column(
              children: <Widget>[
                const SizedBox(height: AppSpacing.s64),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int index) {
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemCount: _steps.length,
                    itemBuilder: (BuildContext context, int index) {
                      final _OnboardingStep step = _steps[index];
                      return _OnboardingPage(
                        step: step,
                        currentIndex: _currentIndex,
                        totalCount: _steps.length,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.s20,
            0,
            AppSpacing.s20,
            AppSpacing.s8,
          ),
          child: SizedBox(
            height: AppSpacing.s56,
            child: FilledButton(
              onPressed: _handlePrimaryAction,
              style: FilledButton.styleFrom(
                backgroundColor: brand.c500,
                foregroundColor: AppNeutralColors.white,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.br8),
                textStyle: AppTypography.buttonLarge,
              ),
              child: _isCompleting
                  ? const SizedBox(
                      width: AppSpacing.s20,
                      height: AppSpacing.s20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppNeutralColors.white,
                      ),
                    )
                  : Text(_steps[_currentIndex].buttonLabel),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.step,
    required this.currentIndex,
    required this.totalCount,
  });

  final _OnboardingStep step;
  final int currentIndex;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          step.title,
          textAlign: TextAlign.center,
          style: AppTypography.headingLarge.copyWith(
            color: AppNeutralColors.grey900,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          step.description,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmallMedium.copyWith(
            color: AppNeutralColors.grey500,
          ),
        ),
        const SizedBox(height: AppSpacing.s20),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320, maxHeight: 430),
              child: Image.asset(
                step.previewAssetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s20),
        _OnboardingIndicator(
          currentIndex: currentIndex,
          totalCount: totalCount,
        ),
        const SizedBox(height: AppSpacing.s12),
      ],
    );
  }
}

class _OnboardingIndicator extends StatelessWidget {
  const _OnboardingIndicator({
    required this.currentIndex,
    required this.totalCount,
  });

  final int currentIndex;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(totalCount, (int index) {
        final bool isSelected = index == currentIndex;
        return Padding(
          padding: EdgeInsets.only(
            right: index == totalCount - 1 ? 0 : AppSpacing.s8,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: AppSpacing.s6,
            height: AppSpacing.s6,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppNeutralColors.grey700
                  : AppNeutralColors.grey200,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.previewAssetPath,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final String previewAssetPath;
}
