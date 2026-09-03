import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/mileage_calculator.dart';
import 'metric_chart_layout.dart';
import '../screens/stats/widgets/metric_chart_empty.dart';
import 'metric_single_point_hero.dart';

/// Unit fuel/charge price trend (৳ per L or kWh).
class FuelPriceChart extends StatelessWidget {
  const FuelPriceChart({
    super.key,
    required this.logs,
    required this.priceUnit,
    this.scrollable = false,
    this.pointWidth = 64,
  });

  final List<FuelLog> logs;
  final String priceUnit;
  final bool scrollable;
  final double pointWidth;

  static final DateFormat _dayMonth = DateFormat('d MMM');

  static String _axisLabel(List<FuelPricePoint> series, int index) {
    final date = series[index].date;
    final sameDay = series
        .where(
          (p) =>
              p.date.year == date.year &&
              p.date.month == date.month &&
              p.date.day == date.day,
        )
        .length;
    if (sameDay > 1) {
      var n = 0;
      for (var i = 0; i <= index; i++) {
        final d = series[i].date;
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
    final series = buildFuelPriceSeries(
      logs,
      maxPoints: scrollable ? null : 8,
    );
    if (series.isEmpty) {
      return const _PriceChartEmpty();
    }

    final avgLabel = 'avg'.tr();

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = _finiteHeight(constraints.maxHeight);
        final chart = series.length == 1
            ? _SinglePriceChart(
                point: series.first,
                priceUnit: priceUnit,
              )
            : _PriceTrendChart(
                series: series,
                priceUnit: priceUnit,
                avgLabel: avgLabel,
              );

        final needsScroll = scrollable && series.length > 6;
        if (!needsScroll) {
          return Padding(
            padding: MetricChartLayout.chartPadding,
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: chart,
            ),
          );
        }

        final width = math.max(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0,
          series.length * pointWidth,
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(width: width, height: height, child: chart),
          ),
        );
      },
    );
  }

  double _finiteHeight(double maxHeight) {
    if (maxHeight.isFinite && maxHeight > AppSpacing.md + 80) {
      return maxHeight - AppSpacing.sm;
    }
    return 220;
  }
}

class _SinglePriceChart extends StatelessWidget {
  const _SinglePriceChart({
    required this.point,
    required this.priceUnit,
  });

  final FuelPricePoint point;
  final String priceUnit;

  @override
  Widget build(BuildContext context) {
    final y = point.price;
    final safeMaxY = y <= 0 ? 1.0 : y * 1.18;
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
          value: '৳${y.toStringAsFixed(1)}',
          unit: priceUnit,
          accentStart: AppColors.warning.withValues(alpha: 0.85),
          accentEnd: AppColors.warning,
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
                        FuelPriceChart._dayMonth.format(point.date),
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
                    '${y.toStringAsFixed(1)} $priceUnit\n'
                    '${FuelPriceChart._dayMonth.format(point.date)}',
                    AppTextStyles.caption.copyWith(
                      color: AppColors.warning,
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
                color: AppColors.warning.withValues(alpha: 0.9),
                barWidth: 2.2,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, _) => (spot.x - 0.5).abs() < 0.01,
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 5,
                      color: AppColors.warning,
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
                      AppColors.warning.withValues(alpha: 0.2),
                      AppColors.warning.withValues(alpha: 0.07),
                      AppColors.warning.withValues(alpha: 0.0),
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

class _PriceTrendChart extends StatelessWidget {
  const _PriceTrendChart({
    required this.series,
    required this.priceUnit,
    required this.avgLabel,
  });

  final List<FuelPricePoint> series;
  final String priceUnit;
  final String avgLabel;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].price),
    ];
    final values = series.map((p) => p.price).toList();
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final spread = math.max(maxVal - minVal, maxVal * 0.08);
    final safeMinY = math.max(0.0, minVal - spread * 0.45);
    final safeMaxY = maxVal + spread * 0.32;
    final avg = values.reduce((a, b) => a + b) / values.length;

    final labelStep = series.length > 12
        ? (series.length / 8).ceil()
        : series.length > 6
            ? 2
            : 1;

    final edge = MetricChartLayout.edgePad(series.length);

    return Stack(
      children: [
        LineChart(
          LineChartData(
            minX: -edge,
            maxX: (series.length - 1).toDouble() + edge,
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
                      '৳${value.toStringAsFixed(0)}',
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
                    if (i < 0 || i >= series.length) {
                      return const SizedBox.shrink();
                    }
                    final show = i == 0 ||
                        i == series.length - 1 ||
                        i % labelStep == 0;
                    if (!show) return SizedBox.shrink();
                    return Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: MetricChartLayout.axisDateLabel(
                        FuelPriceChart._axisLabel(series, i),
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
                  final i = s.x.round().clamp(0, series.length - 1);
                  final p = series[i];
                  return LineTooltipItem(
                    '৳${p.price.toStringAsFixed(1)} $priceUnit\n'
                    '${FuelPriceChart._axisLabel(series, i)}',
                    AppTextStyles.caption.copyWith(
                      color: AppColors.warning,
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
                color: AppColors.warning.withValues(alpha: 0.35),
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
                color: AppColors.warning,
                barWidth: 2.4,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 3,
                      color: AppColors.warning,
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
                      AppColors.warning.withValues(alpha: 0.18),
                      AppColors.warning.withValues(alpha: 0.06),
                      AppColors.warning.withValues(alpha: 0.0),
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
            '$avgLabel ৳${avg.toStringAsFixed(1)}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 9,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceChartEmpty extends StatelessWidget {
  const _PriceChartEmpty();

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
              lineColor: AppColors.warning.withValues(alpha: 0.5),
              fillColor: AppColors.warning.withValues(alpha: 0.12),
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
