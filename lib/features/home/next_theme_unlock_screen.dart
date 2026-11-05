import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "home_character_assets.dart";
import "home_fish_growth.dart";
import "home_screen.dart";

class NextThemeUnlockScreen extends StatelessWidget {
  const NextThemeUnlockScreen({
    super.key,
    this.fallbackHomeBuilder,
    this.unlockedCharacterType = HomeCharacterType.tree,
  });

  final WidgetBuilder? fallbackHomeBuilder;
  final HomeCharacterType unlockedCharacterType;

  void _handleNext(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: fallbackHomeBuilder ?? (_) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = switch (unlockedCharacterType) {
      HomeCharacterType.tree => AppBrandThemes.green,
      HomeCharacterType.stone => AppBrandThemes.brown,
      HomeCharacterType.fish => AppBrandThemes.blue,
    };
    final String assetPath = HomeCharacterAssets.assetFor(
      unlockedCharacterType,
      HomeFishGrowthLevel.level1,
    );
    final String themeName = switch (unlockedCharacterType) {
      HomeCharacterType.tree => "새싹",
      HomeCharacterType.stone => "돌맹이",
      HomeCharacterType.fish => "물고기",
    };
    final String fallbackEmoji = switch (unlockedCharacterType) {
      HomeCharacterType.tree => "🌱",
      HomeCharacterType.stone => "🪨",
      HomeCharacterType.fish => "🐟",
    };

    return Scaffold(
      backgroundColor: AppNeutralColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double topSpacing = (constraints.maxHeight * 0.2).clamp(
              AppSpacing.s80,
              AppSpacing.s160,
            );
            final double textToImageSpacing = (constraints.maxHeight * 0.1)
                .clamp(AppSpacing.s40, AppSpacing.s80);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
              child: Column(
                children: <Widget>[
                  SizedBox(height: topSpacing),
                  Text(
                    "축하해요!\n$themeName 테마가 열렸어요!",
                    textAlign: TextAlign.center,
                    style: AppTypography.headingLarge.copyWith(
                      color: AppNeutralColors.grey900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    "새로운 테마와 함께 기록을\n이어가보세요!",
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmallMedium.copyWith(
                      color: AppNeutralColors.grey500,
                    ),
                  ),
                  SizedBox(height: textToImageSpacing),
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: OverflowBox(
                      maxWidth: 260,
                      maxHeight: 260,
                      child: Image.asset(
                        assetPath,
                        width: 260,
                        height: 260,
                        fit: BoxFit.contain,
                        errorBuilder: (_, error, stackTrace) {
                          return Center(
                            child: AppEmojiText(
                              fallbackEmoji,
                              style: const TextStyle(fontSize: 96),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: () => _handleNext(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: brand.c500,
                        foregroundColor: AppNeutralColors.white,
                        disabledBackgroundColor: brand.c200,
                        disabledForegroundColor: AppNeutralColors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.br8,
                        ),
                        textStyle: AppTypography.buttonLarge,
                      ),
                      child: const Text("다음"),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
