import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/analytics_period.dart';

class MetricPeriodMenu extends StatelessWidget {
  const MetricPeriodMenu({
    required this.label,
    required this.onSelect,
  });

  final String label;
  final ValueChanged<PeriodFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    return PopupMenuButton<PeriodFilter>(
      onSelected: onSelect,
      color: const Color(0xFF1A1A24),
      shape: RoundedRectangleBorder(borderRadius: radius),
      itemBuilder: (context) => PeriodFilter.values
          .map(
            (period) => PopupMenuItem(
              value: period,
              child: Text(
                switch (period) {
                  PeriodFilter.allTime => 'All time',
                  PeriodFilter.thisYear => 'This year',
                  PeriodFilter.last6Months => 'Last 6 months',
                  PeriodFilter.last12Months => 'Last 12 months',
                  PeriodFilter.custom => 'Custom range',
                },
                style: AppTextStyles.body.copyWith(fontSize: 14),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          borderRadius: radius,
          border: Border.all(color: const Color(0xFF2A2A36)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class MetricFilterChips extends StatelessWidget {
  const MetricFilterChips({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.local_gas_station_rounded, 'Fuel'),
    (Icons.account_balance_wallet_outlined, 'Costs'),
    (Icons.route_rounded, 'Distance'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: const Color(0xFF2A2A36)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: _MetricSegmentCell(
                icon: _items[i].$1,
                label: _items[i].$2,
                selected: index == i,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricSegmentCell extends StatelessWidget {
  const _MetricSegmentCell({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusSm);
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.18)
          : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

