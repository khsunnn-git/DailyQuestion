import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "home_character_assets.dart";
import "home_fish_growth.dart";
import "home_screen.dart";

class NextThemeUnlockScreen extends StatelessWidget {
  const NextThemeUnlockScreen({super.key, this.fallbackHomeBuilder});

  final WidgetBuilder? fallbackHomeBuilder;

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
    const BrandScale brand = AppBrandThemes.green;
    final String assetPath = HomeCharacterAssets.assetFor(
      HomeCharacterType.tree,
      HomeFishGrowthLevel.level1,
    );

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
                    "축하해요!\n새싹 테마가 열렸어요!",
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
                          return const Center(
                            child: AppEmojiText(
                              "🌱",
                              style: TextStyle(fontSize: 96),
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
