import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/fuel_options.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dropdown_field.dart';
import '../../widgets/app_text_field.dart';
import 'vehicle_identity_step.dart';

/// Step 2 — odometer, fuel/energy type, capacity (tank or battery).
class VehicleSpecsStep extends StatelessWidget {
  const VehicleSpecsStep({
    super.key,
    required this.vehicleType,
    required this.odometerController,
    required this.capacityController,
    required this.selectedFuelType,
    required this.onFuelTypeChanged,
  });

  final VehicleType vehicleType;
  final TextEditingController odometerController;
  final TextEditingController capacityController;
  final String selectedFuelType;
  final ValueChanged<String?> onFuelTypeChanged;

  @override
  Widget build(BuildContext context) {
    final fuelTypes = FuelOptions.forVehicleType(vehicleType);
    final isEV = FuelOptions.isElectric(selectedFuelType);
    final capacityLabel = isEV ? 'Battery Capacity' : 'Tank Capacity';
    final capacitySuffix = isEV ? 'kWh' : 'Liters';
    final capacityHint = isEV ? '40' : '40';
    final capacityIcon =
        isEV ? Icons.battery_charging_full_rounded : Icons.opacity_rounded;

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
            isEV ? 'Odometer and battery details.' : 'Odometer and fuel details.',
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
                  prefixIcon: isEV
                      ? Icons.ev_station_rounded
                      : Icons.local_gas_station_rounded,
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
                  label: capacityLabel,
                  hint: capacityHint,
                  controller: capacityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: capacityIcon,
                  suffixText: capacitySuffix,
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
