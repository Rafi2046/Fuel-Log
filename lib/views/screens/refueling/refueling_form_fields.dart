import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toggle_row.dart';

/// Dynamic amount / cost / full-tank fields driven by [vehicle.isElectric].
class RefuelingFormFields extends StatelessWidget {
  const RefuelingFormFields({
    super.key,
    required this.vehicle,
    required this.odometerController,
    required this.amountController,
    required this.totalCostController,
    required this.noteController,
    required this.isFullTank,
    required this.onFullTankChanged,
    required this.pricePerUnit,
  });

  final Vehicle vehicle;
  final TextEditingController odometerController;
  final TextEditingController amountController;
  final TextEditingController totalCostController;
  final TextEditingController noteController;
  final bool isFullTank;
  final ValueChanged<bool> onFullTankChanged;
  final String? pricePerUnit;

  @override
  Widget build(BuildContext context) {
    final isEV = vehicle.isElectric;
    final amountLabel = isEV ? 'Charge Added' : 'Fuel Amount';
    final amountSuffix = isEV ? 'kWh' : 'Liters';
    final priceUnit = isEV ? 'kWh' : 'L';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEV ? 'Log Charge' : 'Log Refueling',
          style: AppTextStyles.display.copyWith(fontSize: 28),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${vehicle.name} · ${vehicle.fuelType}',
          style: AppTextStyles.bodySecondary,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Odometer',
                hint: 'e.g. 45000',
                controller: odometerController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.speed_rounded,
                suffixText: 'km',
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: amountLabel,
                hint: isEV ? 'e.g. 32.5' : 'e.g. 35.5',
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: isEV
                    ? Icons.battery_charging_full_rounded
                    : Icons.local_gas_station_rounded,
                suffixText: amountSuffix,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Total Cost',
                hint: 'e.g. 4500',
                controller: totalCostController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.payments_outlined,
                textInputAction: TextInputAction.next,
              ),
              if (pricePerUnit != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Price / $priceUnit: $pricePerUnit',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppToggleRow(
          title: isEV ? 'Full Charge (100%)?' : 'Full Tank?',
          subtitle: isEV
              ? 'Was the battery charged to full?'
              : 'Was the fuel tank filled completely?',
          value: isFullTank,
          onChanged: onFullTankChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: AppTextField(
            label: 'Note (Optional)',
            hint: 'Station, payment method, etc.',
            controller: noteController,
            prefixIcon: Icons.notes_rounded,
            maxLines: 3,
            textInputAction: TextInputAction.done,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
