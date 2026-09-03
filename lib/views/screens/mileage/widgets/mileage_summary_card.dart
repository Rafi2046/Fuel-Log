import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../models/mileage_entry_model.dart';
import '../../../../viewmodels/mileage_log_viewmodel.dart';
import '../../../widgets/app_card.dart';

/// Compact summary card showing overall vehicle efficiency and unit selector.
class MileageSummaryCard extends ConsumerWidget {
  const MileageSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(mileageSummaryProvider);
    final selectedUnit = ref.watch(selectedEfficiencyUnitProvider);

    double mainVal = 0.0;
    switch (selectedUnit) {
      case EfficiencyUnit.kmPerLitre:
        mainVal = summary.avgKmPerLitre;
        break;
      case EfficiencyUnit.l100km:
        mainVal = summary.avgL100km;
        break;
      case EfficiencyUnit.mpg:
        mainVal = summary.avgMpg;
        break;
    }

    final formattedMain = mainVal > 0 ? mainVal.toStringAsFixed(1) : '--';

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.listCardPaddingH,
        vertical: AppSpacing.listCardPaddingV,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  Icons.speed_rounded,
                  color: AppColors.primary,
                  size: 14,
                ),
              ),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Average Mileage',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: _UnitSegmentedControl(
              selectedUnit: selectedUnit,
              onUnitChanged: (unit) {
                ref.read(selectedEfficiencyUnitProvider.notifier).state = unit;
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formattedMain,
                style: AppTextStyles.headline.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  height: 1.1,
                ),
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                selectedUnit.label,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _SubStatTile(
                  icon: Icons.add_road_rounded,
                  label: 'Total Distance',
                  value: summary.totalDistanceDriven > 0
                      ? '${summary.totalDistanceDriven.toStringAsFixed(0)} km'
                      : '--',
                ),
              ),
              Container(width: 1, height: 28, color: AppColors.divider),
              Expanded(
                child: _SubStatTile(
                  icon: Icons.payments_outlined,
                  label: 'Avg Cost/km',
                  value: summary.avgCostPerKm > 0
                      ? '${AppCurrency.format(summary.avgCostPerKm)}/km'
                      : '--',
                ),
              ),
              Container(width: 1, height: 28, color: AppColors.divider),
              Expanded(
                child: _SubStatTile(
                  icon: Icons.local_gas_station_outlined,
                  label: 'Total Fuel',
                  value: summary.totalFuelAmount > 0
                      ? '${summary.totalFuelAmount.toStringAsFixed(0)} L'
                      : '--',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnitSegmentedControl extends StatelessWidget {
  _UnitSegmentedControl({
    required this.selectedUnit,
    required this.onUnitChanged,
  });

  final EfficiencyUnit selectedUnit;
  final ValueChanged<EfficiencyUnit> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: EfficiencyUnit.values.map((unit) {
          final isSelected = unit == selectedUnit;
          return GestureDetector(
            onTap: () => onUnitChanged(unit),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                unit.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textTertiary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SubStatTile extends StatelessWidget {
  _SubStatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 11, color: AppColors.textTertiary),
            SizedBox(width: 2),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 9,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
