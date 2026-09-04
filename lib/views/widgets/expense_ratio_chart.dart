import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/app_formatters.dart';
import '../screens/stats/widgets/metric_chart_empty.dart';

/// Donut breakdown: fuel vs service spend for the current month.
class ExpenseRatioChart extends StatelessWidget {
  const ExpenseRatioChart({
    super.key,
    required this.logs,
    this.serviceLogs = const [],
  });

  final List<FuelLog> logs;
  final List<ServiceLog> serviceLogs;

  static double _currentMonthFuelSpend(List<FuelLog> logs) {
    final now = DateTime.now();
    return logs
        .where((l) => l.date.year == now.year && l.date.month == now.month)
        .fold<double>(0, (sum, l) => sum + l.cost);
  }

  static double _currentMonthServiceSpend(List<ServiceLog> logs) {
    final now = DateTime.now();
    return logs
        .where((l) => l.date.year == now.year && l.date.month == now.month)
        .fold<double>(0, (sum, l) => sum + l.cost);
  }

  @override
  Widget build(BuildContext context) {
    final fuel = _currentMonthFuelSpend(logs);
    final service = _currentMonthServiceSpend(serviceLogs);
    final total = fuel + service;

    if (total <= 0) {
      return const ChartSparklineEmpty();
    }

    // Use share percentages (not raw ৳) so huge spends still paint in fl_chart.
    final fuelShare = fuel / total;
    final serviceShare = service / total;
    final sections = <PieChartSectionData>[
      if (fuelShare > 0)
        PieChartSectionData(
          value: fuelShare,
          color: AppColors.primary,
          radius: 22,
          showTitle: false,
        ),
      if (serviceShare > 0)
        PieChartSectionData(
          value: serviceShare,
          color: AppColors.success,
          radius: 22,
          showTitle: false,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sectionsSpace: sections.length > 1 ? 2 : 0,
                startDegreeOffset: -90,
                pieTouchData: PieTouchData(enabled: true),
                sections: sections,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'expenseRatio'.tr(),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _LegendRow(
                  color: AppColors.primary,
                  label: 'fuelCosts'.tr(),
                  value: AppCurrency.format(fuel),
                ),
                const SizedBox(height: AppSpacing.xs),
                _LegendRow(
                  color: AppColors.success,
                  label: 'serviceCosts'.tr(),
                  value: AppCurrency.format(service),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(fontSize: 11),
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
