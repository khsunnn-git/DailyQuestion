import "package:flutter/material.dart";

class BrandScale {
  const BrandScale({
    required this.bg,
    required this.c50,
    required this.c100,
    required this.c200,
    required this.c300,
    required this.c400,
    required this.c500,
    required this.c600,
    required this.c700,
    required this.c800,
    required this.c900,
  });

  final Color bg;
  final Color c50;
  final Color c100;
  final Color c200;
  final Color c300;
  final Color c400;
  final Color c500;
  final Color c600;
  final Color c700;
  final Color c800;
  final Color c900;
}

abstract final class AppNeutralColors {
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFF7F8F9);
  static const Color grey100 = Color(0xFFE1E2E4);
  static const Color grey200 = Color(0xFFCBCDCF);
  static const Color grey300 = Color(0xFFB5B7BA);
  static const Color grey400 = Color(0xFFA0A1A4);
  static const Color grey500 = Color(0xFF8A8B8E);
  static const Color grey600 = Color(0xFF747578);
  static const Color grey700 = Color(0xFF5E5F62);
  static const Color grey800 = Color(0xFF48494C);
  static const Color grey900 = Color(0xFF111111);
}

abstract final class AppSemanticColors {
  static const Color warning50 = Color(0xFFFFF1E6);
  static const Color warning100 = Color(0xFFFFD6B8);
  static const Color warning300 = Color(0xFFFF9F45);
  static const Color warning500 = Color(0xFFF97316);
  static const Color warning600 = Color(0xFFEA580C);

  static const Color error50 = Color(0xFFFFF2F2);
  static const Color error100 = Color(0xFFFFD8D8);
  static const Color error300 = Color(0xFFFF8A8A);
  static const Color error500 = Color(0xFFF44336);
  static const Color error600 = Color(0xFFD7382D);

  static const Color success50 = Color(0xFFFFFCDB);
  static const Color success100 = Color(0xFFFFF4A8);
  static const Color success300 = Color(0xFFFFEB6A);
  static const Color success500 = Color(0xFFFFE209);
  static const Color success600 = Color(0xFFFFD400);

  static const Color info50 = Color(0xFFF0FBFF);
  static const Color info100 = Color(0xFFD9F3FF);
  static const Color info300 = Color(0xFF82D8FF);
  static const Color info500 = Color(0xFF35B8F0);
  static const Color info600 = Color(0xFF1F9CCC);
}

abstract final class AppAccentColors {
  static const Color mint = Color(0xFFA5F3E4);
  static const Color sky = Color(0xFFA8D8FF);
  static const Color coral = Color(0xFFFFB8A8);
  static const Color lemon = Color(0xFFFFE89A);
  static const Color lavender = Color(0xFFD9C8FF);
  static const Color peach = Color(0xFFFFD7B5);
  static const Color oliveMist = Color(0xFFDCEBC4);
  static const Color cyanBreeze = Color(0xFFC2F1F5);
  static const Color rosePetal = Color(0xFFF8C7D4);
  static const Color plumMilk = Color(0xFFE9C4E6);
  static const Color periwinkle = Color(0xFFC9D3FF);
  static const Color softMocha = Color(0xFFE9D8C6);
}

abstract final class AppTransparentColors {
  static const Color light64 = Color(0xA3FFFFFF);
  static const Color light48 = Color(0x7AFFFFFF);
}

abstract final class AppBrandThemes {
  static const BrandScale blue = BrandScale(
    bg: Color(0xFFF7FAFC),
    c50: Color(0xFFF8FDFF),
    c100: Color(0xFFE9F6FF),
    c200: Color(0xFFD3EEFF),
    c300: Color(0xFFB6E2FF),
    c400: Color(0xFF86CAFF),
    c500: Color(0xFF017AF7),
    c600: Color(0xFF0069D6),
    c700: Color(0xFF0054AD),
    c800: Color(0xFF003E7F),
    c900: Color(0xFF002A52),
  );

  static const BrandScale green = BrandScale(
    bg: Color(0xFFF6F8F5),
    c50: Color(0xFFFDFFF6),
    c100: Color(0xFFFAFFEA),
    c200: Color(0xFFB8EAB9),
    c300: Color(0xFF7BD49C),
    c400: Color(0xFF3EBF7E),
    c500: Color(0xFF00AA60),
    c600: Color(0xFF008A4F),
    c700: Color(0xFF007442),
    c800: Color(0xFF006D3A),
    c900: Color(0xFF00472A),
  );

  static const BrandScale brown = BrandScale(
    bg: Color(0xFFF8F6F3),
    c50: Color(0xFFF8F1E8),
    c100: Color(0xFFF1E6DA),
    c200: Color(0xFFE7D8C7),
    c300: Color(0xFFD7C5B0),
    c400: Color(0xFFC4AE98),
    c500: Color(0xFF7A675B),
    c600: Color(0xFF6A594F),
    c700: Color(0xFF5A4B43),
    c800: Color(0xFF463A33),
    c900: Color(0xFF2F2621),
  );

  static const BrandScale purple = BrandScale(
    bg: Color(0xFFF8F3F8),
    c50: Color(0xFFF3EBF6),
    c100: Color(0xFFEEE1F3),
    c200: Color(0xFFE7D5ED),
    c300: Color(0xFFD7BFE7),
    c400: Color(0xFFBF94DD),
    c500: Color(0xFF9456C2),
    c600: Color(0xFF7E41AC),
    c700: Color(0xFF683396),
    c800: Color(0xFF4F2674),
    c900: Color(0xFF361A50),
  );
}
