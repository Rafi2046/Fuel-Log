import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/database/app_database.dart';
import '../../../../../core/services/trip_category_prefs.dart';
import '../../../../../core/utils/app_formatters.dart';
import '../../../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../../../viewmodels/vehicle_viewmodel.dart';

/// Premium dark summary card for a recorded trip (GPS or Manual).
class TripSummaryCard extends ConsumerWidget {
  const TripSummaryCard({
    super.key,
    required this.trip,
    this.onTap,
  });

  final TripLog trip;
  final VoidCallback? onTap;

  static final _dateFormat = DateFormat('dd MMM yyyy • hh:mm a');

  int get _durationSec {
    if (trip.durationSec > 0) return trip.durationSec;
    final diff = trip.endedAt.difference(trip.startedAt).inSeconds;
    return diff > 0 ? diff : 0;
  }

  static String _formatDuration(int seconds) {
    if (seconds <= 0) return '—';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    if (m > 0) return '${m}m';
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = (trip.title != null && trip.title!.trim().isNotEmpty)
        ? trip.title!.trim()
        : 'manualTrip'.tr();

    final origin = (trip.origin != null && trip.origin!.trim().isNotEmpty)
        ? trip.origin!.trim()
        : 'tripOrigin'.tr();

    final destination =
        (trip.destination != null && trip.destination!.trim().isNotEmpty)
            ? trip.destination!.trim()
            : 'tripDestination'.tr();

    final formattedDate = _dateFormat.format(trip.startedAt);
    final distanceText = '${trip.distanceKm.toStringAsFixed(1)} ${'km'.tr()}';
    final durationSec = _durationSec;
    final durationText = _formatDuration(durationSec);

    String speedText = '—';
    if (durationSec > 0 && trip.distanceKm > 0) {
      final kmh = trip.distanceKm / (durationSec / 3600);
      speedText = '${kmh.toStringAsFixed(0)} km/h';
    }

    final vehicle = ref.watch(activeVehicleProvider).valueOrNull;
    final isEv = vehicle?.isElectric ?? false;
    final mileageUnit = isEv ? 'km/kWh' : 'km/L';

    final derivedCost = (trip.totalCost != null && trip.totalCost! > 0)
        ? trip.totalCost
        : (trip.costPerKm != null &&
                trip.costPerKm! > 0 &&
                trip.distanceKm > 0
            ? trip.costPerKm! * trip.distanceKm
            : null);
    final costText = derivedCost != null
        ? AppCurrency.format(derivedCost)
        : '৳ —';

    String mileageText = '—';
    final logs = ref.watch(vehicleLogsProvider).valueOrNull ?? const [];
    if (derivedCost != null && derivedCost > 0 && trip.distanceKm > 0) {
      FuelLog? latestPriced;
      for (final log in logs) {
        if (log.amount > 0 && log.cost > 0) {
          latestPriced = log;
          break;
        }
      }
      if (latestPriced != null) {
        final unitPrice = latestPriced.cost / latestPriced.amount;
        if (unitPrice > 0) {
          final unitsUsed = derivedCost / unitPrice;
          if (unitsUsed > 0) {
            mileageText =
                '${(trip.distanceKm / unitsUsed).toStringAsFixed(1)} $mileageUnit';
          }
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: const Color(0xFF2A2A32),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs + 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(
                        trip.source == 'gps'
                            ? LucideIcons.navigation
                            : LucideIcons.mapPin,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF24242E),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                        border: Border.all(
                          color: const Color(0xFF353542),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        TripCategoryPrefs.labelFor(trip.privacy).toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 1.5,
                          height: 22,
                          color: const Color(0xFF3E3E4D),
                          margin: const EdgeInsets.symmetric(vertical: 2),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            origin,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            destination,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(
                  color: Color(0xFF262630),
                  height: 1,
                  thickness: 1,
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.calendar,
                      size: 13,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      'tripStatCost'.tr(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      costText,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _TripStat(
                        label: 'tripStatDistance'.tr(),
                        value: distanceText,
                        emphasize: true,
                      ),
                    ),
                    Expanded(
                      child: _TripStat(
                        label: 'tripStatDuration'.tr(),
                        value: durationText,
                      ),
                    ),
                    Expanded(
                      child: _TripStat(
                        label: 'tripStatSpeed'.tr(),
                        value: speedText,
                      ),
                    ),
                    Expanded(
                      child: _TripStat(
                        label: 'tripStatMileage'.tr(),
                        value: mileageText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripStat extends StatelessWidget {
  const _TripStat({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(
            color: emphasize ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
