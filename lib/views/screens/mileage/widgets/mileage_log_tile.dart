import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../models/mileage_entry_model.dart';
import '../../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../../viewmodels/mileage_log_viewmodel.dart';
import '../../../widgets/app_card.dart';

/// Card item presenting a calculated mileage log entry with swipe-to-delete support.
class MileageLogTile extends ConsumerWidget {
  const MileageLogTile({
    super.key,
    required this.entry,
    required this.unit,
    required this.isEV,
  });

  final MileageEntryModel entry;
  final String unit;
  final bool isEV;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedUnit = ref.watch(selectedEfficiencyUnitProvider);
    final log = entry.log;

    final formattedEfficiency = entry.formatEfficiency(selectedUnit);
    final efficiencyVal = entry.getEfficiencyValue(selectedUnit);

    Color badgeColor = AppColors.primary;
    if (efficiencyVal != null) {
      if (selectedUnit == EfficiencyUnit.l100km) {
        badgeColor = efficiencyVal <= 7.5 ? AppColors.success : AppColors.warning;
      } else {
        badgeColor = efficiencyVal >= 12.0 ? AppColors.success : AppColors.warning;
      }
    }

    final pricePerUnit = log.amount > 0 ? (log.cost / log.amount) : 0.0;

    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (_) async {
        await ref.read(fuelLogProvider.notifier).deleteFuelLog(log.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log deleted successfully')),
        );
      },
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Date & Efficiency Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isEV
                          ? Icons.battery_charging_full_rounded
                          : Icons.local_gas_station_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      AppDateFormats.formatLogDate(log.date),
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed_rounded, size: 13, color: badgeColor),
                      const SizedBox(width: 4),
                      Text(
                        formattedEfficiency,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Middle Row: Distance Driven & Fuel details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${log.amount.toStringAsFixed(1)} $unit',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (pricePerUnit > 0)
                          Text(
                            ' @ ${AppCurrency.format(pricePerUnit)}/$unit',
                            style: AppTextStyles.caption,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Odometer: ${log.odometer.toStringAsFixed(0)} km',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppCurrency.format(log.cost),
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (entry.distanceDriven != null)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cardElevated,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: AppColors.border, width: 0.8),
                        ),
                        child: Text(
                          '+${entry.distanceDriven!.toStringAsFixed(0)} km',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Bottom tags: Full Tank & Notes
            if (log.isFullTank || (log.note != null && log.note!.isNotEmpty)) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: log.isFullTank
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.isFullTank ? 'Full Tank' : 'Partial Tank',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: log.isFullTank ? AppColors.primary : AppColors.warning,
                      ),
                    ),
                  ),
                  if (log.note != null && log.note!.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        log.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
