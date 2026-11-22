import "dart:async";

import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "../profile/initial_terms_consent_screen.dart";
import "../profile/nickname_setup_screen.dart";
import "../question/today_question_store.dart";
import "home_character_assets.dart";
import "home_character_selection_store.dart";
import "home_theme_progression.dart";
import "next_theme_unlock_screen.dart";

enum HomeCharacterSelectMode {
  /// 회원가입: 약관동의 → 캐릭터 선택 → 닉네임 설정
  signup,

  /// 지금 캐릭터를 끝까지 키운 뒤 다음 캐릭터 고르기
  nextCycle,
}

/// 60일간 함께 성장할 캐릭터(테마)를 고르는 화면.
///
/// Figma: #회원가입-프로필사진 선택하기 (21227:17749)
class HomeCharacterSelectScreen extends StatefulWidget {
  const HomeCharacterSelectScreen({
    super.key,
    this.mode = HomeCharacterSelectMode.signup,
    this.onNicknameCompleted,
    this.initialCharacterType,
  });

  final HomeCharacterSelectMode mode;

  /// 회원가입 모드에서 닉네임 설정까지 끝났을 때 (로그인 화면에서 넘겨줌).
  final void Function(BuildContext context)? onNicknameCompleted;

  /// 처음부터 선택돼 있을 캐릭터. (닉네임 화면에서 뒤로 왔을 때 등)
  final HomeCharacterType? initialCharacterType;

  static Route<void> signupRoute({
    void Function(BuildContext context)? onNicknameCompleted,
    HomeCharacterType? initialCharacterType,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => HomeCharacterSelectScreen(
        onNicknameCompleted: onNicknameCompleted,
        initialCharacterType: initialCharacterType,
      ),
    );
  }

  @override
  State<HomeCharacterSelectScreen> createState() =>
      _HomeCharacterSelectScreenState();
}

class _HomeCharacterSelectScreenState extends State<HomeCharacterSelectScreen> {
  static const double _heroSize = 160;
  static const double _thumbnailSize = 74;
  static const double _thumbnailGap = 16;

  HomeCharacterType? _selected;
  bool _isSaving = false;

  bool get _isNextCycle => widget.mode == HomeCharacterSelectMode.nextCycle;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCharacterType;
  }

  Future<void> _confirm() async {
    final HomeCharacterType? selected = _selected;
    if (selected == null || _isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await TodayQuestionStore.instance.initialize();
      await HomeCharacterSelectionStore.instance.initialize();
      await HomeCharacterSelectionStore.instance.select(
        selected,
        totalRecordCount: TodayQuestionStore.instance.value.length,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
    if (!mounted) {
      return;
    }
    if (_isNextCycle) {
      unawaited(
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) =>
                NextThemeUnlockScreen(unlockedCharacterType: selected),
          ),
        ),
      );
      return;
    }
    unawaited(
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              NicknameSetupScreen(onCompleted: widget.onNicknameCompleted),
        ),
      ),
    );
  }

  void _routeBack() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const InitialTermsConsentScreen(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final HomeCharacterType? selected = _selected;
    final HomeCharacterType previewType = selected ?? HomeCharacterType.fish;
    // 고르기 전에는 Figma 기본 메인 컬러(블루)를 쓴다.
    final BrandScale brand = selected?.brandScale ?? AppBrandThemes.blue;
    final bool canConfirm = selected != null && !_isSaving;

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, void result) {
        if (didPop || _isNextCycle) {
          return;
        }
        _routeBack();
      },
      child: Scaffold(
        backgroundColor: AppNeutralColors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              if (_isNextCycle)
                SizedBox(
                  height: AppHeaderTokens.height,
                  child: Center(
                    child: Text(
                      "캐릭터 선택",
                      style: AppHeaderTokens.titleStyle.copyWith(
                        color: AppHeaderTokens.titleColor,
                      ),
                    ),
                  ),
                )
              else
                AppHeader(
                  title: "회원가입",
                  trailing: null,
                  onLeadingPressed: _routeBack,
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s20,
                    32,
                    AppSpacing.s20,
                    AppSpacing.s16,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 350,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s8,
                            ),
                            child: Text(
                              _isNextCycle
                                  ? "다음 여정을 함께할\n캐릭터를 선택해주세요!"
                                  : "나와 함께 여정을 시작할\n캐릭터를 선택해주세요!",
                              style: AppTypography.headingLarge.copyWith(
                                color: AppNeutralColors.grey900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: _CharacterCircle(
                              key: ValueKey<String>(
                                "character-select-hero-${previewType.name}",
                              ),
                              characterType: previewType,
                              size: _heroSize,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s24),
                          Text(
                            "$homeCharacterCycleRecordCount일간 함께 성장할 캐릭터를 선택하세요.",
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyLargeMedium.copyWith(
                              color: AppNeutralColors.grey700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "테마는 $homeCharacterCycleRecordCount일마다 변경하실 수 있습니다.",
                            textAlign: TextAlign.center,
                            style: AppTypography.captionMedium.copyWith(
                              color: brand.c500,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s24),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: _thumbnailGap,
                            runSpacing: _thumbnailGap,
                            children: <Widget>[
                              for (final HomeCharacterType type
                                  in HomeCharacterType.values)
                                _CharacterThumbnail(
                                  characterType: type,
                                  size: _thumbnailSize,
                                  isSelected: type == selected,
                                  selectedColor: type.brandScale.c500,
                                  onTap: _isSaving
                                      ? null
                                      : () => setState(() => _selected = type),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: SizedBox(
                    width: 350,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: canConfirm ? _confirm : null,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        backgroundColor: brand.c500,
                        disabledBackgroundColor: AppNeutralColors.grey100,
                        foregroundColor: AppNeutralColors.white,
                        disabledForegroundColor: AppNeutralColors.grey600,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.br8,
                        ),
                        textStyle: AppTypography.buttonLarge,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppNeutralColors.white,
                              ),
                            )
                          : const Text("다음"),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterThumbnail extends StatelessWidget {
  const _CharacterThumbnail({
    required this.characterType,
    required this.size,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  final HomeCharacterType characterType;
  final double size;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: "${characterType.displayName} 캐릭터",
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          foregroundDecoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? selectedColor : Colors.transparent,
              width: 3,
            ),
          ),
          child: _CharacterCircle(characterType: characterType, size: size),
        ),
      ),
    );
  }
}

class _CharacterCircle extends StatelessWidget {
  const _CharacterCircle({
    super.key,
    required this.characterType,
    required this.size,
  });

  final HomeCharacterType characterType;
  final double size;

  @override
  Widget build(BuildContext context) {
    final int decodeSize = (size * MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(1, 1024);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: characterType.selectionBackgroundColor,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(size * 0.04),
        child: Image.asset(
          HomeCharacterAssets.selectionAssetFor(characterType),
          cacheWidth: decodeSize,
          fit: BoxFit.contain,
          errorBuilder: (_, error, stackTrace) {
            return Center(
              child: AppEmojiText(
                characterType.fallbackEmoji,
                style: TextStyle(fontSize: size * 0.45),
              ),
            );
          },
        ),
      ),
    );
  }
}
