import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_text_field.dart';

/// Compact, elegant Odometer & Trip Distance section.
class RefuelingOdometerSection extends StatelessWidget {
  const RefuelingOdometerSection({
    super.key,
    required this.odometerController,
    required this.tripOdometerController,
    required this.lastOdometer,
    required this.onOdometerChanged,
    required this.onTripOdometerChanged,
  });

  final TextEditingController odometerController;
  final TextEditingController tripOdometerController;
  final double? lastOdometer;
  final VoidCallback onOdometerChanged;
  final VoidCallback onTripOdometerChanged;

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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 10,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Last: $lastOdoStr',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
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
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Total Odometer',
                  hint: lastOdometer != null ? '${lastOdometer!.round()}' : '0',
                  controller: odometerController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.speed_rounded,
                  suffixText: 'km',
                  onChanged: (_) => onOdometerChanged(),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  label: 'Trip Distance',
                  hint: 'e.g. 350',
                  controller: tripOdometerController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.add_road_rounded,
                  suffixText: 'km',
                  onChanged: (_) => onTripOdometerChanged(),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
