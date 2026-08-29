import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/list_lead_icon.dart';

import '../mileage/mileage_log_screen.dart';
import '../mileage/widgets/fuel_log_detail_sheet.dart';

/// Logs tab — real Drift fuel/charge entries for the active vehicle.
class LogsTab extends ConsumerWidget {
  const LogsTab({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AppScaffold(
          title: 'logsTitle'.tr(),
          body: const LogsTab(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(vehicleLogsProvider);
    final vehicleAsync = ref.watch(activeVehicleProvider);
    final isEV = vehicleAsync.valueOrNull?.isElectric ?? false;
    final unit = isEV ? 'kWh' : 'L';

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('errorPrefix'.tr(namedArgs: {'error': '$e'})),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'noFuelLogsFound'.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary,
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            AppSpacing.sm,
          ),
          children: [
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.listCardPaddingH,
                vertical: AppSpacing.listCardPaddingV,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MileageLogScreen(),
                  ),
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const ListLeadIcon(icon: Icons.speed_rounded),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mileage Log & Efficiency',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'View fuel efficiency, km/L stats & breakdown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.listGap),

            ...logs.map((log) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.listGap),
                child: Dismissible(
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
                      size: 28,
                    ),
                  ),
                  onDismissed: (_) async {
                    await ref.read(fuelLogProvider.notifier).deleteFuelLog(log.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('logDeleted'.tr())),
                    );
                  },
                  child: GestureDetector(
                    onTap: () => FuelLogDetailSheet.show(
                      context,
                      log: log,
                      unit: unit,
                      isEV: isEV,
                    ),
                    behavior: HitTestBehavior.opaque,
                    child: _LogTile(log: log, unit: unit, isEV: isEV),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({
    required this.log,
    required this.unit,
    required this.isEV,
  });

  final FuelLog log;
  final String unit;
  final bool isEV;

  @override
  Widget build(BuildContext context) {
    final station = log.stationName?.trim();

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.listCardPaddingH,
        vertical: AppSpacing.listCardPaddingV,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ListLeadIcon(
            icon: isEV
                ? Icons.battery_charging_full_rounded
                : Icons.local_gas_station_rounded,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppDateFormats.formatLogDate(log.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${log.amount.toStringAsFixed(1)} $unit • '
                  '${log.odometer.toStringAsFixed(0)} km'
                  '${log.isFullTank ? (isEV ? ' • ${'fullCharge'.tr()}' : ' • ${'fullTank'.tr()}') : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
                if (station != null && station.isNotEmpty)
                  Text(
                    station,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
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
    );
  }
}
