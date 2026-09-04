import 'package:easy_localization/easy_localization.dart';
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
import 'fuel_log_detail_sheet.dart';

/// Compact mileage history row — no lead icon, tight 2–3 line layout.
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

  String _formatKm(double km) => NumberFormat('#,###').format(km.round());

  String _formatUnitPrice(double price) {
    if (price <= 0) return '';
    if (price >= 100) return AppCurrency.format(price);
    return '৳ ${price.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedUnit = ref.watch(selectedEfficiencyUnitProvider);
    final log = entry.log;

    final formattedEfficiency = entry.formatEfficiency(selectedUnit);
    final efficiencyVal = entry.getEfficiencyValue(selectedUnit);

    Color badgeColor = AppColors.primary;
    if (efficiencyVal != null) {
      if (selectedUnit == EfficiencyUnit.l100km) {
        badgeColor =
            efficiencyVal <= 7.5 ? AppColors.success : AppColors.warning;
      } else {
        badgeColor =
            efficiencyVal >= 12.0 ? AppColors.success : AppColors.warning;
      }
    }

    final pricePerUnit = log.amount > 0 ? (log.cost / log.amount) : 0.0;
    final station = log.stationName?.trim();
    // Ignore placeholder / single-char station labels from seed data.
    final hasStation =
        station != null && station.length > 1;
    final distance = entry.distanceDriven;

    final metaParts = <String>[
      '${log.amount.toStringAsFixed(1)} $unit',
      if (pricePerUnit > 0) '${_formatUnitPrice(pricePerUnit)}/$unit',
      '${_formatKm(log.odometer)} km',
      if (distance != null) '+${_formatKm(distance)} km',
      if (hasStation) station,
    ];

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      AppCurrency.format(log.cost),
                      maxLines: 1,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  _EfficiencyBadge(
                    label: formattedEfficiency,
                    color: badgeColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      metaParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EfficiencyBadge extends StatelessWidget {
  const _EfficiencyBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
