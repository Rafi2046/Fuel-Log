import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/app_formatters.dart';

/// Line chart displaying Cost Per Kilometer (৳/km) efficiency over time.
class CostPerKmChart extends StatelessWidget {
  const CostPerKmChart({
    super.key,
    required this.fuelLogs,
    this.serviceLogs = const [],
    this.chartHeight = 220,
  });

  final List<FuelLog> fuelLogs;
  final List<ServiceLog> serviceLogs;
  final double chartHeight;

  List<_CostPerKmData> get _monthlyData {
    if (fuelLogs.isEmpty) return [];

    // Group logs by year-month
    final Map<String, double> fuelMap = {};
    final Map<String, double> serviceMap = {};
    final Map<String, double> minOdoMap = {};
    final Map<String, double> maxOdoMap = {};
    final Map<String, DateTime> dateOrder = {};

    final sortedFuel = List<FuelLog>.from(fuelLogs)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final log in sortedFuel) {
      final key =
          '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}';
      fuelMap[key] = (fuelMap[key] ?? 0) + log.cost;
      dateOrder[key] = DateTime(log.date.year, log.date.month);

      if (!minOdoMap.containsKey(key) || log.odometer < minOdoMap[key]!) {
        minOdoMap[key] = log.odometer;
      }
      if (!maxOdoMap.containsKey(key) || log.odometer > maxOdoMap[key]!) {
        maxOdoMap[key] = log.odometer;
      }
    }

    for (final log in serviceLogs) {
      final key =
          '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}';
      serviceMap[key] = (serviceMap[key] ?? 0) + log.cost;
    }

    final keys = dateOrder.keys.toList()
      ..sort((a, b) => dateOrder[a]!.compareTo(dateOrder[b]!));

    final List<_CostPerKmData> result = [];

    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      final monthDate = dateOrder[key]!;
      final totalCost = (fuelMap[key] ?? 0.0) + (serviceMap[key] ?? 0.0);

      double distance = 0.0;
      if (i > 0) {
        final prevKey = keys[i - 1];
        distance = (maxOdoMap[key] ?? 0) - (maxOdoMap[prevKey] ?? 0);
      } else {
        distance = (maxOdoMap[key] ?? 0) - (minOdoMap[key] ?? 0);
      }

      if (distance <= 0) distance = 100.0; // Graceful fallback estimation

      final costPerKm = totalCost / distance;
      result.add(_CostPerKmData(
        label: '${_monthName(monthDate.month)} ${monthDate.year.toString().substring(2)}',
        costPerKm: costPerKm,
        totalCost: totalCost,
        distanceKm: distance,
      ));
    }

    return result.take(12).toList();
  }

  static String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[(month - 1).clamp(0, 11)];
  }

  @override
  Widget build(BuildContext context) {
    final data = _monthlyData;
    if (data.isEmpty) {
      return SizedBox(
        height: chartHeight,
        child: const Center(
          child: Text(
            'Need more logs to calculate cost per km',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    double maxY = 0;
    for (int i = 0; i < data.length; i++) {
      final val = data[i].costPerKm;
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxY) maxY = val;
    }

    final chartMaxY = math.max(15.0, (maxY * 1.25).ceilToDouble());
    final avgCostPerKm = spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length;

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
                    'Cost Per Kilometer (৳/km)',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Average: ${AppCurrency.format(avgCostPerKm)} / km',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF38BDF8),
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
                      reservedSize: 36,
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
                        if (idx >= 0 && idx < data.length) {
                          return Text(
                            data[idx].label,
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
                        if (idx < 0 || idx >= data.length) return null;
                        final d = data[idx];
                        return LineTooltipItem(
                          '${d.label}\n৳${spot.y.toStringAsFixed(2)} / km\n(Total: ৳${d.totalCost.toStringAsFixed(0)})',
                          const TextStyle(
                            color: Color(0xFF38BDF8),
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
                    color: const Color(0xFF38BDF8),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF38BDF8),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
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

class _CostPerKmData {
  const _CostPerKmData({
    required this.label,
    required this.costPerKm,
    required this.totalCost,
    required this.distanceKm,
  });

  final String label;
  final double costPerKm;
  final double totalCost;
  final double distanceKm;
}
