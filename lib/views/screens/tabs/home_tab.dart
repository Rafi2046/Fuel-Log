import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/utils/mileage_calculator.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../../viewmodels/weather_viewmodel.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_shimmer.dart';
import '../../widgets/efficiency_gauge.dart';
import '../../widgets/home_services_card.dart';
import '../../widgets/list_lead_icon.dart';
import '../../widgets/summary_stat_card.dart';
import '../../widgets/weather_drive_card.dart';
import '../mileage/widgets/fuel_log_detail_sheet.dart';
import '../refueling_form_screen.dart';
import 'dashboard_bottom_bar.dart';
import 'logs_tab.dart';

/// Home tab — compact overview (gauge, month cards, recent log).
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(vehicleLogsProvider);
    final vehicleAsync = ref.watch(activeVehicleProvider);
    final isEV = vehicleAsync.valueOrNull?.isElectric ?? false;
    final unit = isEV ? 'kWh' : 'L';
    final mileageUnit = isEV ? 'km/kWh' : 'km/L';

    return logsAsync.when(
      loading: () => const HomeTabSkeleton(),
      error: (e, _) => Center(
        child: Text('errorPrefix'.tr(namedArgs: {'error': '$e'})),
      ),
      data: (logs) => AppRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(vehicleLogsProvider);
          ref.invalidate(weatherAdviceProvider);
          ref.invalidate(vehiclesProvider);
        },
        child: _HomeContent(
          logs: logs,
          isEV: isEV,
          unit: unit,
          mileageUnit: mileageUnit,
          vehicleName: vehicleAsync.valueOrNull?.name,
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.logs,
    required this.isEV,
    required this.unit,
    required this.mileageUnit,
    required this.vehicleName,
  });

  final List<FuelLog> logs;
  final bool isEV;
  final String unit;
  final String mileageUnit;
  final String? vehicleName;

  double get _monthSpend {
    final now = DateTime.now();
    return logs
        .where((l) => l.date.year == now.year && l.date.month == now.month)
        .fold<double>(0, (sum, l) => sum + l.cost);
  }

  @override
  Widget build(BuildContext context) {
    final recent = logs.isEmpty ? null : logs.first;
    final avgMileage = calculateAverageMileage(logs);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        DashboardBottomBar.contentBottomInset(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: EfficiencyGauge(
              value: avgMileage,
              unit: mileageUnit,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const WeatherDriveCard(),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: SummaryStatCard(
                  label: 'monthCost'.tr(),
                  value: AppCurrency.format(_monthSpend),
                  icon: Icons.receipt_long_rounded,
                  accent: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SummaryStatCard(
                  label: isEV ? 'lastCharge'.tr() : 'lastFill'.tr(),
                  value: recent == null
                      ? '—'
                      : '${recent.amount.toStringAsFixed(0)} $unit',
                  icon: Icons.history_rounded,
                  accent: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const HomeServicesCard(),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  isEV ? 'recentCharge'.tr() : 'recentRefueling'.tr(),
                  style: AppTextStyles.label.copyWith(fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () => LogsTab.open(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'viewAll'.tr(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (recent == null)
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.listCardPaddingH,
                vertical: AppSpacing.listCardPaddingV,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RefuelingFormScreen(),
                  ),
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ListLeadIcon(
                    icon: isEV
                        ? Icons.battery_charging_full_rounded
                        : Icons.local_gas_station_rounded,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEV
                              ? 'addFirstChargeTitle'.tr()
                              : 'addFirstRefuelTitle'.tr(),
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEV
                              ? 'addFirstChargeSubtitle'.tr()
                              : 'addFirstRefuelSubtitle'.tr(),
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.listCardPaddingH,
                vertical: AppSpacing.listCardPaddingV,
              ),
              onTap: () => FuelLogDetailSheet.show(
                context,
                log: recent,
                unit: unit,
                isEV: isEV,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ListLeadIcon(
                    icon: isEV
                        ? Icons.battery_charging_full_rounded
                        : Icons.local_gas_station_rounded,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vehicleName ?? 'Vehicle'} • '
                          '${recent.amount.toStringAsFixed(1)} $unit',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${AppDateFormats.formatLogDate(recent.date)} • '
                          '${recent.odometer.toStringAsFixed(0)} km',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    AppCurrency.format(recent.cost),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


