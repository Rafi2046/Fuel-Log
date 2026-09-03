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
import '../screens/stats/widgets/metric_chart_empty.dart';
import 'metric_single_point_hero.dart';

/// Fill-up cost trend for Metric Explorer.
class FillUpCostChart extends StatelessWidget {
  const FillUpCostChart({
    super.key,
    required this.logs,
    this.chartHeight = 220,
  });

  final List<FuelLog> logs;
  final double chartHeight;

  static final DateFormat _dayMonth = DateFormat('d MMM');

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

  @override
  Widget build(BuildContext context) {
    final sorted = List<FuelLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sorted.isEmpty) {
      return const _FillUpChartEmpty();
    }

    final avgLabel = 'avg'.tr();

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = _finiteHeight(constraints.maxHeight);
        final chart = sorted.length == 1
            ? _SingleFillUpChart(log: sorted.first)
            : _FillUpTrendChart(
                logs: sorted,
                avgLabel: avgLabel,
              );

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

class _SingleFillUpChart extends StatelessWidget {
  const _SingleFillUpChart({required this.log});

  final FuelLog log;

  @override
  Widget build(BuildContext context) {
    final y = log.cost;
    final safeMaxY = y <= 0 ? 1000.0 : y * 1.18;
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
          unit: 'metricChartSingleFillUp'.tr(),
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
                        FillUpCostChart._dayMonth.format(log.date),
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
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.cardElevated,
                getTooltipItems: (_) => [
                  LineTooltipItem(
                    '${AppCurrency.format(y)}\n'
                    '${log.amount.toStringAsFixed(1)} L',
                    AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
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
                color: AppColors.primary.withValues(alpha: 0.9),
                barWidth: 2.2,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, _) => (spot.x - 0.5).abs() < 0.01,
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 5,
                      color: AppColors.primary,
                      strokeWidth: 2.5,
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
                      AppColors.primary.withValues(alpha: 0.22),
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.primary.withValues(alpha: 0.0),
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

class _FillUpTrendChart extends StatelessWidget {
  const _FillUpTrendChart({
    required this.logs,
    required this.avgLabel,
  });

  final List<FuelLog> logs;
  final String avgLabel;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < logs.length; i++) FlSpot(i.toDouble(), logs[i].cost),
    ];
    final values = logs.map((l) => l.cost).toList();
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final spread = math.max(maxVal - minVal, maxVal * 0.1);
    final safeMinY = math.max(0.0, minVal - spread * 0.35);
    final safeMaxY = maxVal + spread * 0.28;
    final avg = values.reduce((a, b) => a + b) / values.length;

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
                color: AppColors.wash,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: avg,
                  color: AppColors.textTertiary.withValues(alpha: 0.55),
                  strokeWidth: 1,
                  dashArray: const [4, 4],
                  label: HorizontalLineLabel(show: false),
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
                  reservedSize: 40,
                  interval: (safeMaxY - safeMinY) / 2,
                  getTitlesWidget: (value, _) {
                    if (value <= safeMinY || value >= safeMaxY) {
                      return SizedBox.shrink();
                    }
                    return Text(
                      '৳${_compactAmount(value)}',
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
                      return SizedBox.shrink();
                    }
                    final show =
                        i == 0 || i == logs.length - 1 || i % labelStep == 0;
                    if (!show) return SizedBox.shrink();
                    return Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: MetricChartLayout.axisDateLabel(
                        FillUpCostChart._axisLabel(logs, i),
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
                    '${FillUpCostChart._axisLabel(logs, i)}\n'
                    '${AppCurrency.format(log.cost)}\n'
                    '${log.amount.toStringAsFixed(1)} L',
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
                preventCurveOverShooting: true,
                curveSmoothness: 0.22,
                color: AppColors.primary.withValues(alpha: 0.35),
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
                color: AppColors.primary,
                barWidth: 2.4,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 3,
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
                    stops: const [0.0, 0.7, 1.0],
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primary.withValues(alpha: 0.06),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          duration: Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        ),
        Positioned(
          top: 0,
          right: 10,
          child: Text(
            '$avgLabel ${AppCurrency.format(avg)}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 9,
            ),
          ),
        ),
      ],
    );
  }

  String _compactAmount(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}

class _FillUpChartEmpty extends StatelessWidget {
  const _FillUpChartEmpty();

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
              lineColor: AppColors.primary.withValues(alpha: 0.55),
              fillColor: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
        ),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
