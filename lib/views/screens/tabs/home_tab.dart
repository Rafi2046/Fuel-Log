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
import '../../widgets/app_card.dart';
import '../../widgets/efficiency_gauge.dart';
import '../../widgets/summary_stat_card.dart';

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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('errorPrefix'.tr(namedArgs: {'error': '$e'})),
      ),
      data: (logs) => _HomeContent(
        logs: logs,
        isEV: isEV,
        unit: unit,
        mileageUnit: mileageUnit,
        vehicleName: vehicleAsync.valueOrNull?.name,
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.lg,
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
          Text(
            isEV ? 'recentCharge'.tr() : 'recentRefueling'.tr(),
            style: AppTextStyles.label.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (recent == null)
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'noLogsYet'.tr(),
                style: AppTextStyles.bodySecondary.copyWith(fontSize: 14),
              ),
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEV
                          ? Icons.battery_charging_full_rounded
                          : Icons.local_gas_station_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
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
                        const SizedBox(height: 1),
                        Text(
                          '${AppDateFormats.formatLogDate(recent.date)} • '
                          '${recent.odometer.toStringAsFixed(0)} km',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    AppCurrency.format(recent.cost),
                    style: AppTextStyles.title.copyWith(
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
