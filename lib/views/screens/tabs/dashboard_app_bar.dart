import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../widgets/app_app_bar.dart';
import '../reminders/reminders_screen.dart';

/// Tab-aware app bar for [DashboardScreen] with modern luxury styling.
PreferredSizeWidget buildDashboardAppBar({
  required BuildContext context,
  required int currentIndex,
  required Vehicle? activeVehicle,
  VoidCallback? onVehicleTap,
  VoidCallback? onFuelStationsTap,
}) {
  switch (currentIndex) {
    case 0:
      final type = activeVehicle?.type.toLowerCase() ?? '';
      final isBike = type == 'bike' ||
          type.contains('bike') ||
          type.contains('motorcycle') ||
          type.contains('scooter') ||
          (activeVehicle?.name.toLowerCase().contains('bike') ?? false) ||
          (activeVehicle?.name.toLowerCase().contains('r15') ?? false);
      final vehicleIcon = isBike
          ? Icons.two_wheeler_rounded
          : Icons.directions_car_filled_rounded;
      final vehicleName = activeVehicle?.name ?? 'My Garage';
      final subtitle = activeVehicle?.fuelType ?? 'Add Vehicle';

      return AppAppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: AppSpacing.screenPadding,
        titleWidget: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onVehicleTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      vehicleIcon,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        vehicleName,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textTertiary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          // Gas Stations & Live Fuel Rates Button
          Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Gas Stations & Prices',
              iconSize: 18,
              icon: const Icon(
                Icons.local_gas_station_rounded,
                color: AppColors.primary,
              ),
              onPressed: onFuelStationsTap,
            ),
          ),

          // Notification / Reminders Button
          Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(right: AppSpacing.screenPadding),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'reminders'.tr(),
              iconSize: 18,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RemindersScreen(),
                  ),
                );
              },
              icon: Badge(
                isLabelVisible: true,
                smallSize: 7,
                backgroundColor: AppColors.primary,
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      );
    case 1:
      return AppAppBar(
        automaticallyImplyLeading: false,
        title: 'logsTitle'.tr(),
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
      return AppAppBar(
        automaticallyImplyLeading: false,
        titleWidget: Text(
          'statsTitle'.tr(),
          style: AppTextStyles.title.copyWith(color: AppColors.primary),
        ),
      );
    case 3:
      return AppAppBar(
        automaticallyImplyLeading: false,
        title: 'settingsTitle'.tr(),
      );
    default:
      return const AppAppBar(automaticallyImplyLeading: false);
  }
}
