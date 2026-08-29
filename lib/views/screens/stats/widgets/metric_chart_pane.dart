import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/database/app_database.dart';
import '../../../widgets/advanced_efficiency_chart.dart';
import '../../../widgets/clean_glass_panel.dart';
import '../../../widgets/cost_per_km_chart.dart';
import '../../../widgets/fill_up_cost_chart.dart';
import '../../../widgets/fuel_price_chart.dart';
import '../../../widgets/monthly_distance_chart.dart';
import '../../../widgets/odometer_growth_chart.dart';
import 'metric_chart_empty.dart';
import 'metric_monthly_spend_panel.dart';

class MetricChartPane extends StatelessWidget {
  const MetricChartPane({
    super.key,
    required this.categoryIndex,
    required this.subMetricIndex,
    required this.onSubMetricChanged,
    required this.fuelLogs,
    required this.serviceLogs,
    required this.mileageUnit,
    required this.isEV,
  });

  final int categoryIndex;
  final int subMetricIndex;
  final ValueChanged<int> onSubMetricChanged;
  final List<FuelLog> fuelLogs;
  final List<ServiceLog> serviceLogs;
  final String mileageUnit;
  final bool isEV;

  bool get _hasData {
    if (categoryIndex == 1) {
      return fuelLogs.isNotEmpty || serviceLogs.isNotEmpty;
    }
    return fuelLogs.length >= 2;
  }

  List<String> get _subMetricLabels {
    if (categoryIndex == 0) {
      return [
        'metricSubConsumption'.tr(),
        'metricSubPrice'.tr(),
        'metricSubFillUps'.tr(),
      ];
    }
    if (categoryIndex == 1) {
      return [
        'metricSubMonthlySpend'.tr(),
        'metricKpiCostPerKm'.tr(),
      ];
    }
    return [
      'metricSubMonthlyKm'.tr(),
      'metricSubOdometer'.tr(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return CleanGlassPanel(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _subMetricRow(),
          const SizedBox(height: 6),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: _hasData
                  ? KeyedSubtree(
                      key: ValueKey('chart_${categoryIndex}_$subMetricIndex'),
                      child: _activeChart(),
                    )
                  : MetricExplorerEmptyState(
                      key: const ValueKey('empty'),
                      fuelLogCount: fuelLogs.length,
                      serviceLogCount: serviceLogs.length,
                      categoryIndex: categoryIndex,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subMetricRow() {
    final options = _subMetricLabels;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            MetricChartTab(
              label: options[i],
              selected: subMetricIndex == i,
              onTap: () => onSubMetricChanged(i),
            ),
          ],
        ],
      ),
    );
  }

  Widget _activeChart() {
    if (categoryIndex == 0) {
      if (subMetricIndex == 0) {
        return AdvancedEfficiencyChart(logs: fuelLogs, unit: mileageUnit);
      } else if (subMetricIndex == 1) {
        return FuelPriceChart(
          logs: fuelLogs,
          priceUnit: isEV ? '৳/kWh' : '৳/L',
        );
      }
      return FillUpCostChart(logs: fuelLogs, chartHeight: 220);
    }
    if (categoryIndex == 1) {
      if (subMetricIndex == 0) {
        return MetricMonthlySpendPanel(
          fuelLogs: fuelLogs,
          serviceLogs: serviceLogs,
        );
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: CostPerKmChart(
              fuelLogs: fuelLogs,
              serviceLogs: serviceLogs,
              chartHeight: constraints.maxHeight.clamp(180, 280),
            ),
          );
        },
      );
    }
    if (subMetricIndex == 0) {
      return MonthlyDistanceChart(logs: fuelLogs);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: OdometerGrowthChart(
            logs: fuelLogs,
            chartHeight: constraints.maxHeight.clamp(180, 280),
          ),
        );
      },
    );
  }
}

class MetricChartTab extends StatelessWidget {
  const MetricChartTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.7)
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected ? AppColors.textPrimary : AppColors.textTertiary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
