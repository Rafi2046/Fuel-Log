import 'package:flutter/animation.dart';

/// Shared motion tokens for consistent, premium animations.
abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration splash = Duration(milliseconds: 2200);

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve entrance = Curves.easeOutQuart;

  static const double slideOffset = 24;
  static const double tapScale = 0.97;
}
