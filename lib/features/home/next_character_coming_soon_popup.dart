import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "home_character_assets.dart";

/// 새 캐릭터(테마)를 고를 수 있기 일주일 전 홈에 띄우는 안내 팝업.
///
/// Figma: #홈 화면 팝업_ 새로운 테마 열리기 일주일 전 공지 (21229:18161)
/// 색상은 지금 키우고 있는 캐릭터의 테마 컬러를 그대로 쓴다.
class NextCharacterComingSoonPopup extends StatelessWidget {
  const NextCharacterComingSoonPopup({
    super.key,
    required this.onCloseForToday,
    required this.onConfirm,
    required this.currentCharacterType,
    required this.remainingRecordCount,
  });

  static const double width = 308;
  static const double _thumbnailSize = 74;
  static const double _thumbnailGap = 16;

  final VoidCallback onCloseForToday;
  final VoidCallback onConfirm;
  final HomeCharacterType currentCharacterType;
  final int remainingRecordCount;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = currentCharacterType.brandScale;
    final int decodeSize =
        (_thumbnailSize * MediaQuery.devicePixelRatioOf(context))
            .ceil()
            .clamp(1, 512);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: width),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(AppSpacing.s20),
          decoration: BoxDecoration(
            color: brand.c50,
            borderRadius: AppRadius.br16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 헤더: 오늘은 닫기 ×
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onCloseForToday,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        "오늘은 닫기",
                        style: AppTypography.captionSmall.copyWith(
                          color: AppNeutralColors.grey900,
                        ),
                      ),
                      const SizedBox(
                        width: AppSpacing.s24,
                        height: AppSpacing.s24,
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: AppNeutralColors.grey900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
              Text(
                "NEW UPDATE",
                textAlign: TextAlign.center,
                style: AppTypography.captionMedium.copyWith(color: brand.c400),
              ),
              const SizedBox(height: AppSpacing.s20),
              Text(
                remainingRecordCount <= 1
                    ? "다음 기록을 마치면"
                    : "$remainingRecordCount번만 더 기록하면",
                textAlign: TextAlign.center,
                style: AppTypography.headingLarge.copyWith(
                  color: AppNeutralColors.grey900,
                ),
              ),
              Text(
                "새로운 테마가 열려요!",
                textAlign: TextAlign.center,
                style: AppTypography.headingLarge.copyWith(color: brand.c500),
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(
                "새로운 테마를 기다려볼까요?",
                textAlign: TextAlign.center,
                style: AppTypography.bodySmallRegular.copyWith(
                  color: AppNeutralColors.grey600,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: _thumbnailGap,
                runSpacing: _thumbnailGap,
                children: <Widget>[
                  for (final HomeCharacterType type in HomeCharacterType.values)
                    Container(
                      width: _thumbnailSize,
                      height: _thumbnailSize,
                      padding: const EdgeInsets.all(_thumbnailSize * 0.04),
                      decoration: BoxDecoration(
                        color: type.selectionBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        HomeCharacterAssets.selectionAssetFor(type),
                        cacheWidth: decodeSize,
                        fit: BoxFit.contain,
                        errorBuilder: (_, error, stackTrace) {
                          return Center(
                            child: AppEmojiText(
                              type.fallbackEmoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s20),
              SizedBox(
                height: AppSpacing.s48,
                child: FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: brand.c500,
                    foregroundColor: AppNeutralColors.white,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s24,
                    ),
                    textStyle: AppTypography.buttonMedium,
                  ),
                  child: Text(
                    "확인",
                    style: AppTypography.buttonMedium.copyWith(
                      color: AppNeutralColors.white,
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
