import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/constants/app_text_styles.dart';

/// Visual tab item for the dashboard bottom navigation.
class DashboardNavItem extends StatelessWidget {
  const DashboardNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  final IconData icon;
  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textTertiary;

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.emphasized,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: isSelected
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.16),
                  AppColors.primary.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
