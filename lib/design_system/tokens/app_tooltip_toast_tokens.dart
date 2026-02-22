import "package:flutter/material.dart";

import "app_colors.dart";
import "app_elevation.dart";
import "app_radius.dart";
import "app_spacing.dart";
import "app_typography.dart";

enum AppBubbleDirection {
  upLeft,
  upCenter,
  upRight,
  downLeft,
  downCenter,
  downRight,
  left,
  right,
  up,
  down,
}

enum AppSpeechBubbleVariant { primary, white }

abstract final class AppTooltipTokens {
  static const double width = 68;
  static const double height = 31;
  static const double pointerWidth = 10;
  static const double pointerHeight = 6;
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s6,
    vertical: AppSpacing.s4,
  );
  static const EdgeInsets pointerHorizontalPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s8,
  );
  static const Color background = Color(0xCC000000);
  static const Color textColor = AppNeutralColors.white;
  static const TextStyle textStyle = AppTypography.captionSmall;
  static const BorderRadius radius = AppRadius.br4;
}

abstract final class AppToastTokens {
  static const double oneLineWidth = 242;
  static const double oneLineHeight = 36;
  static const double twoLineWidth = 212;
  static const double twoLineHeight = 56;
  static const double maxWidth = 290;
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s12,
    vertical: AppSpacing.s8,
  );
  static const Color background = Color(0xCC000000);
  static const Color textColor = AppNeutralColors.white;
  static const TextStyle textStyle = AppTypography.captionMedium;
  static const BorderRadius radius = AppRadius.br4;
  static const List<BoxShadow> shadow = AppElevation.level2;
}

abstract final class AppSpeechBubbleTokens {
  static final Color primaryBackground = AppBrandThemes.blue.c500;
  static const Color primaryText = AppNeutralColors.white;
  static const Color whiteBackground = AppNeutralColors.white;
  static const Color whiteText = AppNeutralColors.grey700;
  static const BorderRadius radius = AppRadius.br16;
  static const List<BoxShadow> whiteShadow = AppElevation.level1;
  static const TextStyle textStyle = AppTypography.bodySmallMedium;
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s12,
    vertical: AppSpacing.s8,
  );
}
