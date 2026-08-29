import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../widgets/clean_glass_panel.dart';

class MetricKpiRow extends StatelessWidget {
  const MetricKpiRow({
    super.key,
    required this.costPerKm,
    required this.spendLabel,
    required this.distanceKm,
    required this.periodHint,
  });

  final double costPerKm;
  final String spendLabel;
  final double distanceKm;
  final String periodHint;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: MetricKpiCard(
              title: 'metricKpiCostPerKm'.tr(),
              value: costPerKm > 0 ? '৳${costPerKm.toStringAsFixed(2)}' : '—',
              hint: costPerKm > 0
                  ? 'metricKpiPerKm'.tr()
                  : 'metricKpiNeedLogs'.tr(),
              icon: Icons.speed_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: MetricKpiCard(
              title: 'metricKpiSpend'.tr(),
              value: spendLabel,
              hint: periodHint,
              icon: Icons.payments_outlined,
              highlightValue: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: MetricKpiCard(
              title: 'metricKpiDistance'.tr(),
              value: distanceKm > 0
                  ? '${distanceKm.toStringAsFixed(0)} km'
                  : '—',
              hint: 'metricKpiThisPeriod'.tr(),
              icon: Icons.route_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class MetricKpiCard extends StatelessWidget {
  const MetricKpiCard({
    required this.title,
    required this.value,
    required this.hint,
    required this.icon,
    this.highlightValue = false,
  });

  final String title;
  final String value;
  final String hint;
  final IconData icon;
  final bool highlightValue;

  @override
  Widget build(BuildContext context) {
    return CleanGlassPanel(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.title.copyWith(
              fontSize: highlightValue ? 14 : 13,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: highlightValue
                  ? AppColors.textPrimary
                  : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            hint,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 9,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
