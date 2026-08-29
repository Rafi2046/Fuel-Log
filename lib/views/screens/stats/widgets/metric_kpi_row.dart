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
    this.embedded = false,
  });

  final double costPerKm;
  final String spendLabel;
  final double distanceKm;
  final String periodHint;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final cells = [
      MetricKpiCard(
        title: 'metricKpiCostPerKm'.tr(),
        value: costPerKm > 0 ? '৳${costPerKm.toStringAsFixed(2)}' : '—',
        hint: costPerKm > 0
            ? 'metricKpiPerKm'.tr()
            : 'metricKpiNeedLogs'.tr(),
        icon: Icons.speed_rounded,
        embedded: embedded,
      ),
      MetricKpiCard(
        title: 'metricKpiSpend'.tr(),
        value: spendLabel,
        hint: periodHint,
        icon: Icons.payments_outlined,
        highlightValue: true,
        embedded: embedded,
      ),
      MetricKpiCard(
        title: 'metricKpiDistance'.tr(),
        value: distanceKm > 0
            ? '${distanceKm.toStringAsFixed(0)} km'
            : '—',
        hint: 'metricKpiThisPeriod'.tr(),
        icon: Icons.route_rounded,
        embedded: embedded,
      ),
    ];

    if (embedded) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              Expanded(child: cells[i]),
            ],
          ],
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: cells[i]),
          ],
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
    this.embedded = false,
  });

  final String title;
  final String value;
  final String hint;
  final IconData icon;
  final bool highlightValue;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: (highlightValue ? AppColors.primary : AppColors.textTertiary)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 12,
                color: highlightValue
                    ? AppColors.primary
                    : AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 6),
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
    );

    if (embedded) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: content,
      );
    }

    return CleanGlassPanel(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: content,
    );
  }
}
