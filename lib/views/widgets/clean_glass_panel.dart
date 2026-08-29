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
