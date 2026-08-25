import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../mileage/mileage_log_screen.dart';
import '../refueling_form_screen.dart';
import '../reminders/reminders_screen.dart';
import '../services/widgets/add_cost_service_sheet.dart';

/// Contextual quick actions from the center FAB (no grid menu).
Future<void> showDashboardQuickActionsSheet(
  BuildContext context, {
  VoidCallback? onRecordTrip,
  VoidCallback? onExploreStations,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    elevation: 8,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
    ),
    builder: (context) => _DashboardQuickActionsSheet(
      onRecordTrip: onRecordTrip,
      onExploreStations: onExploreStations,
    ),
  );
}

class _DashboardQuickActionsSheet extends ConsumerWidget {
  const _DashboardQuickActionsSheet({
    this.onRecordTrip,
    this.onExploreStations,
  });

  final VoidCallback? onRecordTrip;
  final VoidCallback? onExploreStations;

  static const Color _tripBlue = Color(0xFF4A9EFF);
  static const Color _costGreen = Color(0xFF2ECC71);
  static const Color _reminderYellow = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'quickActions'.tr(),
              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ActionTile(
              icon: Icons.local_gas_station_rounded,
              color: AppColors.primary,
              title: 'actionRefueling'.tr(),
              subtitle: 'actionRefuelingSubtitle'.tr(),
              onTap: () {
                final nav = Navigator.of(context);
                nav.pop();
                Future.microtask(() {
                  nav.push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RefuelingFormScreen(),
                    ),
                  );
                });
              },
            ),
            const Divider(color: AppColors.divider, height: 1),
            _ActionTile(
              icon: Icons.local_gas_station_rounded,
              color: AppColors.primary,
              title: 'Gas Stations & Prices',
              subtitle: 'Live Bangladesh fuel rates, nearby pumps & map',
              onTap: () {
                Navigator.of(context).pop();
                onExploreStations?.call();
              },
            ),
            const Divider(color: AppColors.divider, height: 1),
            _ActionTile(
              icon: Icons.speed_rounded,
              color: AppColors.secondary,
              title: 'Mileage Log',
              subtitle: 'View average consumption & distance stats',
              onTap: () {
                final nav = Navigator.of(context);
                nav.pop();
                Future.microtask(() {
                  nav.push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MileageLogScreen(),
                    ),
                  );
                });
              },
            ),
            const Divider(color: AppColors.divider, height: 1),
            _ActionTile(
              icon: Icons.route_rounded,
              color: _tripBlue,
              title: 'actionRecordTrip'.tr(),
              subtitle: 'actionRecordTripSubtitle'.tr(),
              onTap: () {
                Navigator.of(context).pop();
                onRecordTrip?.call();
              },
            ),
            const Divider(color: AppColors.divider, height: 1),
            _ActionTile(
              icon: Icons.build_circle_outlined,
              color: _costGreen,
              title: 'actionAddCost'.tr(),
              subtitle: 'actionAddCostSubtitle'.tr(),
              onTap: () {
                Navigator.of(context).pop();
                final vehicle = ref.read(activeVehicleProvider).valueOrNull;
                if (vehicle == null) return;
                final logs = ref.read(vehicleLogsProvider).valueOrNull ?? [];
                final currentOdo =
                    logs.isNotEmpty ? logs.first.odometer : vehicle.startOdo;
                AddCostServiceSheet.show(
                  context,
                  vehicleId: vehicle.id,
                  currentOdometer: currentOdo,
                );
              },
            ),
            const Divider(color: AppColors.divider, height: 1),
            _ActionTile(
              icon: Icons.notifications_active_outlined,
              color: _reminderYellow,
              title: 'actionAddReminder'.tr(),
              subtitle: 'actionAddReminderSubtitle'.tr(),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RemindersScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    ),
  );
}
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: AppTextStyles.body),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
    );
  }
}
