import "package:flutter/widgets.dart";

abstract final class AppRadius {
  static const double r0 = 0;
  static const double r2 = 2;
  static const double r4 = 4;
  static const double r8 = 8;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;
  static const double r32 = 32;
  static const double full = 999;

  static const BorderRadius br4 = BorderRadius.all(Radius.circular(r4));
  static const BorderRadius br8 = BorderRadius.all(Radius.circular(r8));
  static const BorderRadius br16 = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius br20 = BorderRadius.all(Radius.circular(r20));
  static const BorderRadius br24 = BorderRadius.all(Radius.circular(r24));
  static const BorderRadius br32 = BorderRadius.all(Radius.circular(r32));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(full));
}
