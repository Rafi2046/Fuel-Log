import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/mileage_calculator.dart';

/// Monthly distance panel for Metric Explorer.
class MetricMonthlyDistancePanel extends StatelessWidget {
  const MetricMonthlyDistancePanel({super.key, required this.logs});

  final List<FuelLog> logs;

  static const int _slotCount = 6;
  static final DateFormat _monthLabel = DateFormat('MMM');
  static final DateFormat _monthYear = DateFormat('MMM yyyy');

  List<_MonthKm> _chartMonths(List<MonthlyDistancePoint> data) {
    if (data.isEmpty) return [];

    final end = data.map((p) => p.period).reduce((a, b) => a.isAfter(b) ? a : b);
    final byKey = {
      for (final p in data)
        '${p.year}-${p.month.toString().padLeft(2, '0')}': p,
    };

    return [
      for (var i = _slotCount - 1; i >= 0; i--)
        () {
          final period = DateTime(end.year, end.month - i);
          final key =
              '${period.year}-${period.month.toString().padLeft(2, '0')}';
          final point = byKey[key];
          return _MonthKm(
            period: period,
            shortLabel: _monthLabel.format(period),
            label: _monthYear.format(period).toUpperCase(),
            km: point?.km ?? 0,
          );
        }(),
    ];
  }

  double _barWidth(int activeCount, int slotCount) {
    if (activeCount <= 1) return 22;
    if (activeCount <= 2) return 18;
    if (slotCount <= 3) return 16;
    if (slotCount <= 5) return 12;
    return 9;
  }

  String _axisLabel(double value) {
    if (value >= 1000) {
      final k = value / 1000;
      return k >= 10 ? '${k.toStringAsFixed(0)}k' : '${k.toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final data = buildMonthlyDistanceSeries(logs, maxMonths: null);
    if (data.isEmpty) {
      return Center(
        child: Text('chartNeedMoreLogs'.tr(), style: AppTextStyles.caption),
      );
    }

    final months = _chartMonths(data);
    final active = months.where((m) => m.km > 0).toList();
    final maxKm = active.isEmpty
        ? 1.0
        : active.map((m) => m.km).reduce((a, b) => a > b ? a : b);
    final safeMaxY = (maxKm * 1.18).clamp(20.0, double.infinity);
    final barWidth = _barWidth(active.length, months.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
            child: BarChart(
              BarChartData(
                maxY: safeMaxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMaxY / 3,
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
                      reservedSize: 36,
                      interval: safeMaxY / 2,
                      getTitlesWidget: (value, _) {
                        if (value <= 0 || value >= safeMaxY) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            _axisLabel(value),
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 9,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= months.length) {
                          return const SizedBox.shrink();
                        }
                        final m = months[i];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            m.shortLabel,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: m.km > 0
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                              fontWeight:
                                  m.km > 0 ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipColor: (_) => AppColors.cardElevated,
                    tooltipBorder: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final m = months[group.x];
                      if (m.km <= 0) return null;
                      return BarTooltipItem(
                        '${m.label}\n${m.km.toStringAsFixed(0)} ${'km'.tr()}',
                        AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      );
                    },
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < months.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: months[i].km > 0
                          ? [
                              BarChartRodData(
                                toY: months[i].km,
                                width: barWidth,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                                gradient: const LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color(0xFFCC5A35),
                                    AppColors.primary,
                                    AppColors.secondary,
                                  ],
                                ),
                              ),
                            ]
                          : const [],
                    ),
                ],
                alignment: BarChartAlignment.spaceBetween,
                groupsSpace: 6,
              ),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...active.reversed.take(3).map((m) => _MonthKmRow(month: m)),
      ],
    );
  }
}

class _MonthKm {
  const _MonthKm({
    required this.period,
    required this.shortLabel,
    required this.label,
    required this.km,
  });

  final DateTime period;
  final String shortLabel;
  final String label;
  final double km;
}

class _MonthKmRow extends StatelessWidget {
  const _MonthKmRow({required this.month});

  final _MonthKm month;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                month.label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                '${month.km.toStringAsFixed(0)} ${'km'.tr()}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
