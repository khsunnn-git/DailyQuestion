import "package:flutter/material.dart";

import "app_colors.dart";
import "app_radius.dart";
import "app_spacing.dart";
import "app_typography.dart";

enum AppBucketTagState {
  addDefault,
  oneOrMoreAdd,
  deleteAdd,
  defaultState,
  delete,
}

class AppBucketTagStyle {
  const AppBucketTagStyle({
    required this.background,
    required this.textColor,
    required this.showHash,
    required this.showDelete,
    required this.showAdd,
  });

  final Color background;
  final Color textColor;
  final bool showHash;
  final bool showDelete;
  final bool showAdd;
}

abstract final class AppBadgeTokens {
  static const double bucketHeight = 24;
  static const EdgeInsets bucketPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s8,
    vertical: AppSpacing.s4,
  );
  static const TextStyle bucketTextStyle = AppTypography.captionSmall;
  static const Color bucketTextColor = AppNeutralColors.grey900;
  static const BorderRadius bucketRadius = AppRadius.pill;
}

abstract final class AppBucketTagTokens {
  static const double height = 38;
  static const BorderRadius radius = AppRadius.pill;
  static const TextStyle textStyle = AppTypography.bodySmallMedium;
  static const EdgeInsets defaultPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s12,
    vertical: AppSpacing.s8,
  );
  static const double innerGap = AppSpacing.s8;
  static const double iconSize = 20;

  static AppBucketTagStyle style(AppBucketTagState state) {
    switch (state) {
      case AppBucketTagState.addDefault:
        return AppBucketTagStyle(
          background: AppNeutralColors.grey100,
          textColor: AppBrandThemes.blue.c500,
          showHash: false,
          showDelete: false,
          showAdd: true,
        );
      case AppBucketTagState.oneOrMoreAdd:
        return AppBucketTagStyle(
          background: AppBrandThemes.blue.c500,
          textColor: AppNeutralColors.white,
          showHash: true,
          showDelete: false,
          showAdd: true,
        );
      case AppBucketTagState.deleteAdd:
        return AppBucketTagStyle(
          background: AppBrandThemes.blue.c500,
          textColor: AppNeutralColors.white,
          showHash: true,
          showDelete: true,
          showAdd: true,
        );
      case AppBucketTagState.defaultState:
        return AppBucketTagStyle(
          background: AppBrandThemes.blue.c500,
          textColor: AppNeutralColors.white,
          showHash: true,
          showDelete: false,
          showAdd: false,
        );
      case AppBucketTagState.delete:
        return AppBucketTagStyle(
          background: AppBrandThemes.blue.c500,
          textColor: AppNeutralColors.white,
          showHash: true,
          showDelete: true,
          showAdd: false,
        );
    }
  }
}
