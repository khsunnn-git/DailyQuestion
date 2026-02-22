import "package:flutter/material.dart";

import "app_colors.dart";
import "app_radius.dart";
import "app_spacing.dart";

enum AppItemCardState { defaultState, selected }

abstract final class AppItemCardTokens {
  static const double width = 108;
  static const double height = 120;
  static const BorderRadius radius = AppRadius.br16;
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s24,
    vertical: AppSpacing.s8,
  );
  static const double gap = AppSpacing.s4;
  static const double itemImageSize = 60;
  static const double coinIconSize = 18;

  static const Color backgroundColor = AppNeutralColors.grey50;
  static const Color textColor = AppNeutralColors.grey600;
  static const Color selectedBorderColor = AppBrandThemes.blue.c500;

  static const TextStyle priceStyle = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle nameStyle = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
  );

  static Border? border(AppItemCardState state) {
    if (state == AppItemCardState.selected) {
      return Border.all(color: selectedBorderColor, width: 1);
    }
    return null;
  }
}
