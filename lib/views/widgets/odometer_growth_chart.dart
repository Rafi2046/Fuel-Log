import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/database/app_database.dart';
import 'metric_chart_layout.dart';
import '../screens/stats/widgets/metric_chart_empty.dart';
import 'metric_single_point_hero.dart';

/// Odometer growth trend for Metric Explorer.
class OdometerGrowthChart extends StatelessWidget {
  const OdometerGrowthChart({
    super.key,
    required this.logs,
    this.chartHeight = 220,
  });

  final List<FuelLog> logs;
  final double chartHeight;

  static final DateFormat _dayMonth = DateFormat('d MMM');
  static const Color _accent = Color(0xFFA855F7);

  static String _axisLabel(List<FuelLog> logs, int index) {
    final date = logs[index].date;
    final sameDay = logs
        .where(
          (l) =>
              l.date.year == date.year &&
              l.date.month == date.month &&
              l.date.day == date.day,
        )
        .length;
    if (sameDay > 1) {
      var n = 0;
      for (var i = 0; i <= index; i++) {
        final d = logs[i].date;
        if (d.year == date.year &&
            d.month == date.month &&
            d.day == date.day) {
          n++;
        }
      }
      return '${_dayMonth.format(date)} · $n';
    }
    return _dayMonth.format(date);
  }

  static String _formatOdo(double value) {
    if (value >= 10000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<FuelLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sorted.isEmpty) {
      return const _OdometerChartEmpty();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = _finiteHeight(constraints.maxHeight);
        final chart = sorted.length == 1
            ? _SingleOdometerChart(log: sorted.first)
            : _OdometerTrendChart(logs: sorted);

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

class _SingleOdometerChart extends StatelessWidget {
  const _SingleOdometerChart({required this.log});

  final FuelLog log;

  @override
  Widget build(BuildContext context) {
    final y = log.odometer;
    final safeMaxY = y <= 0 ? 1000.0 : y * 1.05;
    final safeMinY = math.max(0.0, y * 0.92);
    final spots = [
      FlSpot(0, safeMinY + (y - safeMinY) * 0.15),
      FlSpot(0.22, safeMinY + (y - safeMinY) * 0.55),
      FlSpot(0.5, y),
      FlSpot(0.78, safeMinY + (y - safeMinY) * 0.55),
      FlSpot(1, safeMinY + (y - safeMinY) * 0.15),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MetricSinglePointHero(
          value: '${y.toStringAsFixed(0)} km',
          unit: OdometerGrowthChart._dayMonth.format(log.date),
          accentStart: OdometerGrowthChart._accent.withValues(alpha: 0.8),
          accentEnd: OdometerGrowthChart._accent,
        ),
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 1,
              minY: safeMinY,
              maxY: safeMaxY,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (safeMaxY - safeMinY) / 2,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.white.withValues(alpha: 0.04),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.cardElevated,
                  getTooltipItems: (_) => [
                    LineTooltipItem(
                      '${log.odometer.toStringAsFixed(0)} km\n'
                      '${OdometerGrowthChart._dayMonth.format(log.date)}',
                      AppTextStyles.caption.copyWith(
                        color: OdometerGrowthChart._accent,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  curveSmoothness: 0.28,
                  color: OdometerGrowthChart._accent.withValues(alpha: 0.9),
                  barWidth: 2.2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, _) => (spot.x - 0.5).abs() < 0.01,
                    getDotPainter: (spot, percent, bar, index) {
                      return FlDotCirclePainter(
                        radius: 4.5,
                        color: OdometerGrowthChart._accent,
                        strokeWidth: 2,
                        strokeColor: AppColors.cardElevated,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.55, 1.0],
                      colors: [
                        OdometerGrowthChart._accent.withValues(alpha: 0.18),
                        OdometerGrowthChart._accent.withValues(alpha: 0.06),
                        OdometerGrowthChart._accent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
          ),
        ),
      ],
    );
  }
}

class _OdometerTrendChart extends StatelessWidget {
  const _OdometerTrendChart({required this.logs});

  final List<FuelLog> logs;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < logs.length; i++)
        FlSpot(i.toDouble(), logs[i].odometer),
    ];
    final values = logs.map((l) => l.odometer).toList();
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final spread = math.max(maxVal - minVal, 50.0);
    final safeMinY = math.max(0.0, minVal - spread * 0.25);
    final safeMaxY = maxVal + spread * 0.2;
    final delta = maxVal - minVal;

    final summary = 'metricChartOdometerSummary'
        .tr()
        .replaceAll('{odo}', maxVal.toStringAsFixed(0))
        .replaceAll('{delta}', delta.toStringAsFixed(0));

    final labelStep = logs.length > 12
        ? (logs.length / 8).ceil()
        : logs.length > 6
            ? 2
            : 1;

    final edge = MetricChartLayout.edgePad(logs.length);

    return Stack(
      children: [
        LineChart(
          LineChartData(
            minX: -edge,
            maxX: (logs.length - 1).toDouble() + edge,
            minY: safeMinY,
            maxY: safeMaxY,
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (safeMaxY - safeMinY) / 3,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.white.withValues(alpha: 0.05),
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
                  reservedSize: 38,
                  interval: (safeMaxY - safeMinY) / 2,
                  getTitlesWidget: (value, _) {
                    if (value <= safeMinY || value >= safeMaxY) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      OdometerGrowthChart._formatOdo(value),
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
                    if (i < 0 || i >= logs.length) {
                      return const SizedBox.shrink();
                    }
                    final show =
                        i == 0 || i == logs.length - 1 || i % labelStep == 0;
                    if (!show) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: MetricChartLayout.axisDateLabel(
                        OdometerGrowthChart._axisLabel(logs, i),
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipColor: (_) => AppColors.cardElevated,
                getTooltipItems: (touched) => touched.map((s) {
                  final i = s.x.round().clamp(0, logs.length - 1);
                  final log = logs[i];
                  return LineTooltipItem(
                    '${log.odometer.toStringAsFixed(0)} km\n'
                    '${OdometerGrowthChart._axisLabel(logs, i)}',
                    AppTextStyles.caption.copyWith(
                      color: OdometerGrowthChart._accent,
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
                preventCurveOverShooting: true,
                curveSmoothness: 0.22,
                color: OdometerGrowthChart._accent.withValues(alpha: 0.35),
                barWidth: 5,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
              LineChartBarData(
                spots: spots,
                isCurved: true,
                preventCurveOverShooting: true,
                curveSmoothness: 0.22,
                color: OdometerGrowthChart._accent,
                barWidth: 2.4,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 3,
                      color: OdometerGrowthChart._accent,
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
                    stops: const [0.0, 0.7, 1.0],
                    colors: [
                      OdometerGrowthChart._accent.withValues(alpha: 0.18),
                      OdometerGrowthChart._accent.withValues(alpha: 0.06),
                      OdometerGrowthChart._accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        ),
        Positioned(
          top: 0,
          left: 4,
          right: 4,
          child: Text(
            summary,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption.copyWith(
              color: OdometerGrowthChart._accent.withValues(alpha: 0.85),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _OdometerChartEmpty extends StatelessWidget {
  const _OdometerChartEmpty();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 72,
          width: double.infinity,
          child: CustomPaint(
            painter: MetricEmptySparklinePainter(
              lineColor: OdometerGrowthChart._accent.withValues(alpha: 0.5),
              fillColor: OdometerGrowthChart._accent.withValues(alpha: 0.12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'chartNeedMoreLogs'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
