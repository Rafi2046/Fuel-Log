import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/app_formatters.dart';
import 'app_card.dart';
import 'expense_ratio_chart.dart';

/// Minimal month rows: fuel (orange) + dummy service (green).
class MonthlyCostBreakdown extends StatelessWidget {
  const MonthlyCostBreakdown({super.key, required this.logs});

  final List<FuelLog> logs;

  static final DateFormat _monthLabel = DateFormat('MMM yyyy');

  List<_MonthSpend> get _months {
    final map = <String, double>{};
    final order = <String, DateTime>{};

    for (final log in logs) {
      final key =
          '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + log.cost;
      order[key] = DateTime(log.date.year, log.date.month);
    }

    final keys = map.keys.toList()
      ..sort((a, b) => order[b]!.compareTo(order[a]!));

    return [
      for (final key in keys.take(6))
        _MonthSpend(
          label: _monthLabel.format(order[key]!).toUpperCase(),
          fuel: map[key]!,
          service: ExpenseRatioChart.dummyServiceCost,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final months = _months;
    if (months.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text('noLogsYet'.tr(), style: AppTextStyles.caption),
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          for (var i = 0; i < months.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.divider),
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
  });

  final String label;
  final double fuel;
  final double service;
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.month});

  final _MonthSpend month;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              month.label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _CostLine(
                color: AppColors.primary,
                value: AppCurrency.format(month.fuel),
              ),
              const SizedBox(height: 2),
              _CostLine(
                color: AppColors.success,
                value: AppCurrency.format(month.service),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CostLine extends StatelessWidget {
  const _CostLine({required this.color, required this.value});

  final Color color;
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
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
