import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/database/app_database.dart';
import '../../../widgets/advanced_efficiency_chart.dart';
import '../../../widgets/cost_per_km_chart.dart';
import '../../../widgets/fill_up_cost_chart.dart';
import '../../../widgets/fuel_price_chart.dart';
import '../../../widgets/monthly_cost_breakdown.dart';
import '../../../widgets/monthly_distance_chart.dart';
import '../../../widgets/odometer_growth_chart.dart';
import 'metric_chart_empty.dart';

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

  static const _surface = Color(0xFF16161E);
  static const _border = Color(0xFF2A2A36);

  bool get _hasData {
    if (categoryIndex == 1) {
      return fuelLogs.isNotEmpty || serviceLogs.isNotEmpty;
    }
    return fuelLogs.length >= 2;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: _hasData ? const BoxConstraints(minHeight: 280) : null,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _subMetricRow(),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: _hasData
                ? _activeChart()
                : const MetricExplorerEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _subMetricRow() {
    final List<String> options;
    if (categoryIndex == 0) {
      options = ['Consumption', 'Price', 'Fill-ups'];
    } else if (categoryIndex == 1) {
      options = ['Monthly spend', 'Cost / km'];
    } else {
      options = ['Monthly km', 'Odometer'];
    }
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
    final key = ValueKey('chart_${categoryIndex}_$subMetricIndex');
    if (categoryIndex == 0) {
      if (subMetricIndex == 0) {
        return AdvancedEfficiencyChart(
          key: key, logs: fuelLogs, unit: mileageUnit,
        );
      } else if (subMetricIndex == 1) {
        return FuelPriceChart(
          key: key,
          logs: fuelLogs,
          priceUnit: isEV ? '৳/kWh' : '৳/L',
        );
      }
      return FillUpCostChart(key: key, logs: fuelLogs, chartHeight: 240);
    }
    if (categoryIndex == 1) {
      if (subMetricIndex == 0) {
        return MonthlyCostBreakdown(
          key: key, fuelLogs: fuelLogs, serviceLogs: serviceLogs,
        );
      }
      return CostPerKmChart(
        key: key,
        fuelLogs: fuelLogs,
        serviceLogs: serviceLogs,
        chartHeight: 240,
      );
    }
    if (subMetricIndex == 0) {
      return MonthlyDistanceChart(key: key, logs: fuelLogs);
    }
    return OdometerGrowthChart(key: key, logs: fuelLogs, chartHeight: 240);
  }
}

class MetricChartTab extends StatelessWidget {
  const MetricChartTab({
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected ? AppColors.primary : AppColors.textTertiary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

