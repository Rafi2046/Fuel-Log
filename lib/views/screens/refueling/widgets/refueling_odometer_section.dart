import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_text_field.dart';

/// Compact Odometer & Trip Distance — total is primary; trip is a helper.
class RefuelingOdometerSection extends StatelessWidget {
  const RefuelingOdometerSection({
    super.key,
    required this.odometerController,
    required this.tripOdometerController,
    required this.odometerFocus,
    required this.tripFocus,
    required this.lastOdometer,
    required this.onOdometerEditingComplete,
    required this.onTripEditingComplete,
    required this.onOdometerChanged,
  });

  final TextEditingController odometerController;
  final TextEditingController tripOdometerController;
  final FocusNode odometerFocus;
  final FocusNode tripFocus;
  final double? lastOdometer;
  final VoidCallback onOdometerEditingComplete;
  final VoidCallback onTripEditingComplete;
  final VoidCallback onOdometerChanged;

  @override
  Widget build(BuildContext context) {
    final lastOdoStr = lastOdometer != null && lastOdometer! > 0
        ? '${lastOdometer!.toStringAsFixed(0)} km'
        : '0 km';

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.speed_rounded,
                      color: AppColors.textTertiary,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Odometer Readings',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 10,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Last: $lastOdoStr',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Total Odometer',
                  hint: lastOdometer != null ? '${lastOdometer!.round()}' : '0',
                  controller: odometerController,
                  focusNode: odometerFocus,
                  dense: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.speed_rounded,
                  suffixText: 'km',
                  onChanged: (_) => onOdometerChanged(),
                  onEditingComplete: onOdometerEditingComplete,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  label: 'Trip',
                  hint: '0',
                  controller: tripOdometerController,
                  focusNode: tripFocus,
                  dense: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.add_road_rounded,
                  suffixText: 'km',
                  onEditingComplete: onTripEditingComplete,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Km since last refuel. Trip and total odometer update each other.',
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: AppColors.textTertiary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
