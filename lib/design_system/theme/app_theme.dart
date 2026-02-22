import "package:flutter/material.dart";

import "../tokens/app_colors.dart";
import "../tokens/app_radius.dart";
import "../tokens/app_typography.dart";

enum AppBrandTheme {
  blue,
  green,
  brown,
  purple,
}

class AppThemePalette extends ThemeExtension<AppThemePalette> {
  const AppThemePalette({
    required this.brand,
  });

  final BrandScale brand;

  @override
  ThemeExtension<AppThemePalette> copyWith({
    BrandScale? brand,
  }) {
    return AppThemePalette(
      brand: brand ?? this.brand,
    );
  }

  @override
  ThemeExtension<AppThemePalette> lerp(
    covariant ThemeExtension<AppThemePalette>? other,
    double t,
  ) {
    if (other is! AppThemePalette) return this;
    return t < 0.5 ? this : other;
  }
}

abstract final class AppTheme {
  static ThemeData of(AppBrandTheme brandTheme) {
    late final BrandScale brand;
    switch (brandTheme) {
      case AppBrandTheme.blue:
        brand = AppBrandThemes.blue;
        break;
      case AppBrandTheme.green:
        brand = AppBrandThemes.green;
        break;
      case AppBrandTheme.brown:
        brand = AppBrandThemes.brown;
        break;
      case AppBrandTheme.purple:
        brand = AppBrandThemes.purple;
        break;
    }

    final ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: brand.c500,
      onPrimary: AppNeutralColors.white,
      secondary: brand.c400,
      onSecondary: AppNeutralColors.grey900,
      error: AppSemanticColors.error500,
      onError: AppNeutralColors.white,
      surface: AppNeutralColors.white,
      onSurface: AppNeutralColors.grey900,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppFontFamily.suit,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brand.bg,
      cardColor: AppNeutralColors.white,
      dividerColor: AppNeutralColors.grey100,
      disabledColor: AppNeutralColors.grey300,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      textTheme: const TextTheme(
        displayLarge: AppTypography.headingLarge,
        titleLarge: AppTypography.headingSmall,
        titleMedium: AppTypography.headingXSmall,
        bodyLarge: AppTypography.bodyLargeRegular,
        bodyMedium: AppTypography.bodyMediumRegular,
        bodySmall: AppTypography.bodySmallRegular,
        labelLarge: AppTypography.buttonLarge,
        labelMedium: AppTypography.buttonMedium,
        labelSmall: AppTypography.buttonSmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppNeutralColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: AppRadius.br8,
          borderSide: const BorderSide(color: AppNeutralColors.grey200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.br8,
          borderSide: const BorderSide(color: AppNeutralColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.br8,
          borderSide: BorderSide(color: brand.c500, width: 1.5),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppThemePalette(brand: brand),
      ],
    );
  }
}
