import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/app_formatters.dart';
import 'metric_chart_layout.dart';
import 'metric_single_point_hero.dart';

/// Cost per km trend for Metric Explorer.
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

    final fuelMap = <String, double>{};
    final serviceMap = <String, double>{};
    final minOdoMap = <String, double>{};
    final maxOdoMap = <String, double>{};
    final dateOrder = <String, DateTime>{};

    final sortedFuel = List<FuelLog>.from(fuelLogs)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final log in sortedFuel) {
      final key =
          '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}';
      fuelMap[key] = (fuelMap[key] ?? 0) + log.cost;
      dateOrder[key] = DateTime(log.date.year, log.date.month);

      minOdoMap[key] = math.min(minOdoMap[key] ?? log.odometer, log.odometer);
      maxOdoMap[key] = math.max(maxOdoMap[key] ?? log.odometer, log.odometer);
    }

    for (final log in serviceLogs) {
      final key =
          '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}';
      serviceMap[key] = (serviceMap[key] ?? 0) + log.cost;
    }

    final keys = dateOrder.keys.toList()
      ..sort((a, b) => dateOrder[a]!.compareTo(dateOrder[b]!));

    final result = <_CostPerKmData>[];
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final monthDate = dateOrder[key]!;
      final totalCost = (fuelMap[key] ?? 0.0) + (serviceMap[key] ?? 0.0);

      double distance;
      if (i > 0) {
        final prevKey = keys[i - 1];
        distance = (maxOdoMap[key] ?? 0) - (maxOdoMap[prevKey] ?? 0);
      } else {
        distance = (maxOdoMap[key] ?? 0) - (minOdoMap[key] ?? 0);
      }
      if (distance <= 0) distance = 100.0;

      result.add(
        _CostPerKmData(
          label: DateFormat('MMM yy').format(monthDate),
          costPerKm: totalCost / distance,
          totalCost: totalCost,
          distanceKm: distance,
        ),
      );
    }

    return result.take(12).toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = _monthlyData;
    if (data.isEmpty) {
      return Center(
        child: Text(
          'metricKpiNeedLogs'.tr(),
          style: AppTextStyles.caption,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = _finiteHeight(constraints.maxHeight);
        final chart = data.length == 1
            ? _SingleCostPerKmChart(point: data.first)
            : _CostPerKmTrendChart(data: data);

        return Padding(
          padding: MetricChartLayout.chartPadding,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: chart,
          ),
        );
      },
    );
  }

  double _finiteHeight(double maxHeight) {
    if (maxHeight.isFinite && maxHeight > AppSpacing.md + 80) {
      return maxHeight - AppSpacing.sm;
    }
    return chartHeight;
  }
}

class _SingleCostPerKmChart extends StatelessWidget {
  const _SingleCostPerKmChart({required this.point});

  final _CostPerKmData point;

  @override
  Widget build(BuildContext context) {
    final y = point.costPerKm;
    final safeMaxY = y <= 0 ? 15.0 : y * 1.22;
    final spots = [
      FlSpot(0, y * 0.08),
      FlSpot(0.22, y * 0.42),
      FlSpot(0.5, y),
      FlSpot(0.78, y * 0.42),
      FlSpot(1, y * 0.08),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MetricSinglePointHero(
          value: AppCurrency.format(y),
          unit: 'metricKpiPerKm'.tr(),
        ),
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 1,
              minY: 0,
              maxY: safeMaxY,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: safeMaxY / 2,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.wash,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 0.5,
                    getTitlesWidget: (value, _) {
                      if ((value - 0.5).abs() > 0.01) {
                        return SizedBox.shrink();
                      }
                      return Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          point.label,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: AppColors.primary,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.22),
                        AppColors.primary.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          ),
        ),
      ],
    );
  }
}

class _CostPerKmTrendChart extends StatelessWidget {
  const _CostPerKmTrendChart({required this.data});

  final List<_CostPerKmData> data;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++)
        FlSpot(i.toDouble(), data[i].costPerKm),
    ];
    final maxY = spots.map((s) => s.y).reduce(math.max);
    final minY = spots.map((s) => s.y).reduce(math.min);
    final range = math.max(1.0, maxY - minY);
    final safeMaxY = maxY + range * 0.18;
    final safeMinY = math.max(0.0, minY - range * 0.12);
    final avg = spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length;
    final edgePad = MetricChartLayout.edgePad(data.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8, 0, 8, 4),
          child: Row(
            children: [
              Text(
                'avg'.tr(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${AppCurrency.format(avg)} / km',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LineChart(
            LineChartData(
              minX: -edgePad,
              maxX: data.length - 1 + edgePad,
              minY: safeMinY,
              maxY: safeMaxY,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (safeMaxY - safeMinY) / 2,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.wash,
                  strokeWidth: 1,
                ),
              ),
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
                    reservedSize: 34,
                    interval: (safeMaxY - safeMinY) / 2,
                    getTitlesWidget: (value, _) {
                      if (value < safeMinY + 0.01 || value > safeMaxY - 0.01) {
                        return SizedBox.shrink();
                      }
                      return Text(
                        AppCurrency.format(value),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 9,
                          color: AppColors.textTertiary,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, _) {
                      final i = value.round();
                      if ((value - i).abs() > 0.01 ||
                          i < 0 ||
                          i >= data.length) {
                        return SizedBox.shrink();
                      }
                      return Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: MetricChartLayout.axisDateLabel(
                          data[i].label,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  getTooltipColor: (_) => AppColors.cardElevated,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final idx = spot.x.round();
                      if (idx < 0 || idx >= data.length) return null;
                      final d = data[idx];
                      return LineTooltipItem(
                        '${d.label}\n'
                        '${AppCurrency.format(spot.y)} / km\n'
                        '${'metricKpiSpend'.tr()}: ${AppCurrency.format(d.totalCost)}',
                        AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: avg,
                    color: Colors.white.withValues(alpha: 0.12),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.28,
                  color: AppColors.primary,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  shadow: Shadow(
                    color: AppColors.primary.withValues(alpha: 0.33),
                    blurRadius: 8,
                  ),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                      radius: 3.5,
                      color: AppColors.primary,
                      strokeWidth: 2,
                      strokeColor: AppColors.card,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.18),
                        AppColors.primary.withValues(alpha: 0.01),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          ),
        ),
      ],
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
