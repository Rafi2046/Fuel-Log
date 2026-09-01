import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/vehicle_display.dart';
import '../../../viewmodels/reminder_viewmodel.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/clean_glass_panel.dart';
import '../notifications/notifications_screen.dart';
import 'dashboard_bar_metrics.dart';

/// Tab-aware app bar for [DashboardScreen].
PreferredSizeWidget buildDashboardAppBar({
  required BuildContext context,
  required int currentIndex,
  required Vehicle? activeVehicle,
  VoidCallback? onVehicleTap,
  VoidCallback? onFuelStationsTap,
  VoidCallback? onBackToHome,
}) {
  switch (currentIndex) {
    case 0:
      return HomeDashboardAppBar(
        activeVehicle: activeVehicle,
        onVehicleTap: onVehicleTap,
        onFuelStationsTap: onFuelStationsTap,
      );
    case 1:
      return AppAppBar(
        leading: onBackToHome != null ? AppBackButton(onPressed: onBackToHome) : null,
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
        leading: onBackToHome != null ? AppBackButton(onPressed: onBackToHome) : null,
        title: 'statsTitle'.tr(),
      );
    case 3:
      return AppAppBar(
        leading: onBackToHome != null ? AppBackButton(onPressed: onBackToHome) : null,
        title: 'settingsTitle'.tr(),
      );
    default:
      return AppAppBar(
        leading: onBackToHome != null ? AppBackButton(onPressed: onBackToHome) : null,
      );
  }
}

/// Unified glass home header — vehicle switcher + ghost actions.
class HomeDashboardAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HomeDashboardAppBar({
    super.key,
    required this.activeVehicle,
    this.onVehicleTap,
    this.onFuelStationsTap,
  });

  final Vehicle? activeVehicle;
  final VoidCallback? onVehicleTap;
  final VoidCallback? onFuelStationsTap;

  static const _barHeight = DashboardBarMetrics.barHeight;
  static const _outerVPad = DashboardBarMetrics.outerVPad;

  @override
  Size get preferredSize =>
      const Size.fromHeight(_barHeight + _outerVPad * 2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);
    final hasAlerts =
        reminders.overdueCount + reminders.dueSoonCount > 0;

    final vehicleIcon = activeVehicle != null
        ? VehicleDisplay.iconFor(activeVehicle!)
        : Icons.directions_car_filled_rounded;
    final vehicleName = activeVehicle?.name ?? 'My Garage';
    final subtitle = activeVehicle?.fuelType ?? 'Add Vehicle';

    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, _outerVPad, 14, _outerVPad),
          child: CleanGlassPanel(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            padding: const EdgeInsets.fromLTRB(
              10,
              DashboardBarMetrics.glassVerticalPad,
              4,
              DashboardBarMetrics.glassVerticalPad,
            ),
            child: SizedBox(
              height: DashboardBarMetrics.innerContentHeight,
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onVehicleTap,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary
                                          .withValues(alpha: 0.22),
                                      AppColors.primary
                                          .withValues(alpha: 0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Icon(
                                  vehicleIcon,
                                  color: AppColors.primary,
                                  size: 17,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      vehicleName,
                                      style: AppTextStyles.label.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        height: 1.15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      subtitle,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textTertiary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        height: 1.15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textTertiary,
                                size: 18,
                              ),
                              const SizedBox(width: 2),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _GhostIconButton(
                    tooltip: 'Gas Stations & Prices',
                    icon: Icons.local_gas_station_rounded,
                    iconColor: AppColors.primary,
                    onTap: onFuelStationsTap,
                  ),
                  _GhostIconButton(
                    tooltip: 'notificationsTitle'.tr(),
                    icon: Icons.notifications_outlined,
                    onTap: () => NotificationsScreen.open(context),
                    showDot: hasAlerts,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostIconButton extends StatelessWidget {
  const _GhostIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.iconColor,
    this.showDot = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? iconColor;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor ?? AppColors.textSecondary,
              ),
              if (showDot)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.card,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
