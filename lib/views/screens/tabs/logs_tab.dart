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

import '../mileage/mileage_log_screen.dart';

/// Logs tab — real Drift fuel/charge entries for the active vehicle.
class LogsTab extends ConsumerWidget {
  const LogsTab({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('logsTitle'.tr()),
            backgroundColor: AppColors.background,
          ),
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
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // Top Mileage Log Banner Button
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MileageLogScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.cardElevated,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.speed_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mileage Log & Efficiency',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'View fuel efficiency, km/L stats & breakdown',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            ...logs.map((log) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Dismissible(
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
                      SnackBar(content: Text('logDeleted'.tr())),
                    );
                  },
                  child: _LogTile(log: log, unit: unit, isEV: isEV),
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
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isEV
                ? Icons.battery_charging_full_rounded
                : Icons.local_gas_station_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          AppDateFormats.formatLogDate(log.date),
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${log.amount.toStringAsFixed(1)} $unit • '
          '${log.odometer.toStringAsFixed(0)} km'
          '${log.isFullTank ? (isEV ? ' • ${'fullCharge'.tr()}' : ' • ${'fullTank'.tr()}') : ''}',
          style: AppTextStyles.caption,
        ),
        trailing: Text(
          AppCurrency.format(log.cost),
          style: AppTextStyles.title.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
