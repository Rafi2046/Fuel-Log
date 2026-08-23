import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_selectable_card.dart';
import '../../widgets/app_text_field.dart';

enum VehicleType { car, bike }

/// Step 1 — type, name, and model.
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
            style: AppTextStyles.display.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Set your vehicle's basic identity.",
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Select Machine Type', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppSelectableCard(
                  title: 'Car',
                  icon: Icons.directions_car_rounded,
                  isSelected: selectedType == VehicleType.car,
                  onTap: () => onTypeChanged(VehicleType.car),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppSelectableCard(
                  title: 'Bike',
                  icon: Icons.two_wheeler_rounded,
                  isSelected: selectedType == VehicleType.bike,
                  onTap: () => onTypeChanged(VehicleType.bike),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              children: [
                AppTextField(
                  label: 'Vehicle Name',
                  hint: 'e.g., Family SUV',
                  controller: nameController,
                  prefixIcon: Icons.directions_car_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Model',
                  hint: 'e.g., Toyota Axio',
                  controller: modelController,
                  prefixIcon: Icons.badge_outlined,
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
