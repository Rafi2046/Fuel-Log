import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/app_selectable_card.dart';

enum VehicleType { car, bike }

/// Step 1 — vehicle type, name, and model with sleek grouped luxury layout.
class VehicleIdentityStep extends StatelessWidget {
  const VehicleIdentityStep({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.nameController,
    required this.modelController,
  });

  final VehicleType selectedType;
  final ValueChanged<VehicleType> onTypeChanged;
  final TextEditingController nameController;
  final TextEditingController modelController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Vehicle',
            style: AppTextStyles.headline.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose vehicle type and set basic identity.',
            style: AppTextStyles.bodySecondary.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Section 1: Type Selection
          Text(
            'VEHICLE TYPE',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppSelectableCard(
                  title: 'Car',
                  subtitle: 'Sedan, SUV, EV',
                  icon: Icons.directions_car_filled_rounded,
                  isSelected: selectedType == VehicleType.car,
                  onTap: () => onTypeChanged(VehicleType.car),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppSelectableCard(
                  title: 'Bike',
                  subtitle: 'Motorcycle, Scooter',
                  icon: Icons.two_wheeler_rounded,
                  isSelected: selectedType == VehicleType.bike,
                  onTap: () => onTypeChanged(VehicleType.bike),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Section 2: Identity Form (Grouped Luxury Card)
          Text(
            'VEHICLE DETAILS',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _IdentityInputRow(
                  label: 'Vehicle Name',
                  hint: 'e.g., Family SUV, Daily Ride',
                  controller: nameController,
                  icon: selectedType == VehicleType.car
                      ? Icons.directions_car_outlined
                      : Icons.two_wheeler_outlined,
                  textInputAction: TextInputAction.next,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border.withValues(alpha: 0.6),
                  indent: 64,
                ),
                _IdentityInputRow(
                  label: 'Model',
                  hint: 'e.g., Toyota Axio, Yamaha R15',
                  controller: modelController,
                  icon: Icons.badge_outlined,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _IdentityInputRow extends StatelessWidget {
  const _IdentityInputRow({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.textInputAction = TextInputAction.next,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  textInputAction: textInputAction,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: hint,
                    hintStyle: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.textTertiary.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
