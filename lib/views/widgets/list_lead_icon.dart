import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// Compact leading icon for list cards — vertically centered in rows.
class ListLeadIcon extends StatelessWidget {
  const ListLeadIcon({
    super.key,
    required this.icon,
    this.iconSize = 16,
    this.padding = 6,
  });

  final IconData icon;
  final double iconSize;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Icon(
        icon,
        color: AppColors.primary,
        size: iconSize,
      ),
    );
  }
}
