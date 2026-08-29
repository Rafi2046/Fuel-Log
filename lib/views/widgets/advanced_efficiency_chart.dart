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

/// Interactive efficiency trend with average baseline.
class AdvancedEfficiencyChart extends StatefulWidget {
  const AdvancedEfficiencyChart({
    super.key,
    required this.logs,
    required this.unit,
    this.scrollable = false,
    this.pointWidth = 64,
  });

  final List<FuelLog> logs;
  final String unit;
  final bool scrollable;
  final double pointWidth;

  @override
  State<AdvancedEfficiencyChart> createState() =>
      _AdvancedEfficiencyChartState();
}

class _AdvancedEfficiencyChartState extends State<AdvancedEfficiencyChart> {
  static final DateFormat _dayMonth = DateFormat('d MMM');

  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final series = buildEfficiencySeries(
      widget.logs,
      maxPoints: widget.scrollable ? null : 8,
    );
    if (series.isEmpty) {
      return const _ChartEmpty(messageKey: 'chartNeedMoreLogs');
    }

    final avgLabel = 'avg'.tr();

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = _finiteHeight(constraints.maxHeight);
        final chart = series.length == 1
            ? _buildSinglePointChart(series.first)
            : _buildTrendChart(series, avgLabel: avgLabel);

        final needsScroll = widget.scrollable && series.length > 6;
        if (!needsScroll) {
          return Padding(
            padding: MetricChartLayout.chartPadding,
            child: SizedBox(
              height: chartHeight,
              width: double.infinity,
              child: chart,
            ),
          );
        }

        final width = math.max(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0,
          series.length * widget.pointWidth,
        );

        return Padding(
          padding: MetricChartLayout.chartPadding,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: width,
              height: chartHeight,
              child: chart,
            ),
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

  /// One reading — hero above chart (no overlap).
  Widget _buildSinglePointChart(EfficiencyPoint point) {
    final y = point.efficiency;
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
          value: y.toStringAsFixed(1),
          unit: widget.unit,
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
                  color: Colors.white.withValues(alpha: 0.04),
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
                    reservedSize: 24,
                    interval: 0.5,
                    getTitlesWidget: (value, _) {
                      if ((value - 0.5).abs() > 0.01) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _dayMonth.format(point.date),
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
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.cardElevated,
                  getTooltipItems: (_) => [
                    LineTooltipItem(
                      '${y.toStringAsFixed(1)} ${widget.unit}\n'
                      '${_dayMonth.format(point.date)}',
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
                        radius: 4.5,
                        color: AppColors.primary,
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
                        AppColors.primary.withValues(alpha: 0.18),
                        AppColors.primary.withValues(alpha: 0.06),
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

  Widget _buildTrendChart(
    List<EfficiencyPoint> series, {
    required String avgLabel,
  }) {
    final spots = [
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].efficiency),
    ];
    final values = series.map((p) => p.efficiency).toList();
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final spread = math.max(maxVal - minVal, maxVal * 0.12);
    final safeMinY = math.max(0.0, minVal - spread * 0.35);
    final safeMaxY = maxVal + spread * 0.28;
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
                color: Colors.white.withValues(alpha: 0.05),
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
                  reservedSize: 30,
                  interval: (safeMaxY - safeMinY) / 2,
                  getTitlesWidget: (value, _) {
                    if (value <= safeMinY || value >= safeMaxY) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      value.toStringAsFixed(1),
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
                  reservedSize: 26,
                  interval: 1,
                  getTitlesWidget: (value, _) {
                    final i = value.round();
                    if (i < 0 || i >= series.length) {
                      return const SizedBox.shrink();
                    }
                    final show = i == 0 ||
                        i == series.length - 1 ||
                        i % labelStep == 0;
                    if (!show) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: MetricChartLayout.axisDateLabel(
                        _dayMonth.format(series[i].date),
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
                    '${p.efficiency.toStringAsFixed(1)} ${widget.unit}\n'
                    '${_dayMonth.format(p.date)}',
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
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                    radius: 3,
                    color: AppColors.primary,
                    strokeWidth: 1.5,
                    strokeColor: AppColors.cardElevated,
                  ),
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
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        ),
        Positioned(
          top: 0,
          right: 10,
          child: Text(
            '$avgLabel ${avg.toStringAsFixed(1)}',
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

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.messageKey});

  final String messageKey;

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
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            messageKey.tr(),
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
