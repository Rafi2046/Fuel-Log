import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../widgets/month_expense_details_sheet.dart';
import 'metric_chart_empty.dart';

/// Monthly spend for Metric Explorer — premium bar chart + compact rows.
class MetricMonthlySpendPanel extends StatelessWidget {
  const MetricMonthlySpendPanel({
    super.key,
    required this.fuelLogs,
    this.serviceLogs = const [],
  });

  final List<FuelLog> fuelLogs;
  final List<ServiceLog> serviceLogs;

  static const int _slotCount = 6;
  static final DateFormat _monthLabel = DateFormat('MMM');

  List<_MonthSpend> _aggregateMonths() {
    final fuelMap = <String, double>{};
    final serviceMap = <String, double>{};
    final fuelLogsMap = <String, List<FuelLog>>{};
    final serviceLogsMap = <String, List<ServiceLog>>{};
    final order = <String, DateTime>{};

    for (final log in fuelLogs) {
      final key =
          '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}';
      fuelMap[key] = (fuelMap[key] ?? 0) + log.cost;
      fuelLogsMap.putIfAbsent(key, () => []).add(log);
      order[key] = DateTime(log.date.year, log.date.month);
    }

    for (final log in serviceLogs) {
      final key =
          '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}';
      serviceMap[key] = (serviceMap[key] ?? 0) + log.cost;
      serviceLogsMap.putIfAbsent(key, () => []).add(log);
      order.putIfAbsent(
        key,
        () => DateTime(log.date.year, log.date.month),
      );
    }

    return [
      for (final key in order.keys)
        _MonthSpend(
          period: order[key]!,
          label: DateFormat('MMM yyyy').format(order[key]!).toUpperCase(),
          shortLabel: _monthLabel.format(order[key]!),
          fuel: fuelMap[key] ?? 0.0,
          service: serviceMap[key] ?? 0.0,
          monthFuelLogs: fuelLogsMap[key] ?? [],
          monthServiceLogs: serviceLogsMap[key] ?? [],
        ),
    ];
  }

  List<_MonthSpend> _chartMonths(List<_MonthSpend> dataMonths) {
    if (dataMonths.isEmpty) return [];

    final end = dataMonths
        .map((m) => m.period)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final byKey = {
      for (final m in dataMonths)
        '${m.period.year}-${m.period.month.toString().padLeft(2, '0')}': m,
    };

    return [
      for (var i = _slotCount - 1; i >= 0; i--)
        () {
          final period = DateTime(end.year, end.month - i);
          final key =
              '${period.year}-${period.month.toString().padLeft(2, '0')}';
          return byKey[key] ??
              _MonthSpend.empty(
                period: period,
                shortLabel: _monthLabel.format(period),
              );
        }(),
    ];
  }

  double _barWidth(int count) {
    if (count <= 3) return 14;
    if (count <= 5) return 11;
    return 8;
  }

  @override
  Widget build(BuildContext context) {
    final dataMonths = _aggregateMonths();
    if (dataMonths.isEmpty) {
      return const ChartSparklineEmpty(messageKey: 'noLogsYet');
    }

    final months = _chartMonths(dataMonths);
    final activeMonths = months.where((m) => m.hasSpend).toList();
    final maxTotal = activeMonths.isEmpty
        ? 1.0
        : activeMonths
            .map((m) => m.total)
            .reduce((a, b) => a > b ? a : b);
    final safeMaxY = (maxTotal * 1.15).clamp(500.0, double.infinity);
    final barWidth = _barWidth(months.length);

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
                      reservedSize: 36,
                      interval: safeMaxY / 3,
                      getTitlesWidget: (value, _) {
                        if (value <= 0) return SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(right: 4),
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
                          return SizedBox.shrink();
                        }
                        final m = months[i];
                        return Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            m.shortLabel,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: m.hasSpend
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                              fontWeight: m.hasSpend
                                  ? FontWeight.w600
                                  : FontWeight.w400,
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
                      color: AppColors.washBorder,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final m = months[group.x];
                      if (!m.hasSpend) return null;
                      return BarTooltipItem(
                        '${m.label}\n'
                        '${'metricCategoryFuel'.tr()}: ${AppCurrency.format(m.fuel)}'
                        '${m.service > 0 ? '\n${'metricCategoryCosts'.tr()}: ${AppCurrency.format(m.service)}' : ''}',
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
                      barRods: _rodsForMonth(
                        months[i],
                        barWidth: barWidth,
                      ),
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
        ...dataMonths.reversed.take(3).map(
              (m) => _MonthRow(month: m),
            ),
      ],
    );
  }

  List<BarChartRodData> _rodsForMonth(
    _MonthSpend month, {
    required double barWidth,
  }) {
    if (!month.hasSpend) return const [];

    final fuelRadius = month.service > 0
        ? const BorderRadius.vertical(top: Radius.circular(2))
        : const BorderRadius.vertical(top: Radius.circular(6));

    return [
      if (month.fuel > 0)
        BarChartRodData(
          toY: month.fuel,
          width: barWidth,
          borderRadius: fuelRadius,
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
      if (month.service > 0)
        BarChartRodData(
          fromY: month.fuel,
          toY: month.fuel + month.service,
          width: barWidth,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          gradient: const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0xFF1E8449),
              AppColors.success,
              Color(0xFF58D68D),
            ],
          ),
        ),
    ];
  }

  String _axisLabel(double value) {
    if (value >= 1000) {
      final k = value / 1000;
      return k >= 10 ? '${k.toStringAsFixed(0)}k' : '${k.toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}

class _MonthSpend {
  const _MonthSpend({
    required this.period,
    required this.label,
    required this.shortLabel,
    required this.fuel,
    required this.service,
    required this.monthFuelLogs,
    required this.monthServiceLogs,
  });

  factory _MonthSpend.empty({
    required DateTime period,
    required String shortLabel,
  }) {
    return _MonthSpend(
      period: period,
      label: DateFormat('MMM yyyy').format(period).toUpperCase(),
      shortLabel: shortLabel,
      fuel: 0,
      service: 0,
      monthFuelLogs: const [],
      monthServiceLogs: const [],
    );
  }

  final DateTime period;
  final String label;
  final String shortLabel;
  final double fuel;
  final double service;
  final List<FuelLog> monthFuelLogs;
  final List<ServiceLog> monthServiceLogs;

  double get total => fuel + service;
  bool get hasSpend => total > 0;
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.month});

  final _MonthSpend month;

  @override
  Widget build(BuildContext context) {
    final hasFuel = month.fuel > 0;
    final hasService = month.service > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AppColors.wash,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: () {
            MonthExpenseDetailsSheet.show(
              context,
              monthLabel: month.label,
              fuelLogs: month.monthFuelLogs,
              serviceLogs: month.monthServiceLogs,
            );
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.washDivider,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  month.label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (hasFuel)
                        _CostChip(
                          color: AppColors.primary,
                          label: 'metricCategoryFuel'.tr(),
                          value: AppCurrency.format(month.fuel),
                        ),
                      if (hasService)
                        _CostChip(
                          color: AppColors.success,
                          label: 'metricCategoryCosts'.tr(),
                          value: AppCurrency.format(month.service),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CostChip extends StatelessWidget {
  const _CostChip({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final maxTextWidth = MediaQuery.sizeOf(context).width * 0.42;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxTextWidth),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$label: $value',
                maxLines: 1,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
