import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../widgets/app_card.dart';
import '../../widgets/clean_glass_panel.dart';
import '../../widgets/app_text_field.dart';
import 'widgets/refueling_cost_section.dart';
import 'widgets/refueling_odometer_section.dart';
import 'widgets/refueling_tank_level_section.dart';

/// Compact, ultra-sleek refueling form layout.
class RefuelingFormFields extends StatelessWidget {
  const RefuelingFormFields({
    super.key,
    required this.vehicle,
    required this.odometerController,
    required this.tripOdometerController,
    required this.odometerFocus,
    required this.tripFocus,
    required this.amountController,
    required this.pricePerUnitController,
    required this.totalCostController,
    required this.noteController,
    required this.lastOdometer,
    required this.isFullTank,
    required this.isSetupTankLevel,
    required this.beforeLevelPercent,
    required this.afterLevelPercent,
    required this.onOdometerEditingComplete,
    required this.onTripEditingComplete,
    required this.onOdometerChanged,
    required this.onAmountChanged,
    required this.onPriceChanged,
    required this.onTotalCostChanged,
    required this.onFullTankChanged,
    required this.onSetupTankLevelChanged,
    required this.onBeforeLevelChanged,
    required this.onAfterLevelChanged,
    this.onScanReceipt,
    this.isScanning = false,
  });

  final Vehicle vehicle;
  final TextEditingController odometerController;
  final TextEditingController tripOdometerController;
  final FocusNode odometerFocus;
  final FocusNode tripFocus;
  final TextEditingController amountController;
  final TextEditingController pricePerUnitController;
  final TextEditingController totalCostController;
  final TextEditingController noteController;
  final double? lastOdometer;
  final bool isFullTank;
  final bool isSetupTankLevel;
  final double beforeLevelPercent;
  final double afterLevelPercent;
  final VoidCallback? onScanReceipt;
  final bool isScanning;

  final VoidCallback onOdometerEditingComplete;
  final VoidCallback onTripEditingComplete;
  final VoidCallback onOdometerChanged;
  final VoidCallback onAmountChanged;
  final VoidCallback onPriceChanged;
  final VoidCallback onTotalCostChanged;
  final ValueChanged<bool> onFullTankChanged;
  final ValueChanged<bool> onSetupTankLevelChanged;
  final ValueChanged<double> onBeforeLevelChanged;
  final ValueChanged<double> onAfterLevelChanged;

  @override
  Widget build(BuildContext context) {
    final isEV = vehicle.isElectric;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sleek Thin Vehicle Info Bar
        CleanGlassPanel(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                isEV
                    ? Icons.bolt_rounded
                    : Icons.directions_car_filled_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      vehicle.name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${vehicle.fuelType} • ${vehicle.capacity.toStringAsFixed(0)} ${isEV ? "kWh" : "L"}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  isEV ? 'EV' : 'Fuel',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Section 1: Odometer & Trip Distance
        RefuelingOdometerSection(
          odometerController: odometerController,
          tripOdometerController: tripOdometerController,
          odometerFocus: odometerFocus,
          tripFocus: tripFocus,
          lastOdometer: lastOdometer,
          onOdometerEditingComplete: onOdometerEditingComplete,
          onTripEditingComplete: onTripEditingComplete,
          onOdometerChanged: onOdometerChanged,
        ),
        const SizedBox(height: 10),

        // Section 2: Fuel Amount, Price/Unit, Total Cost
        RefuelingCostSection(
          amountController: amountController,
          pricePerUnitController: pricePerUnitController,
          totalCostController: totalCostController,
          isEV: isEV,
          onAmountChanged: onAmountChanged,
          onPriceChanged: onPriceChanged,
          onTotalCostChanged: onTotalCostChanged,
          onScanReceipt: onScanReceipt,
          isScanning: isScanning,
        ),
        const SizedBox(height: 10),

        // Section 3: Dual Tank Toggles, Sliders, and Capacity Estimates
        RefuelingTankLevelSection(
          isFullTank: isFullTank,
          isSetupTankLevel: isSetupTankLevel,
          tankCapacity: vehicle.capacity > 0 ? vehicle.capacity : 50.0,
          beforeLevelPercent: beforeLevelPercent,
          afterLevelPercent: afterLevelPercent,
          onFullTankChanged: onFullTankChanged,
          onSetupTankLevelChanged: onSetupTankLevelChanged,
          onBeforeLevelChanged: onBeforeLevelChanged,
          onAfterLevelChanged: onAfterLevelChanged,
          isEV: isEV,
        ),
        const SizedBox(height: 10),

        // Section 4: Optional Note
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.textTertiary,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Notes (Optional)',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppTextField(
                label: 'Note',
                hint: 'Station name, payment method, discount, etc.',
                controller: noteController,
                prefixIcon: Icons.notes_rounded,
                dense: true,
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
