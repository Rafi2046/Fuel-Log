import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// Clean glass look via solid surface + specular edge — no [BackdropFilter].
///
/// Backdrop blur on a flat dark background adds little visually but triggers
/// Android compositing / hot-reload issues (invisible children, mouse_tracker).
class CleanGlassPanel extends StatelessWidget {
  const CleanGlassPanel({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AppSpacing.radiusLg),
    ),
    this.padding,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: AppColors.card,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}

/// iOS-style frosted glass — real blur on iOS, [CleanGlassPanel] on Android.
class FrostedGlassPanel extends StatelessWidget {
  const FrostedGlassPanel({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AppSpacing.radiusLg),
    ),
    this.padding,
    this.blurSigma = 22,
    this.tintOpacity = 0.55,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final double tintOpacity;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return CleanGlassPanel(
        borderRadius: borderRadius,
        padding: padding,
        child: child,
      );
    }

    final content =
        padding != null ? Padding(padding: padding!, child: child) : child;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: AppColors.card.withValues(alpha: tintOpacity),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}
