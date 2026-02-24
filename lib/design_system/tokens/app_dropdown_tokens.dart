import "package:flutter/material.dart";

import "app_colors.dart";
import "app_elevation.dart";
import "app_radius.dart";
import "app_spacing.dart";
import "app_typography.dart";

enum AppDropdownItemState { defaultState, hovered, selected }

enum AppDropdownMenuSize { lg, md, sm }

class AppDropdownItemStyle {
  const AppDropdownItemStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.showCheck,
  });

  final Color backgroundColor;
  final Color textColor;
  final bool showCheck;
}

class AppDropdownMenuStyle {
  const AppDropdownMenuStyle({required this.width, required this.shadow});

  final double width;
  final List<BoxShadow> shadow;
}

abstract final class AppDropdownTokens {
  static const double itemHeight = 44;
  static const double itemInnerHeight = 24;
  static const double itemIconSize = 20;
  static const double radius = AppRadius.r8;
  static const EdgeInsets menuPadding = EdgeInsets.symmetric(
    vertical: AppSpacing.s8,
  );
  static const EdgeInsets itemPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s12,
  );
  static const TextStyle itemTextStyle = AppTypography.bodySmallSemiBold;

  static const Color background = AppNeutralColors.white;
  static const Color hoveredBackground = AppNeutralColors.grey50;
  static const Color defaultText = AppNeutralColors.grey900;
  static final Color selectedText = AppBrandThemes.blue.c500;

  static AppDropdownItemStyle itemStyle(AppDropdownItemState state) {
    switch (state) {
      case AppDropdownItemState.defaultState:
        return const AppDropdownItemStyle(
          backgroundColor: Colors.transparent,
          textColor: defaultText,
          showCheck: false,
        );
      case AppDropdownItemState.hovered:
        return const AppDropdownItemStyle(
          backgroundColor: hoveredBackground,
          textColor: defaultText,
          showCheck: false,
        );
      case AppDropdownItemState.selected:
        return AppDropdownItemStyle(
          backgroundColor: Colors.transparent,
          textColor: selectedText,
          showCheck: true,
        );
    }
  }

  static AppDropdownMenuStyle menuStyle(AppDropdownMenuSize size) {
    switch (size) {
      case AppDropdownMenuSize.lg:
        return const AppDropdownMenuStyle(
          width: 110,
          shadow: AppElevation.level2,
        );
      case AppDropdownMenuSize.md:
        return const AppDropdownMenuStyle(
          width: 84,
          shadow: AppElevation.level3,
        );
      case AppDropdownMenuSize.sm:
        return const AppDropdownMenuStyle(
          width: 84,
          shadow: AppElevation.level3,
        );
    }
  }
}
