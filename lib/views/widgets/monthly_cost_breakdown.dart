import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/app_formatters.dart';
import '../screens/stats/widgets/metric_chart_empty.dart';
import 'app_card.dart';
import 'month_expense_details_sheet.dart';

/// Monthly cost breakdown combining fuel logs (orange) and service logs (green) with clickable details sheet.
class MonthlyCostBreakdown extends StatelessWidget {
  const MonthlyCostBreakdown({
    super.key,
    required this.fuelLogs,
    this.serviceLogs = const [],
  });

  final List<FuelLog> fuelLogs;
  final List<ServiceLog> serviceLogs;

  static final DateFormat _monthLabel = DateFormat('MMM yyyy');

  List<_MonthSpend> get _months {
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
      if (!order.containsKey(key)) {
        order[key] = DateTime(log.date.year, log.date.month);
      }
    }

    final keys = order.keys.toList()
      ..sort((a, b) => order[b]!.compareTo(order[a]!));

    return [
      for (final key in keys.take(6))
        _MonthSpend(
          label: _monthLabel.format(order[key]!).toUpperCase(),
          fuel: fuelMap[key] ?? 0.0,
          service: serviceMap[key] ?? 0.0,
          monthFuelLogs: fuelLogsMap[key] ?? [],
          monthServiceLogs: serviceLogsMap[key] ?? [],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final months = _months;
    if (months.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: const ChartSparklineEmpty(
          messageKey: 'noLogsYet',
          sparklineHeight: 56,
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          for (var i = 0; i < months.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: AppColors.divider),
            _MonthRow(month: months[i]),
          ],
        ],
      ),
    );
  }
}

class _MonthSpend {
  const _MonthSpend({
    required this.label,
    required this.fuel,
    required this.service,
    required this.monthFuelLogs,
    required this.monthServiceLogs,
  });

  final String label;
  final double fuel;
  final double service;
  final List<FuelLog> monthFuelLogs;
  final List<ServiceLog> monthServiceLogs;
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.month});

  final _MonthSpend month;

  @override
  Widget build(BuildContext context) {
    final hasFuel = month.fuel > 0;
    final hasService = month.service > 0;

    return InkWell(
      onTap: () {
        MonthExpenseDetailsSheet.show(
          context,
          monthLabel: month.label,
          fuelLogs: month.monthFuelLogs,
          serviceLogs: month.monthServiceLogs,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      month.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasFuel || !hasService)
                  _CostLine(
                    color: AppColors.primary,
                    label: 'Fuel',
                    value: AppCurrency.format(month.fuel),
                  ),
                if (hasFuel && hasService) const SizedBox(height: 2),
                if (hasService)
                  _CostLine(
                    color: const Color(0xFF2ECC71),
                    label: 'Service/Costs',
                    value: AppCurrency.format(month.service),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CostLine extends StatelessWidget {
  const _CostLine({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$label: $value',
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
