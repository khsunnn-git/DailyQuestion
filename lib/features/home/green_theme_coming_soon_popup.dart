import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "home_character_assets.dart";
import "home_fish_growth.dart";
import "home_theme_progression.dart";

class GreenThemeComingSoonPopup extends StatelessWidget {
  const GreenThemeComingSoonPopup({
    super.key,
    required this.onCloseForToday,
    required this.onConfirm,
    this.targetCharacterType = HomeCharacterType.tree,
  });

  static const double width = 308;

  final VoidCallback onCloseForToday;
  final VoidCallback onConfirm;
  final HomeCharacterType targetCharacterType;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = switch (targetCharacterType) {
      HomeCharacterType.tree => AppBrandThemes.green,
      HomeCharacterType.stone => AppBrandThemes.brown,
      HomeCharacterType.fish => AppBrandThemes.blue,
    };
    final int unlockRecordCount = switch (targetCharacterType) {
      HomeCharacterType.tree => homeGreenThemeUnlockRecordCount,
      HomeCharacterType.stone => homeBrownThemeUnlockRecordCount,
      HomeCharacterType.fish => 0,
    };
    final String themeName = switch (targetCharacterType) {
      HomeCharacterType.tree => "새싹",
      HomeCharacterType.stone => "돌맹이",
      HomeCharacterType.fish => "물고기",
    };
    final String fallbackEmoji = switch (targetCharacterType) {
      HomeCharacterType.tree => "🌱",
      HomeCharacterType.stone => "🪨",
      HomeCharacterType.fish => "🐟",
    };
    final HomeFishGrowthLevel previewLevel = switch (targetCharacterType) {
      HomeCharacterType.stone => HomeFishGrowthLevel.level1,
      _ => HomeFishGrowthLevel.level2,
    };
    final String assetPath = HomeCharacterAssets.assetFor(
      targetCharacterType,
      previewLevel,
    );
    final Color backgroundColor = switch (targetCharacterType) {
      HomeCharacterType.stone => brand.bg,
      _ => brand.c200,
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: width),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(AppSpacing.s20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppRadius.br16,
          boxShadow: AppElevation.level2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextButton(
                    onPressed: onCloseForToday,
                    style: TextButton.styleFrom(
                      foregroundColor: AppNeutralColors.grey900,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "오늘은 닫기",
                      style: AppTypography.captionSmall.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  SizedBox(
                    width: AppSpacing.s24,
                    height: AppSpacing.s24,
                    child: IconButton(
                      onPressed: onCloseForToday,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: AppSpacing.s24,
                        height: AppSpacing.s24,
                      ),
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              "NEW UPDATE",
              textAlign: TextAlign.center,
              style: AppTypography.heading2XSmall.copyWith(color: brand.c400),
            ),
            const SizedBox(height: AppSpacing.s20),
            Text(
              "$unlockRecordCount번째 기록과 함께할",
              textAlign: TextAlign.center,
              style: AppTypography.headingLarge.copyWith(
                color: AppNeutralColors.grey900,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              "귀여운 $themeName테마!",
              textAlign: TextAlign.center,
              style: AppTypography.headingLarge.copyWith(color: brand.c500),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              "새로운 테마를 기다려볼까요?",
              textAlign: TextAlign.center,
              style: AppTypography.bodySmallRegular.copyWith(
                color: AppNeutralColors.grey600,
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            SizedBox(
              height: targetCharacterType == HomeCharacterType.stone
                  ? 144
                  : 110,
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return Center(
                        child: AppEmojiText(
                          fallbackEmoji,
                          style: const TextStyle(fontSize: 72),
                        ),
                      );
                    },
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.s48,
              child: FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: brand.c500,
                  foregroundColor: AppNeutralColors.white,
                  disabledBackgroundColor: brand.c300,
                  disabledForegroundColor: AppNeutralColors.white,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
                  textStyle: AppTypography.buttonMedium,
                ),
                child: Text(
                  "확인",
                  style: AppTypography.buttonMedium.copyWith(
                    color: AppNeutralColors.white,
                    decoration: TextDecoration.none,
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
