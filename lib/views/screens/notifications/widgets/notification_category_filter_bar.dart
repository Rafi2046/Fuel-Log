import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../models/app_notification_item.dart';

/// Segmented horizontal category bar with dark surface and counter badges.
class NotificationCategoryFilterBar extends StatelessWidget {
  const NotificationCategoryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.allNotifications,
  });

  final NotificationCategory selectedCategory;
  final ValueChanged<NotificationCategory> onSelectCategory;
  final List<AppNotificationItem> allNotifications;

  @override
  Widget build(BuildContext context) {
    final maintenanceCount = allNotifications
        .where((n) => n.category == NotificationCategory.maintenance)
        .length;
    final weatherCount = allNotifications
        .where((n) => n.category == NotificationCategory.weather)
        .length;
    final tipsCount = allNotifications
        .where((n) => n.category == NotificationCategory.tips)
        .length;

    final tabs = [
      (NotificationCategory.all, 'notificationsAll'.tr(), allNotifications.length),
      (
        NotificationCategory.maintenance,
        'notificationsMaintenance'.tr(),
        maintenanceCount,
      ),
      (NotificationCategory.weather, 'notificationsWeather'.tr(), weatherCount),
      (NotificationCategory.tips, 'notificationsTips'.tr(), tipsCount),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.appBarBodyGap,
        AppSpacing.screenPadding,
        AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: tabs.map((tab) {
            final isSelected = selectedCategory == tab.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => onSelectCategory(tab.$1),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.card : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.16)
                          : Colors.white.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tab.$2,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${tab.$3}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
