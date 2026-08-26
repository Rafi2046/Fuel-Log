import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

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
    return SizedBox(
      height: 112,
      child: Row(
        children: [
          Expanded(
            child: MetricKpiCard(
              title: 'Cost / km',
              value: costPerKm > 0 ? '৳${costPerKm.toStringAsFixed(2)}' : '—',
              hint: costPerKm > 0 ? 'per km' : 'Need logs',
              icon: Icons.speed_rounded,
              accent: const Color(0xFF38BDF8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MetricKpiCard(
              title: 'Spend',
              value: spendLabel,
              hint: periodHint,
              icon: Icons.payments_outlined,
              accent: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MetricKpiCard(
              title: 'Distance',
              value: distanceKm > 0 ? '${distanceKm.toStringAsFixed(0)} km' : '—',
              hint: 'this period',
              icon: Icons.route_rounded,
              accent: const Color(0xFFA855F7),
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
    required this.accent,
  });

  final String title;
  final String value;
  final String hint;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: const Color(0xFF2A2A36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 14, color: accent),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.title.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
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
