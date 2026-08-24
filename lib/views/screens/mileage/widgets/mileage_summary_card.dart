import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../models/mileage_entry_model.dart';
import '../../../../viewmodels/mileage_log_viewmodel.dart';

/// Glassmorphic hero summary card showing overall vehicle efficiency and unit selector.
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle gradient glow
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Label & Unit Switcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(
                            Icons.speed_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Average Mileage',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    _UnitSegmentedControl(
                      selectedUnit: selectedUnit,
                      onUnitChanged: (unit) {
                        ref.read(selectedEfficiencyUnitProvider.notifier).state = unit;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Hero Number
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formattedMain,
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      selectedUnit.label,
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: AppSpacing.md),

                // Bottom Sub-Stats Grid
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
                    Container(width: 1, height: 32, color: AppColors.divider),
                    Expanded(
                      child: _SubStatTile(
                        icon: Icons.payments_outlined,
                        label: 'Avg Cost/km',
                        value: summary.avgCostPerKm > 0
                            ? '${AppCurrency.format(summary.avgCostPerKm)}/km'
                            : '--',
                      ),
                    ),
                    Container(width: 1, height: 32, color: AppColors.divider),
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
          ),
        ],
      ),
    );
  }
}

class _UnitSegmentedControl extends StatelessWidget {
  const _UnitSegmentedControl({
    required this.selectedUnit,
    required this.onUnitChanged,
  });

  final EfficiencyUnit selectedUnit;
  final ValueChanged<EfficiencyUnit> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                unit.label,
                style: TextStyle(
                  fontSize: 11,
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
  const _SubStatTile({
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
            Icon(icon, size: 13, color: AppColors.textTertiary),
            const SizedBox(width: 3),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
