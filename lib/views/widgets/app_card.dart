import 'package:flutter/material.dart';

import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import 'clean_glass_panel.dart';

/// Primary content container — clean glass surface on dark backgrounds.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.onTap,
    this.elevated = false,
    this.showBorder = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool elevated;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusLg);

    Widget panel = CleanGlassPanel(
      borderRadius: radius,
      padding: padding,
      child: child,
    );

    if (elevated) {
      panel = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppShadows.card,
        ),
        child: panel,
      );
    }

    if (onTap == null) return panel;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: panel,
    );
  }
}
