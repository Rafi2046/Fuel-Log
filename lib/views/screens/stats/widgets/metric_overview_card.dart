import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/analytics_period.dart';
import '../../../widgets/clean_glass_panel.dart';
import 'metric_filter_chips.dart';
import 'metric_kpi_row.dart';

/// Period selector + KPI stats in one premium glass card.
class MetricOverviewCard extends StatelessWidget {
  const MetricOverviewCard({
    super.key,
    required this.periodLabel,
    required this.onPeriodSelect,
    required this.costPerKm,
    required this.spendLabel,
    required this.distanceKm,
    required this.periodHint,
  });

  final String periodLabel;
  final ValueChanged<PeriodFilter> onPeriodSelect;
  final double costPerKm;
  final String spendLabel;
  final double distanceKm;
  final String periodHint;

  @override
  Widget build(BuildContext context) {
    return CleanGlassPanel(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'metricKpiThisPeriod'.tr(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: MetricPeriodMenu(
                    label: periodLabel,
                    onSelect: onPeriodSelect,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),
          MetricKpiRow(
            costPerKm: costPerKm,
            spendLabel: spendLabel,
            distanceKm: distanceKm,
            periodHint: periodHint,
            embedded: true,
          ),
        ],
      ),
    );
  }
}
