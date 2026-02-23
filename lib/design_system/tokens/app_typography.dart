import "package:flutter/material.dart";

abstract final class AppFontFamily {
  static const String suit = "SUIT Variable";
}

abstract final class AppTypography {
  // Heading
  static const TextStyle headingLarge = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle headingMediumExtraBold = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.6,
    letterSpacing: 0,
  );

  static const TextStyle headingMediumBold = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle headingXSmall = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle heading2XSmall = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0,
  );

  // Body
  static const TextStyle bodyXLargeSemiBold = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
  );
  static const TextStyle bodyXLargeMedium = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
  );
  static const TextStyle bodyXLargeRegular = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle bodyLargeSemiBold = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
  );
  static const TextStyle bodyLargeMedium = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
  );
  static const TextStyle bodyLargeRegular = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.8,
    letterSpacing: 0,
  );

  static const TextStyle bodyMediumSemiBold = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
  );
  static const TextStyle bodyMediumMedium = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
  );
  static const TextStyle bodyMediumRegular = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle bodySmallSemiBold = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
  );
  static const TextStyle bodySmallMedium = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
  );
  static const TextStyle bodySmallRegular = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  // Button
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0,
  );
  static const TextStyle buttonMedium = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0,
  );
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0,
  );

  // Caption
  static const TextStyle captionLarge = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0,
  );
  static const TextStyle captionMedium = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0,
  );
  static const TextStyle captionSmall = TextStyle(
    fontFamily: AppFontFamily.suit,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );
}
