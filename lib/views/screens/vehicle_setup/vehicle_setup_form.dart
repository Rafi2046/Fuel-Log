import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_icon_choice.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toggle_row.dart';
import 'vehicle_setup_form_data.dart';

/// Identity + odometer fields for first-run vehicle setup.
class VehicleSetupForm extends StatelessWidget {
  const VehicleSetupForm({
    super.key,
    required this.data,
    required this.nameController,
    required this.modelController,
    required this.odometerController,
    required this.tankController,
    required this.onTypeChanged,
    required this.onDefaultChanged,
  });

  final VehicleSetupFormData data;
  final TextEditingController nameController;
  final TextEditingController modelController;
  final TextEditingController odometerController;
  final TextEditingController tankController;
  final ValueChanged<VehicleType> onTypeChanged;
  final ValueChanged<bool> onDefaultChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vehicle type', style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.md),
              AppIconChoice<VehicleType>(
                selected: data.type,
                onChanged: onTypeChanged,
                options: const [
                  AppIconChoiceOption(
                    value: VehicleType.car,
                    label: 'Car',
                    icon: Icons.directions_car_filled_rounded,
                  ),
                  AppIconChoiceOption(
                    value: VehicleType.bike,
                    label: 'Bike',
                    icon: Icons.two_wheeler_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              AppTextField(
                label: 'Vehicle name',
                hint: 'e.g. Family SUV',
                controller: nameController,
                prefixIcon: Icons.directions_car_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Model',
                hint: 'e.g. Toyota Axio',
                controller: modelController,
                prefixIcon: Icons.badge_outlined,
                textInputAction: TextInputAction.next,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              AppTextField(
                label: 'Start odometer',
                hint: '0',
                controller: odometerController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.speed_outlined,
                suffixText: 'km',
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Fuel tank capacity',
                hint: '40',
                controller: tankController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.local_gas_station_outlined,
                suffixText: 'L',
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppToggleRow(
          title: 'Default vehicle',
          subtitle: 'Show this vehicle when the app opens',
          value: data.isDefault,
          onChanged: onDefaultChanged,
        ),
      ],
    );
  }
}
