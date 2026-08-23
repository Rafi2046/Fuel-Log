import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

/// Tab-aware app bar for [DashboardScreen].
PreferredSizeWidget buildDashboardAppBar({
  required BuildContext context,
  required int currentIndex,
  required String selectedVehicle,
  VoidCallback? onVehicleTap,
}) {
  switch (currentIndex) {
    case 0:
      return AppBar(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.background,
        title: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onVehicleTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: Container(
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
          ),
        ),
      );
    case 1:
      return AppBar(
        title: Text('logsTitle'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            color: AppColors.primary,
            tooltip: 'filterLogs'.tr(),
            onPressed: () {},
          ),
        ],
      );
    case 2:
      return AppBar(
        title: Text(
          'statsTitle'.tr(),
          style: AppTextStyles.title.copyWith(color: AppColors.primary),
        ),
      );
    case 3:
      return AppBar(title: Text('settingsTitle'.tr()));
    default:
      return AppBar();
  }
}
