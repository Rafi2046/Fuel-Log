import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/mileage_calculator.dart';

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

  @override
  Widget build(BuildContext context) {
    final series = buildFuelPriceSeries(
      logs,
      maxPoints: scrollable ? null : 8,
    );
    if (series.length < 2) {
      return Center(
        child: Text('chartNeedMoreLogs'.tr(), style: AppTextStyles.caption),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = _finiteHeight(constraints.maxHeight);
        final chart = _Line(series: series, priceUnit: priceUnit);

        final needsScroll = scrollable && series.length > 6;
        if (!needsScroll) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: SizedBox(height: height, child: chart),
          );
        }

        final width = math.max(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0,
          series.length * pointWidth,
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.md,
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
      return maxHeight - AppSpacing.md;
    }
    return 220;
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.series, required this.priceUnit});

  final List<FuelPricePoint> series;
  final String priceUnit;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].price),
    ];
    final maxY = series.map((p) => p.price).reduce((a, b) => a > b ? a : b) *
        1.25;
    final safeMaxY = maxY <= 0 ? 1.0 : maxY;
    final labelStep = series.length > 12
        ? (series.length / 8).ceil()
        : series.length > 6
            ? 2
            : 1;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (series.length - 1).toDouble(),
        minY: 0,
        maxY: safeMaxY,
        clipData: const FlClipData.all(),
        gridData: const FlGridData(show: false),
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
              reservedSize: 36,
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
                    FuelPriceChart._dayMonth.format(series[i].date),
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
                '${point.price.toStringAsFixed(1)} $priceUnit\n'
                '${FuelPriceChart._dayMonth.format(point.date)}',
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
            color: AppColors.warning,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) => true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 3.2,
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
                colors: [
                  AppColors.warning.withValues(alpha: 0.28),
                  AppColors.warning.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}
