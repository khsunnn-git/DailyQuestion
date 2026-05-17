import "package:flutter/material.dart";

import "../../design_system/design_system.dart";

class GreenThemeComingSoonPopup extends StatelessWidget {
  const GreenThemeComingSoonPopup({
    super.key,
    required this.onCloseForToday,
    required this.onConfirm,
  });

  static const double width = 308;
  static const String _sproutAsset =
      "assets/images/home/characters/tree/level_2.webp";

  final VoidCallback onCloseForToday;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    const BrandScale brand = AppBrandThemes.green;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: width),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(AppSpacing.s20),
        decoration: BoxDecoration(
          color: brand.c200,
          borderRadius: AppRadius.br16,
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x14000000),
              offset: Offset(0, 4),
              blurRadius: 8,
            ),
          ],
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
              "60번째 기록과 함께할",
              textAlign: TextAlign.center,
              style: AppTypography.headingXSmall.copyWith(
                color: AppNeutralColors.grey900,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              "귀여운 새싹테마!",
              textAlign: TextAlign.center,
              style: AppTypography.headingXSmall.copyWith(color: brand.c500),
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
              height: 110,
              child: Image.asset(
                _sproutAsset,
                fit: BoxFit.contain,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return const Center(
                        child: AppEmojiText(
                          "🌱",
                          style: TextStyle(fontSize: 72),
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
