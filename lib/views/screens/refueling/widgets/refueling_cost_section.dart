import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
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
    this.onScanReceipt,
    this.isScanning = false,
  });

  final TextEditingController amountController;
  final TextEditingController pricePerUnitController;
  final TextEditingController totalCostController;
  final bool isEV;
  final VoidCallback onAmountChanged;
  final VoidCallback onPriceChanged;
  final VoidCallback onTotalCostChanged;
  final VoidCallback? onScanReceipt;
  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    final amountLabel =
        isEV ? 'refuelChargeAmount'.tr() : 'refuelGasFuel'.tr();
    final unitSuffix = isEV ? 'kwhUnit'.tr() : 'literUnit'.tr();

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
                'refuelFuelExpenseSection'.tr(),
                style: AppTextStyles.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (onScanReceipt != null)
                Material(
                  color: AppColors.border.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: InkWell(
                    onTap: isScanning ? null : onScanReceipt,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isScanning)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: AppColors.textSecondary,
                              ),
                            )
                          else
                            const Icon(
                              Icons.document_scanner_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          const SizedBox(width: 5),
                          Text(
                            isScanning ? 'refuelScanning'.tr() : 'refuelScanReceipt'.tr(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: amountLabel,
                  hint: '0.0',
                  controller: amountController,
                  dense: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
                  label: 'refuelPricePerUnit'.tr(namedArgs: {'unit': unitSuffix}),
                  hint: '0.0',
                  controller: pricePerUnitController,
                  dense: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.sell_outlined,
                  onChanged: (_) => onPriceChanged(),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppTextField(
            label: 'refuelTotalCost'.tr(),
            hint: 'refuelTotalCostHint'.tr(),
            controller: totalCostController,
            dense: true,
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
