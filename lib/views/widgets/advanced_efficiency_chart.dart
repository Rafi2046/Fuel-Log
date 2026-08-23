import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/mileage_calculator.dart';

/// Interactive efficiency trend with average baseline.
///
/// When [scrollable] is true (fullscreen), full history is plotted and the
/// chart can be panned horizontally if there are many points.
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
    if (series.length < 2) {
      return const _ChartEmpty(messageKey: 'chartNeedMoreLogs');
    }

    // Resolve i18n in build — not inside fl_chart painters.
    final avgLabel = 'avg'.tr();

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = _finiteHeight(constraints.maxHeight);
        final chart = _buildChart(series, avgLabel: avgLabel);

        final needsScroll = widget.scrollable && series.length > 6;
        if (!needsScroll) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: SizedBox(height: chartHeight, child: chart),
          );
        }

        final width = math.max(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0,
          series.length * widget.pointWidth,
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
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
      return maxHeight - AppSpacing.md;
    }
    return 220;
  }

  Widget _buildChart(
    List<EfficiencyPoint> series, {
    required String avgLabel,
  }) {
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
    final safeMaxY = maxY <= 0 ? 1.0 : maxY;

    final labelStep = series.length > 12
        ? (series.length / 8).ceil()
        : series.length > 6
            ? 2
            : 1;

    return Stack(
      children: [
        LineChart(
          LineChartData(
            minX: 0,
            maxX: (series.length - 1).toDouble(),
            minY: 0,
            maxY: safeMaxY,
            clipData: const FlClipData.all(),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: avg,
                  color: AppColors.textTertiary.withValues(alpha: 0.7),
                  strokeWidth: 1,
                  dashArray: const [5, 5],
                  // Avoid HorizontalLineLabel paint (MediaQuery) during
                  // orientation changes; avg badge is drawn in the Stack.
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
                  reservedSize: 32,
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
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipColor: (_) => AppColors.card,
                getTooltipItems: (touched) => touched.map((s) {
                  final i = s.x.round().clamp(0, series.length - 1);
                  final point = series[i];
                  return LineTooltipItem(
                    '${point.efficiency.toStringAsFixed(1)} ${widget.unit}\n'
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
                preventCurveOverShooting: true,
                color: AppColors.primary,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, barData) => true,
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
          duration: Duration.zero,
        ),
        Positioned(
          top: 0,
          right: 4,
          child: Text(
            avgLabel,
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
