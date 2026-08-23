import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

/// Tab-aware app bar for [DashboardScreen].
PreferredSizeWidget buildDashboardAppBar({
  required int currentIndex,
  required String selectedVehicle,
}) {
  switch (currentIndex) {
    case 0:
      return AppBar(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.background,
        title: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedVehicle,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      );
    case 1:
      return AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            color: AppColors.primary,
            tooltip: 'Filter Logs',
            onPressed: () {},
          ),
        ],
      );
    case 2:
      return AppBar(title: const Text('My Garage'));
    case 3:
      return AppBar(title: const Text('Settings'));
    default:
      return AppBar();
  }
}
