import "package:flutter/material.dart";

import "app_colors.dart";
import "app_radius.dart";
import "app_spacing.dart";
import "app_typography.dart";

enum AppButtonHierarchy {
  primary,
  primaryR,
  secondary,
  secondaryR,
  tertiary,
  tertiaryR,
  outline,
  outlineR,
  nolineR,
  text,
}

enum AppButtonType { textOnly, textIcon, iconOnly }

enum AppButtonState { enabled, hovered, disabled }

enum AppButtonSize { xLarge, large, medium, small }

class AppButtonMetrics {
  const AppButtonMetrics({
    required this.height,
    required this.iconOnlySize,
    required this.horizontalPadding,
    required this.gap,
    required this.textStyle,
    required this.radius,
  });

  final double height;
  final double iconOnlySize;
  final double horizontalPadding;
  final double gap;
  final TextStyle textStyle;
  final BorderRadius radius;
}

class AppPillButtonStateStyle {
  const AppPillButtonStateStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    this.elevation = 0,
    this.shadowColor = const Color(0x00000000),
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final double elevation;
  final Color shadowColor;
}

abstract final class AppButtonTokens {
  static AppButtonMetrics metrics(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.xLarge:
        return const AppButtonMetrics(
          height: 60,
          iconOnlySize: 60,
          horizontalPadding: AppSpacing.s24,
          gap: AppSpacing.s8,
          textStyle: AppTypography.buttonLarge,
          radius: AppRadius.br16,
        );
      case AppButtonSize.large:
        return const AppButtonMetrics(
          height: 56,
          iconOnlySize: 56,
          horizontalPadding: AppSpacing.s20,
          gap: AppSpacing.s8,
          textStyle: AppTypography.buttonLarge,
          radius: AppRadius.br16,
        );
      case AppButtonSize.medium:
        return const AppButtonMetrics(
          height: 48,
          iconOnlySize: 48,
          horizontalPadding: AppSpacing.s16,
          gap: AppSpacing.s8,
          textStyle: AppTypography.buttonMedium,
          radius: AppRadius.br8,
        );
      case AppButtonSize.small:
        return const AppButtonMetrics(
          height: 38,
          iconOnlySize: 38,
          horizontalPadding: AppSpacing.s12,
          gap: AppSpacing.s6,
          textStyle: AppTypography.buttonSmall,
          radius: AppRadius.br8,
        );
    }
  }

  static AppPillButtonStateStyle polishActionStyle({
    required AppButtonState state,
    required BrandScale brand,
  }) {
    switch (state) {
      case AppButtonState.disabled:
        return AppPillButtonStateStyle(
          backgroundColor: Color.alphaBlend(
            AppTransparentColors.light64,
            brand.c200,
          ),
          borderColor: brand.c200,
          foregroundColor: brand.c300,
        );
      case AppButtonState.hovered:
        return AppPillButtonStateStyle(
          backgroundColor: brand.c100,
          borderColor: brand.c200,
          foregroundColor: brand.c500,
          elevation: 2,
          shadowColor: const Color(0x14000000),
        );
      case AppButtonState.enabled:
        return AppPillButtonStateStyle(
          backgroundColor: brand.c100,
          borderColor: brand.c200,
          foregroundColor: brand.c500,
        );
    }
  }
}
