import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/mileage_calculator.dart';

/// Interactive efficiency trend with average baseline (fl_chart LineChart).
class AdvancedEfficiencyChart extends StatelessWidget {
  const AdvancedEfficiencyChart({
    super.key,
    required this.logs,
    required this.unit,
  });

  final List<FuelLog> logs;
  final String unit;

  static final DateFormat _dayMonth = DateFormat('d MMM');

  @override
  Widget build(BuildContext context) {
    final series = buildEfficiencySeries(logs);
    if (series.length < 2) {
      return const _ChartEmpty(messageKey: 'chartNeedMoreLogs');
    }

    final spots = <FlSpot>[
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].efficiency),
    ];
    final avg =
        series.map((p) => p.efficiency).reduce((a, b) => a + b) / series.length;
    final maxY = series
            .map((p) => p.efficiency)
            .reduce((a, b) => a > b ? a : b) *
        1.25;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (series.length - 1).toDouble(),
          minY: 0,
          maxY: maxY <= 0 ? 1 : maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: avg,
                color: AppColors.textTertiary.withValues(alpha: 0.7),
                strokeWidth: 1,
                dashArray: const [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 4, bottom: 2),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 9,
                  ),
                  labelResolver: (_) => 'avg'.tr(),
                ),
              ),
            ],
          ),
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
                reservedSize: 32,
                interval: maxY / 2,
                getTitlesWidget: (value, _) {
                  if (value <= 0 || value >= maxY) {
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
                interval: 1,
                getTitlesWidget: (value, _) {
                  final i = value.round();
                  if (i < 0 || i >= series.length) {
                    return const SizedBox.shrink();
                  }
                  if (series.length > 4 &&
                      i != 0 &&
                      i != series.length - 1 &&
                      i.isOdd) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _dayMonth.format(series[i].date),
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.card,
              getTooltipItems: (touched) => touched.map((s) {
                final i = s.x.round().clamp(0, series.length - 1);
                final point = series[i];
                return LineTooltipItem(
                  '${point.efficiency.toStringAsFixed(1)} $unit\n'
                  '${_dayMonth.format(point.date)}',
                  AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 3.2,
                    color: AppColors.primary,
                    strokeWidth: 1.5,
                    strokeColor: AppColors.cardElevated,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.32),
                    AppColors.primary.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.messageKey});

  final String messageKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          messageKey.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
      ),
    );
  }
}
