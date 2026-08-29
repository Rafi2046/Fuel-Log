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
import '../../../widgets/list_lead_icon.dart';
import 'fuel_log_detail_sheet.dart';

/// Compact card for a calculated mileage log entry with swipe-to-delete.
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

  static const _cardPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.listCardPaddingH,
    vertical: AppSpacing.listCardPaddingV,
  );

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
    final station = log.stationName?.trim();

    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {
        DismissDirection.endToStart: 0.35,
      },
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
          size: 24,
        ),
      ),
      onDismissed: (_) async {
        await ref.read(fuelLogProvider.notifier).deleteFuelLog(log.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log deleted successfully')),
        );
      },
      child: GestureDetector(
        onTap: () => FuelLogDetailSheet.show(
          context,
          log: log,
          unit: unit,
          isEV: isEV,
          entry: entry,
        ),
        behavior: HitTestBehavior.opaque,
        child: AppCard(
          padding: _cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ListLeadIcon(
                icon: isEV
                    ? Icons.battery_charging_full_rounded
                    : Icons.local_gas_station_rounded,
                iconSize: 14,
                padding: 5,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppDateFormats.formatLogDate(log.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.speed_rounded, size: 11, color: badgeColor),
                            const SizedBox(width: 3),
                            Text(
                              formattedEfficiency,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${log.amount.toStringAsFixed(1)} $unit'
                    '${pricePerUnit > 0 ? ' @ ${AppCurrency.format(pricePerUnit)}/$unit' : ''}'
                    ' • ${log.odometer.toStringAsFixed(0)} km'
                    '${entry.distanceDriven != null ? ' • +${entry.distanceDriven!.toStringAsFixed(0)} km' : ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                  if (station != null && station.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        station,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppCurrency.format(log.cost),
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
