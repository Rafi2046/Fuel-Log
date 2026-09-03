import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/analytics_period.dart';
import '../../../widgets/clean_glass_panel.dart';

class MetricPeriodMenu extends StatelessWidget {
  const MetricPeriodMenu({
    required this.label,
    required this.onSelect,
  });

  final String label;
  final ValueChanged<PeriodFilter> onSelect;

  String _periodLabel(PeriodFilter period) => switch (period) {
        PeriodFilter.allTime => 'metricPeriodAllTime'.tr(),
        PeriodFilter.thisYear => 'metricPeriodThisYear'.tr(),
        PeriodFilter.last6Months => 'metricPeriodLast6Months'.tr(),
        PeriodFilter.last12Months => 'metricPeriodLast12Months'.tr(),
        PeriodFilter.custom => 'metricPeriodCustomRange'.tr(),
      };

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    return PopupMenuButton<PeriodFilter>(
      onSelected: onSelect,
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: radius),
      itemBuilder: (context) => PeriodFilter.values
          .map(
            (period) => PopupMenuItem(
              value: period,
              child: Text(
                _periodLabel(period),
                style: AppTextStyles.body.copyWith(fontSize: 14),
              ),
            ),
          )
          .toList(),
      child: CleanGlassPanel(
        borderRadius: radius,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 148),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: AppColors.textTertiary,
            ),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
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

  static const _iconKeys = [
    Icons.local_gas_station_rounded,
    Icons.account_balance_wallet_outlined,
    Icons.route_rounded,
  ];

  static const _labelKeys = [
    'metricCategoryFuel',
    'metricCategoryCosts',
    'metricCategoryDistance',
  ];

  @override
  Widget build(BuildContext context) {
    return CleanGlassPanel(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          for (var i = 0; i < _labelKeys.length; i++)
            Expanded(
              child: _MetricSegmentCell(
                icon: _iconKeys[i],
                label: _labelKeys[i].tr(),
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
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    style: AppTextStyles.label.copyWith(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
      ),
    );
  }
}
