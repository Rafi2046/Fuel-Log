import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/analytics_carousel.dart';
import '../../widgets/monthly_cost_breakdown.dart';

/// Dedicated analytics: chart carousel (expandable) + monthly costs.
class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(vehicleLogsProvider);
    final vehicleAsync = ref.watch(activeVehicleProvider);
    final isEV = vehicleAsync.valueOrNull?.isElectric ?? false;
    final mileageUnit = isEV ? 'km/kWh' : 'km/L';

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('errorPrefix'.tr(namedArgs: {'error': '$e'})),
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
            chartHeight: 240,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'costs'.tr(),
            style: AppTextStyles.label.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          MonthlyCostBreakdown(logs: logs),
        ],
      ),
    );
  }
}
