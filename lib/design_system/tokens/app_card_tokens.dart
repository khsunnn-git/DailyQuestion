import "package:flutter/material.dart";

import "app_colors.dart";
import "app_elevation.dart";
import "app_radius.dart";
import "app_spacing.dart";
import "app_typography.dart";

enum AppStreakStarState { defaultState, missed, success }

abstract final class AppCardTokens {
  static const Color background = AppNeutralColors.white;
  static const List<BoxShadow> shadow = AppElevation.level1;

  // Daily streak check
  static const double dailyWidth = 350;
  static const double dailyHeight = 255;
  static const EdgeInsets dailyPadding = EdgeInsets.all(AppSpacing.s32);
  static const BorderRadius dailyRadius = AppRadius.br16;
  static const TextStyle dailyTitleStyle = AppTypography.headingLarge;
  static const TextStyle dailyBodyStyle = AppTypography.bodySmallRegular;
  static const TextStyle dailyWeekdayStyle = AppTypography.bodySmallMedium;
  static const double weekItemGap = AppSpacing.s8;
  static const double weekStarSize = 32;

  // Record preview
  static const double recordPreviewWidth = 350;
  static const double recordPreviewHeight = 458;
  static const EdgeInsets recordPreviewPadding = EdgeInsets.all(AppSpacing.s32);
  static const BorderRadius recordPreviewRadius = AppRadius.br24;
  static const TextStyle recordDateStyle = AppTypography.bodyMediumSemiBold;
  static const TextStyle recordTitleStyle =
      AppTypography.headingMediumExtraBold;
  static const TextStyle recordBodyStyle = AppTypography.bodyLargeMedium;

  // Insight card
  static const double insightWidth = 342;
  static const EdgeInsets insightPadding = EdgeInsets.all(AppSpacing.s24);
  static const BorderRadius insightRadius = AppRadius.br16;
  static const double insightIconSize = 50;
  static const TextStyle insightTitleStyle = AppTypography.headingXSmall;
  static const TextStyle insightBodyStyle = AppTypography.bodyMediumRegular;
  static const double insightGap = AppSpacing.s20;

  // Today's records
  static const double todayWidth = 320;
  static const double todayHeight = 154;
  static const EdgeInsets todayPadding = EdgeInsets.all(AppSpacing.s24);
  static const BorderRadius todayRadius = AppRadius.br16;
  static const TextStyle todayBodyStyle = AppTypography.bodyMediumMedium;
  static const TextStyle todayNameStyle = AppTypography.bodyMediumMedium;
  static const Color todayNameColor = AppBrandThemes.blue.c500;
  static const Color todayEmptyCtaColor = AppBrandThemes.blue.c400;

  // Today's other records
  static const double todayOtherWidth = 350;
  static const double todayOtherHeight = 205;
  static const EdgeInsets todayOtherPadding = EdgeInsets.all(AppSpacing.s32);
  static const BorderRadius todayOtherRadius = AppRadius.br16;
  static const TextStyle todayOtherBodyStyle = AppTypography.bodyMediumMedium;
  static const TextStyle todayOtherNameStyle = AppTypography.bodySmallSemiBold;

  static Color streakStarBackground(AppStreakStarState state) {
    switch (state) {
      case AppStreakStarState.defaultState:
        return AppNeutralColors.grey100;
      case AppStreakStarState.missed:
        return AppSemanticColors.success50;
      case AppStreakStarState.success:
        return AppSemanticColors.success500;
    }
  }

  static Border? streakStarBorder(AppStreakStarState state) {
    switch (state) {
      case AppStreakStarState.defaultState:
        return null;
      case AppStreakStarState.missed:
        return Border.all(
          color: AppSemanticColors.success300,
          width: 1,
          style: BorderStyle.solid,
        );
      case AppStreakStarState.success:
        return Border.all(color: AppSemanticColors.success600, width: 1);
    }
  }
}
