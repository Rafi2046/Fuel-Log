import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_text_field.dart';

/// Compact Fuel Amount, Unit Price, and Total Cost section.
class RefuelingCostSection extends StatelessWidget {
  const RefuelingCostSection({
    super.key,
    required this.amountController,
    required this.pricePerUnitController,
    required this.totalCostController,
    required this.isEV,
    required this.onAmountChanged,
    required this.onPriceChanged,
    required this.onTotalCostChanged,
  });

  final TextEditingController amountController;
  final TextEditingController pricePerUnitController;
  final TextEditingController totalCostController;
  final bool isEV;
  final VoidCallback onAmountChanged;
  final VoidCallback onPriceChanged;
  final VoidCallback onTotalCostChanged;

  @override
  Widget build(BuildContext context) {
    final amountLabel = isEV ? 'Charge' : 'Gas / Fuel';
    final unitSuffix = isEV ? 'kWh' : 'L';

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isEV
                    ? Icons.battery_charging_full_rounded
                    : Icons.local_gas_station_outlined,
                color: AppColors.textTertiary,
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                'Fuel & Expense Details',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: amountLabel,
                  hint: '0.0',
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: isEV
                      ? Icons.battery_charging_full_rounded
                      : Icons.local_gas_station_rounded,
                  suffixText: unitSuffix,
                  onChanged: (_) => onAmountChanged(),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  label: 'Price / $unitSuffix',
                  hint: '0.0',
                  controller: pricePerUnitController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.sell_outlined,
                  onChanged: (_) => onPriceChanged(),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppTextField(
            label: 'Total Cost',
            hint: 'e.g. 5000',
            controller: totalCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.payments_outlined,
            onChanged: (_) => onTotalCostChanged(),
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }
}
