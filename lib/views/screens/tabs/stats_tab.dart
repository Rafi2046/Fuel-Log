import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/service_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../reports/reports_screen.dart';
import '../stats/advanced_metric_explorer_screen.dart';
import '../../widgets/analytics_carousel.dart';
import '../../widgets/monthly_cost_breakdown.dart';

/// Stats home: light summary carousel + costs. Deep charts live in Metric Explorer.
class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(vehicleLogsProvider);
    final serviceLogsAsync = ref.watch(serviceLogsProvider);
    final vehicleAsync = ref.watch(activeVehicleProvider);
    final isEV = vehicleAsync.valueOrNull?.isElectric ?? false;
    final mileageUnit = isEV ? 'km/kWh' : 'km/L';
    final serviceLogs = serviceLogsAsync.valueOrNull ?? [];

    return logsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text(
          'errorPrefix'.tr(namedArgs: {'error': '$e'}),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
      data: (logs) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        children: [
          AnalyticsCarousel(
            logs: logs,
            mileageUnit: mileageUnit,
            isElectric: isEV,
          ),
          const SizedBox(height: AppSpacing.lg),
          _StatsActionTile(
            icon: Icons.analytics_rounded,
            label: 'exploreMetrics'.tr(),
            onTap: () => AdvancedMetricExplorerScreen.open(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _StatsActionTile(
            icon: Icons.description_rounded,
            label: 'report'.tr(),
            onTap: () => ReportsScreen.open(context),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'monthlySpendingBreakdown'.tr(),
            style: AppTextStyles.label.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          MonthlyCostBreakdown(
            fuelLogs: logs,
            serviceLogs: serviceLogs,
          ),
        ],
      ),
    );
  }
}

class _StatsActionTile extends StatelessWidget {
  const _StatsActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF161622),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: const Color(0xFF262638)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
