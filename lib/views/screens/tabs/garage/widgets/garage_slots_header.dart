import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../widgets/clean_glass_panel.dart';

/// Garage capacity indicator — e.g. "1 of 3 vehicles".
class GarageSlotsHeader extends StatelessWidget {
  const GarageSlotsHeader({
    super.key,
    required this.used,
    required this.max,
  });

  final int used;
  final int max;

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (used / max).clamp(0.0, 1.0) : 0.0;

    return CleanGlassPanel(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.garage_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'garageTitle'.tr(),
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'garageSlotsUsed'.tr(
                        namedArgs: {'used': '$used', 'max': '$max'},
                      ),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              color: AppColors.primary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
