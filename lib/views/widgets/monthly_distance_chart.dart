import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/mileage_calculator.dart';
import '../screens/stats/widgets/metric_chart_empty.dart';

/// Bar chart of kilometres driven per calendar month.
class MonthlyDistanceChart extends StatelessWidget {
  const MonthlyDistanceChart({
    super.key,
    required this.logs,
    this.scrollable = false,
  });

  final List<FuelLog> logs;
  final bool scrollable;

  static final DateFormat _monthLabel = DateFormat('MMM');

  @override
  Widget build(BuildContext context) {
    final series = buildMonthlyDistanceSeries(
      logs,
      maxMonths: scrollable ? null : 6,
    );
    if (series.isEmpty) {
      return const ChartSparklineEmpty();
    }

    final maxY =
        series.map((p) => p.km).reduce((a, b) => a > b ? a : b) * 1.2;
    final safeMaxY = maxY <= 0 ? 1.0 : maxY;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: BarChart(
        BarChartData(
          maxY: safeMaxY,
          minY: 0,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: safeMaxY / 2,
                getTitlesWidget: (value, _) {
                  if (value <= 0 || value >= safeMaxY) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    value.toStringAsFixed(0),
                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= series.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _monthLabel.format(series[i].period),
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) => AppColors.card,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final i = group.x.clamp(0, series.length - 1);
                final point = series[i];
                return BarTooltipItem(
                  '${point.km.toStringAsFixed(0)} ${'km'.tr()}\n'
                  '${_monthLabel.format(point.period)} ${point.year}',
                  AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < series.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: series[i].km,
                    width: series.length > 8 ? 10 : 14,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    color: AppColors.primary,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: safeMaxY,
                      color: AppColors.border.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
          ],
          alignment: BarChartAlignment.spaceAround,
        ),
        duration: Duration.zero,
      ),
    );
  }
}
