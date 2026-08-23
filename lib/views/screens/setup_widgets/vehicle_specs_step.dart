import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/fuel_options.dart';
import 'vehicle_identity_step.dart';

/// Step 2 — odometer, fuel/energy type, capacity with grouped luxury styling.
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
    final capacitySuffix = isEV ? 'kWh' : 'L';
    final capacityHint = isEV ? 'e.g. 40' : 'e.g. 40';
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
            style: AppTextStyles.headline.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEV
                ? 'Odometer and battery details for analytics.'
                : 'Odometer and fuel details for analytics.',
            style: AppTextStyles.bodySecondary.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Grouped Specs Container
          Text(
            'STARTING METRICS',
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
                // 1. Odometer
                _SpecsInputRow(
                  label: 'Start Odometer',
                  hint: '0',
                  controller: odometerController,
                  icon: Icons.speed_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  unitBadge: 'KM',
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border.withValues(alpha: 0.6),
                  indent: 64,
                ),
                // 2. Fuel Type Dropdown
                _SpecsDropdownRow(
                  label: 'Fuel Type',
                  value: selectedFuelType,
                  items: fuelTypes,
                  icon: isEV
                      ? Icons.ev_station_rounded
                      : Icons.local_gas_station_rounded,
                  onChanged: onFuelTypeChanged,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border.withValues(alpha: 0.6),
                  indent: 64,
                ),
                // 3. Tank / Battery Capacity
                _SpecsInputRow(
                  label: capacityLabel,
                  hint: capacityHint,
                  controller: capacityController,
                  icon: capacityIcon,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  unitBadge: capacitySuffix,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Helper info callout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_graph_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Starting odometer and capacity calibrate your fuel economy, range calculations, and cost per km.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
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

class _SpecsInputRow extends StatelessWidget {
  const _SpecsInputRow({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    required this.unitBadge,
    this.textInputAction = TextInputAction.next,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final String unitBadge;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

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
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              unitBadge,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecsDropdownRow extends StatelessWidget {
  const _SpecsDropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isDense: true,
                    dropdownColor: AppColors.cardElevated,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    items: items
                        .map(
                          (t) => DropdownMenuItem<String>(
                            value: t,
                            child: Text(
                              t,
                              style: AppTextStyles.body.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onChanged,
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
