import "package:flutter/material.dart";

import "app_colors.dart";
import "app_elevation.dart";
import "app_radius.dart";
import "app_spacing.dart";
import "app_typography.dart";

enum AppControlState { selected, defaultState, disabled }

class AppSegmentedButtonStyle {
  const AppSegmentedButtonStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.padding,
    required this.borderRadius,
    required this.shadows,
    required this.textStyle,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;
  final TextStyle textStyle;
}

abstract final class AppSegmentedTokens {
  static const double gap = AppSpacing.s8;

  static AppSegmentedButtonStyle style(AppControlState state) {
    switch (state) {
      case AppControlState.selected:
        return AppSegmentedButtonStyle(
          backgroundColor: AppBrandThemes.blue.c100,
          borderColor: AppBrandThemes.blue.c500,
          textColor: AppBrandThemes.blue.c500,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s20,
            vertical: AppSpacing.s6,
          ),
          borderRadius: AppRadius.pill,
          shadows: AppElevation.level1,
          textStyle: AppTypography.bodySmallSemiBold,
        );
      case AppControlState.defaultState:
      case AppControlState.disabled:
        return const AppSegmentedButtonStyle(
          backgroundColor: AppNeutralColors.white,
          borderColor: Colors.transparent,
          textColor: AppNeutralColors.grey600,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s20,
            vertical: AppSpacing.s6,
          ),
          borderRadius: AppRadius.pill,
          shadows: AppElevation.level1,
          textStyle: AppTypography.bodySmallSemiBold,
        );
    }
  }
}

class AppTabButtonStyle {
  const AppTabButtonStyle({
    required this.textColor,
    required this.borderColor,
    required this.padding,
    required this.textStyle,
  });

  final Color textColor;
  final Color borderColor;
  final EdgeInsets padding;
  final TextStyle textStyle;
}

abstract final class AppTabTokens {
  static const double width = 78;
  static const double selectedBottomBorderWidth = 2;
  static const double containerHorizontalPadding = AppSpacing.s20;
  static const BorderSide containerBottomBorder = BorderSide(
    color: AppNeutralColors.grey200,
    width: 1,
  );

  static AppTabButtonStyle style(AppControlState state) {
    switch (state) {
      case AppControlState.selected:
        return AppTabButtonStyle(
          textColor: AppBrandThemes.blue.c500,
          borderColor: AppBrandThemes.blue.c500,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s20,
            vertical: AppSpacing.s12,
          ),
          textStyle: AppTypography.bodyMediumSemiBold,
        );
      case AppControlState.defaultState:
      case AppControlState.disabled:
        return const AppTabButtonStyle(
          textColor: AppNeutralColors.grey500,
          borderColor: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s20,
            vertical: AppSpacing.s12,
          ),
          textStyle: AppTypography.bodyMediumSemiBold,
        );
    }
  }
}

abstract final class AppRadioTokens {
  static const double iconSizeSm = 20;
  static const double iconSizeMd = 24;
  static const double gapSm = AppSpacing.s4;
  static const double gapMd = AppSpacing.s8;
  static const TextStyle labelSm = AppTypography.bodySmallMedium;
  static const TextStyle labelMd = AppTypography.bodyMediumMedium;
  static const Color labelEnabled = AppNeutralColors.grey900;
  static const Color labelDisabled = AppNeutralColors.grey300;
}

abstract final class AppToggleTokens {
  static const double iconOnlySize = 58;
  static const double labelGap = AppSpacing.s8;
  static const TextStyle label = AppTypography.captionLarge;
  static const Color labelEnabled = AppNeutralColors.grey900;
  static const Color labelDisabled = AppNeutralColors.grey300;
}
