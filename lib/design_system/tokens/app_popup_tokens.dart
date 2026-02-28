import "package:flutter/material.dart";

import "app_colors.dart";
import "app_elevation.dart";
import "app_radius.dart";
import "app_spacing.dart";
import "app_typography.dart";

abstract final class AppPopupTokens {
  static const double mobileWidth = 320;
  static const double maxWidth = 320;
  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(
    AppSpacing.s20,
    AppSpacing.s32,
    AppSpacing.s20,
    AppSpacing.s20,
  );
  static const double textGap = AppSpacing.s12;
  static const double contentGap = AppSpacing.s28;
  static const double actionGap = AppSpacing.s8;
  static const double textHorizontalInset = AppSpacing.s16;
  static const Color background = AppNeutralColors.white;
  static const Color dimmed = Color(0xB8000000);
  static const BorderRadius radius = AppRadius.br24;
  static const List<BoxShadow> shadow = AppElevation.level3;
  static const List<BoxShadow> bottomSheetShadow = AppElevation.level1;
  static const TextStyle titleStyle = AppTypography.headingXSmall;
  static const TextStyle bodyStyle = AppTypography.bodySmallRegular;
  static const Color titleColor = AppNeutralColors.grey900;
  static const Color bodyColor = AppNeutralColors.grey600;
}

abstract final class AppStreakPillTokens {
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s20,
    vertical: AppSpacing.s8,
  );
  static const BorderRadius radius = AppRadius.pill;
  static const Color background = AppNeutralColors.white;
  static const TextStyle textStyle = AppTypography.captionLarge;
  static const Color textColor = AppNeutralColors.grey900;
  static const List<BoxShadow> shadow = AppElevation.level1;
}
