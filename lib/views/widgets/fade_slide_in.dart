import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_motion.dart';

/// Fade + slide entrance used for screen sections and list items.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = AppMotion.slideOffset,
  });

  final Widget child;
  final Duration delay;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(duration: AppMotion.normal, delay: delay, curve: AppMotion.entrance)
        .moveY(
          begin: offsetY,
          end: 0,
          duration: AppMotion.normal,
          delay: delay,
          curve: AppMotion.entrance,
        );
  }
}

/// Stagger helper: index * 50ms delay.
Duration staggerDelay(int index, {int stepMs = 50}) =>
    Duration(milliseconds: index * stepMs);
