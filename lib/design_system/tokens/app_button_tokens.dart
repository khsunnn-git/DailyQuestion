import "package:flutter/material.dart";

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

enum AppButtonType {
  textOnly,
  textIcon,
  iconOnly,
}

enum AppButtonState {
  enabled,
  hovered,
  disabled,
}

enum AppButtonSize {
  xLarge,
  large,
  medium,
  small,
}

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
}
