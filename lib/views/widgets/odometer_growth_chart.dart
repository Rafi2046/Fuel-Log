import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/database/app_database.dart';

/// Line chart displaying vehicle total odometer growth curve over time.
class OdometerGrowthChart extends StatelessWidget {
  const OdometerGrowthChart({
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
            'No odometer data logged yet',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    double minY = sorted.first.odometer;
    double maxY = sorted.last.odometer;

    for (int i = 0; i < sorted.length; i++) {
      final odo = sorted[i].odometer;
      spots.add(FlSpot(i.toDouble(), odo));
      if (odo < minY) minY = odo;
      if (odo > maxY) maxY = odo;
    }

    final chartMinY = math.max(0.0, minY - 100.0);
    final chartMaxY = maxY + 200.0;
    final totalKmDriven = maxY - minY;

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
                    'Odometer Growth Curve',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Current: ${maxY.toStringAsFixed(0)} km (+${totalKmDriven.toStringAsFixed(0)} km)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA855F7),
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
                minY: chartMinY,
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
                      reservedSize: 45,
                      getTitlesWidget: (val, _) => Text(
                        '${val.toInt()}k',
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
                          '${_dayMonth.format(log.date)}\nOdometer: ${spot.y.toStringAsFixed(0)} km',
                          const TextStyle(
                            color: Color(0xFFA855F7),
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
                    color: const Color(0xFFA855F7),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFFA855F7),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFA855F7).withValues(alpha: 0.15),
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
