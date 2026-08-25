import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/app_formatters.dart';

/// Line chart displaying individual fill-up refueling transaction costs over time.
class FillUpCostChart extends StatelessWidget {
  const FillUpCostChart({
    super.key,
    required this.logs,
    this.chartHeight = 220,
  });

  final List<FuelLog> logs;
  final double chartHeight;

  static final DateFormat _dayMonth = DateFormat('d MMM');

  @override
  Widget build(BuildContext context) {
    final sorted = List<FuelLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sorted.isEmpty) {
      return SizedBox(
        height: chartHeight,
        child: const Center(
          child: Text(
            'No fill-up logs recorded yet',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    double maxY = 0;
    for (int i = 0; i < sorted.length; i++) {
      final cost = sorted[i].cost;
      spots.add(FlSpot(i.toDouble(), cost));
      if (cost > maxY) maxY = cost;
    }

    final chartMaxY = math.max(1000.0, (maxY * 1.25).ceilToDouble());
    final avgCost = spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fill-up Transaction Costs',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Average Fill-up: ${AppCurrency.format(avgCost)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: chartHeight - 50,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: chartMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (val, _) => Text(
                        '৳${val.toInt()}',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < sorted.length) {
                          return Text(
                            _dayMonth.format(sorted[idx].date),
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E1E2E),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        if (idx < 0 || idx >= sorted.length) return null;
                        final log = sorted[idx];
                        return LineTooltipItem(
                          '${_dayMonth.format(log.date)}\n${AppCurrency.format(spot.y)}\n(${log.amount.toStringAsFixed(1)} L @ ${log.odometer.toStringAsFixed(0)} km)',
                          const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
