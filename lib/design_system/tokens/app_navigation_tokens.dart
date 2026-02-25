import "package:flutter/material.dart";

import "app_colors.dart";
import "app_spacing.dart";
import "app_typography.dart";

abstract final class AppHeaderTokens {
  static const double topInset = 49;
  static const double width = double.infinity;
  static const double height = 65;
  static const double horizontalPadding = AppSpacing.s20;
  static const EdgeInsets padding = EdgeInsets.all(AppSpacing.s20);
  static const double iconSize = 24;
  static const TextStyle titleStyle = AppTypography.headingXSmall;
  static const Color titleColor = AppNeutralColors.grey900;
}

abstract final class AppNavigationBarTokens {
  static const double width = double.infinity;
  static const double height = 76;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(
    AppSpacing.s40,
    AppSpacing.s16,
    AppSpacing.s40,
    AppSpacing.s0,
  );
  static const double itemWidth = 56;
  static const double itemIconSize = 24;
  static const double gap = AppSpacing.s28;
  static const double itemGap = AppSpacing.s4;
  static const TextStyle labelStyle = AppTypography.captionSmall;
  static final Color focusedColor = AppBrandThemes.blue.c500;
  static const Color unfocusedColor = AppNeutralColors.grey700;
  static const Color backgroundColor = AppTransparentColors.light64;
  static const double blurSigma = 12;
}
