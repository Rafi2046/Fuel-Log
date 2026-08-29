import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_toggle_row.dart';

/// Compact section with Full Tank toggle, Set Up Tank Level toggle,
/// slider controls, preset pills, and responsive overflow-safe estimation tiles.
class RefuelingTankLevelSection extends StatelessWidget {
  const RefuelingTankLevelSection({
    super.key,
    required this.isFullTank,
    required this.isSetupTankLevel,
    required this.tankCapacity,
    required this.beforeLevelPercent,
    required this.afterLevelPercent,
    required this.onFullTankChanged,
    required this.onSetupTankLevelChanged,
    required this.onBeforeLevelChanged,
    required this.onAfterLevelChanged,
    required this.isEV,
  });

  final bool isFullTank;
  final bool isSetupTankLevel;
  final double tankCapacity;
  final double beforeLevelPercent;
  final double afterLevelPercent;
  final ValueChanged<bool> onFullTankChanged;
  final ValueChanged<bool> onSetupTankLevelChanged;
  final ValueChanged<double> onBeforeLevelChanged;
  final ValueChanged<double> onAfterLevelChanged;
  final bool isEV;

  @override
  Widget build(BuildContext context) {
    final unit = isEV ? 'kwhUnit'.tr() : 'literUnit'.tr();
    final addedFuel = ((afterLevelPercent - beforeLevelPercent) / 100.0 * tankCapacity)
        .clamp(0.0, tankCapacity);
    final estimatedFuelAfter = ((afterLevelPercent / 100.0) * tankCapacity)
        .clamp(0.0, tankCapacity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Full Tank Toggle Row
        AppToggleRow(
          title: isEV ? 'refuelFullCharge'.tr() : 'refuelFullTank'.tr(),
          subtitle: isEV
              ? 'refuelFullChargeSubtitle'.tr()
              : 'refuelFullTankSubtitle'.tr(),
          value: isFullTank,
          onChanged: onFullTankChanged,
        ),
        const SizedBox(height: 10),

        // 2. Set Up Tank Level Toggle Row (Disabled when Full Tank is active)
        Opacity(
          opacity: isFullTank ? 0.45 : 1.0,
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'refuelSetupTankLevel'.tr(),
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (isFullTank) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isFullTank
                            ? 'refuelSetupTankDisabled'.tr()
                            : 'refuelSetupTankEnabled'.tr(),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.75,
                  child: Switch.adaptive(
                    value: isFullTank ? false : isSetupTankLevel,
                    activeThumbColor: AppColors.primary,
                    onChanged: isFullTank
                        ? null
                        : (val) => onSetupTankLevelChanged(val),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Expanded Fuel Level Sliders & Capacity Summary (when Set Up Tank Level is ON)
        if (!isFullTank && isSetupTankLevel) ...[
          const SizedBox(height: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        color: AppColors.textTertiary,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'refuelFuelLevelSection'.tr(),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Fuel Level BEFORE Slider
                  _LevelSliderWidget(
                    label: 'refuelBeforeRefueling'.tr(),
                    percent: beforeLevelPercent,
                    onChanged: onBeforeLevelChanged,
                    activeColor: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 10),

                  // Fuel Level AFTER Slider
                  _LevelSliderWidget(
                    label: 'refuelAfterRefueling'.tr(),
                    percent: afterLevelPercent,
                    onChanged: (val) {
                      if (val >= beforeLevelPercent) {
                        onAfterLevelChanged(val);
                      }
                    },
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 10),

                  // Responsive Overflow-Safe Estimation Grid
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cardElevated,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _EstimateStatTile(
                            label: 'refuelCapacity'.tr(),
                            value: '${tankCapacity.toStringAsFixed(0)} $unit',
                            icon: Icons.local_gas_station_rounded,
                          ),
                        ),
                        Container(width: 1, height: 24, color: AppColors.divider),
                        Expanded(
                          child: _EstimateStatTile(
                            label: 'refuelCalculated'.tr(),
                            value: '+${addedFuel.toStringAsFixed(1)} $unit',
                            icon: Icons.add_circle_outline_rounded,
                          ),
                        ),
                        Container(width: 1, height: 24, color: AppColors.divider),
                        Expanded(
                          child: _EstimateStatTile(
                            label: 'refuelEstRemaining'.tr(),
                            value: '${estimatedFuelAfter.toStringAsFixed(1)} $unit',
                            icon: Icons.battery_charging_full_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LevelSliderWidget extends StatelessWidget {
  const _LevelSliderWidget({
    required this.label,
    required this.percent,
    required this.onChanged,
    required this.activeColor,
  });

  final String label;
  final double percent;
  final ValueChanged<double> onChanged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${percent.round()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: activeColor,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: activeColor,
            inactiveTrackColor: AppColors.surface,
            thumbColor: activeColor,
            overlayColor: activeColor.withValues(alpha: 0.15),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: percent.clamp(0.0, 100.0),
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: onChanged,
          ),
        ),

        // Responsive Preset Pills
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [0.0, 25.0, 50.0, 75.0, 100.0].map((preset) {
            final isSelected = (percent - preset).abs() < 2.0;
            return GestureDetector(
              onTap: () => onChanged(preset),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.textSecondary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(
                    color: isSelected ? AppColors.textSecondary : AppColors.border,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  preset == 0
                      ? 'refuelTankEmpty'.tr()
                      : preset == 100
                          ? 'refuelTankFull'.tr()
                          : '${preset.round()}%',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textTertiary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _EstimateStatTile extends StatelessWidget {
  const _EstimateStatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            fontSize: 9,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 10,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
