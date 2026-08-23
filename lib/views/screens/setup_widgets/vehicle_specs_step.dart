import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dropdown_field.dart';
import '../../widgets/app_text_field.dart';

/// Step 2 — odometer, fuel type, tank capacity.
class VehicleSpecsStep extends StatelessWidget {
  const VehicleSpecsStep({
    super.key,
    required this.odometerController,
    required this.tankController,
    required this.selectedFuelType,
    required this.fuelTypes,
    required this.onFuelTypeChanged,
  });

  final TextEditingController odometerController;
  final TextEditingController tankController;
  final String selectedFuelType;
  final List<String> fuelTypes;
  final ValueChanged<String?> onFuelTypeChanged;

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
            'Technical Specs',
            style: AppTextStyles.display.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Odometer and fuel details.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Start Odometer',
                  hint: '0',
                  controller: odometerController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.speed_rounded,
                  suffixText: 'km',
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                AppDropdownField<String>(
                  label: 'Fuel Type',
                  value: selectedFuelType,
                  prefixIcon: Icons.local_gas_station_rounded,
                  items: fuelTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: onFuelTypeChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Tank Capacity',
                  hint: '40',
                  controller: tankController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icons.opacity_rounded,
                  suffixText: 'Liters',
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
