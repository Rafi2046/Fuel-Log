import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/clean_glass_panel.dart';
import '../mileage/mileage_log_screen.dart';
import '../refueling_form_screen.dart';
import '../reminders/reminders_screen.dart';
import '../reports/reports_screen.dart';
import '../services/widgets/add_cost_service_sheet.dart';

/// Contextual quick actions from the center FAB.
Future<void> showDashboardQuickActionsSheet(
  BuildContext context, {
  VoidCallback? onRecordTrip,
  VoidCallback? onExploreStations,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        bottomInset + AppSpacing.sm,
      ),
      child: CleanGlassPanel(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
          bottom: Radius.circular(AppSpacing.radiusXl),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'quickActions'.tr(),
                    style: AppTextStyles.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ActionTile(
                    icon: LucideIcons.fuel,
                    accent: true,
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
                  _sheetDivider(),
                  _ActionTile(
                    icon: LucideIcons.mapPin,
                    title: 'Gas Stations & Prices',
                    subtitle:
                        'Live Bangladesh fuel rates, nearby pumps & map',
                    onTap: () {
                      Navigator.of(context).pop();
                      onExploreStations?.call();
                    },
                  ),
                  _sheetDivider(),
                  _ActionTile(
                    icon: LucideIcons.gauge,
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
                  _sheetDivider(),
                  _ActionTile(
                    icon: LucideIcons.route,
                    title: 'actionRecordTrip'.tr(),
                    subtitle: 'actionRecordTripSubtitle'.tr(),
                    onTap: () {
                      Navigator.of(context).pop();
                      onRecordTrip?.call();
                    },
                  ),
                  _sheetDivider(),
                  _ActionTile(
                    icon: LucideIcons.wrench,
                    title: 'actionAddCost'.tr(),
                    subtitle: 'actionAddCostSubtitle'.tr(),
                    onTap: () {
                      Navigator.of(context).pop();
                      final vehicle =
                          ref.read(activeVehicleProvider).valueOrNull;
                      if (vehicle == null) return;
                      final logs =
                          ref.read(vehicleLogsProvider).valueOrNull ?? [];
                      final currentOdo = logs.isNotEmpty
                          ? logs.first.odometer
                          : vehicle.startOdo;
                      AddCostServiceSheet.show(
                        context,
                        vehicleId: vehicle.id,
                        currentOdometer: currentOdo,
                      );
                    },
                  ),
                  _sheetDivider(),
                  _ActionTile(
                    icon: LucideIcons.bell,
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
                  _sheetDivider(),
                  _ActionTile(
                    icon: LucideIcons.fileText,
                    title: 'Create Report',
                    subtitle: 'Generate CSV & text history report',
                    onTap: () {
                      Navigator.of(context).pop();
                      ReportsScreen.open(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetDivider() => Divider(
        height: 1,
        thickness: 1,
        color: AppColors.border.withValues(alpha: 0.5),
        indent: 52,
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        accent ? AppColors.primary : AppColors.textSecondary;
    final chipFill = accent
        ? AppColors.primary.withValues(alpha: 0.12)
        : AppColors.border.withValues(alpha: 0.35);
    final chipBorder = accent
        ? AppColors.primary.withValues(alpha: 0.22)
        : AppColors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: chipFill,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: chipBorder),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
