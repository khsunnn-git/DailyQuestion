import "package:flutter/material.dart";

import "app_colors.dart";
import "app_radius.dart";
import "app_spacing.dart";
import "app_typography.dart";

enum AppInputFieldState { defaultState, focus, success, error, disabled }

enum AppInputSize { md, sm }

enum AppTextAreaUsage { bottomSheet, textArea }

abstract final class AppInputTokens {
  static const double fieldWidth = 350;
  static const double textAreaWidth = 326;
  static const double textButtonWidth = 350;
  static const double textButtonActionWidth = 85;

  static const double fieldHeightMd = 58;
  static const double fieldHeightSm = 48;
  static const double selectHeight = 56;
  static const double textButtonHeight = 58;
  static const double textAreaBottomSheetHeight = 156;
  static const double textAreaBoxHeight = 370;
  static const double textAreaInputPreviewHeight = 100;

  static const BorderRadius radius = AppRadius.br8;
  static const EdgeInsets fieldPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s16,
  );
  static const EdgeInsets textAreaPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s16,
    vertical: AppSpacing.s12,
  );
  static const EdgeInsets supportingPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s12,
  );

  static const double fieldGap = AppSpacing.s6;
  static const double textAreaGap = AppSpacing.s8;
  static const double supportingGap = AppSpacing.s4;
  static const double textAreaSupportingGap = AppSpacing.s6;
  static const double iconSize = 20;
  static const double actionIconSize = 24;

  static const TextStyle mdLabelStyle = AppTypography.captionLarge;
  static const TextStyle smLabelStyle = AppTypography.captionMedium;
  static const TextStyle mdTextStyle = AppTypography.bodyMediumMedium;
  static const TextStyle smTextStyle = AppTypography.bodySmallMedium;
  static const TextStyle supportingMdStyle = AppTypography.captionMedium;
  static const TextStyle supportingSmStyle = AppTypography.captionSmall;
  static const TextStyle actionButtonStyle = AppTypography.buttonMedium;

  static Color backgroundColor(AppInputFieldState state) {
    if (state == AppInputFieldState.disabled) {
      return AppNeutralColors.grey50;
    }
    return AppNeutralColors.white;
  }

  static Color borderColor(
    AppInputFieldState state, {
    bool successUseLight = false,
  }) {
    switch (state) {
      case AppInputFieldState.defaultState:
        return AppNeutralColors.grey300;
      case AppInputFieldState.focus:
        return AppBrandThemes.blue.c500;
      case AppInputFieldState.success:
        return successUseLight
            ? AppBrandThemes.blue.c400
            : AppBrandThemes.blue.c500;
      case AppInputFieldState.error:
        return AppSemanticColors.error500;
      case AppInputFieldState.disabled:
        return Colors.transparent;
    }
  }

  static Color textColor(AppInputFieldState state, {required bool hasValue}) {
    if (state == AppInputFieldState.disabled) {
      return AppNeutralColors.grey300;
    }
    if (hasValue || state == AppInputFieldState.focus) {
      return AppNeutralColors.grey900;
    }
    return AppNeutralColors.grey400;
  }

  static Color supportingColor(AppInputFieldState state) {
    switch (state) {
      case AppInputFieldState.defaultState:
        return AppNeutralColors.grey500;
      case AppInputFieldState.focus:
      case AppInputFieldState.success:
        return AppBrandThemes.blue.c500;
      case AppInputFieldState.error:
        return AppSemanticColors.error500;
      case AppInputFieldState.disabled:
        return AppNeutralColors.grey400;
    }
  }

  static Color actionBackground(AppInputFieldState state) {
    switch (state) {
      case AppInputFieldState.success:
        return AppBrandThemes.blue.c100;
      case AppInputFieldState.disabled:
        return AppNeutralColors.grey50;
      case AppInputFieldState.defaultState:
      case AppInputFieldState.focus:
      case AppInputFieldState.error:
        return AppBrandThemes.blue.c500;
    }
  }

  static Color actionForeground(AppInputFieldState state) {
    switch (state) {
      case AppInputFieldState.success:
        return AppBrandThemes.blue.c500;
      case AppInputFieldState.disabled:
        return AppNeutralColors.grey400;
      case AppInputFieldState.defaultState:
      case AppInputFieldState.focus:
      case AppInputFieldState.error:
        return AppNeutralColors.white;
    }
  }
}
