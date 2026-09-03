import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/utils/mileage_calculator.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/service_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../../viewmodels/weather_viewmodel.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_shimmer.dart';
import '../../widgets/cost_per_km_detail_sheet.dart';
import '../../widgets/efficiency_gauge.dart';
import '../../widgets/home_metrics_cards.dart';
import '../../widgets/home_quick_action_cards.dart';
import '../../widgets/list_lead_icon.dart';
import '../../widgets/vehicle_vitals_detail_sheet.dart';
import '../../widgets/weather_drive_card.dart';
import '../mileage/mileage_log_screen.dart';
import '../mileage/widgets/fuel_log_detail_sheet.dart';
import '../refueling_form_screen.dart';
import '../services/services_screen.dart';
import '../services/widgets/add_cost_service_sheet.dart';
import 'dashboard_bottom_bar.dart';
import 'logs_tab.dart';

/// Home tab — compact overview (gauge, key metrics grid, vitals, services, recent log).
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(vehicleLogsProvider);
    final serviceLogsAsync = ref.watch(serviceLogsProvider);
    final vehicleAsync = ref.watch(activeVehicleProvider);
    final vehicle = vehicleAsync.valueOrNull;
    final isEV = vehicle?.isElectric ?? false;
    final unit = isEV ? 'kWh' : 'L';
    final mileageUnit = isEV ? 'km/kWh' : 'km/L';
    if (logsAsync.isLoading && !logsAsync.hasValue) {
      return const HomeTabSkeleton();
    }
    if (logsAsync.hasError && !logsAsync.hasValue) {
      return Center(
        child: Text('errorPrefix'.tr(namedArgs: {'error': '${logsAsync.error}'})),
      );
    }

    final logs = logsAsync.valueOrNull ?? [];
    final serviceLogs = serviceLogsAsync.valueOrNull ?? [];

    return AppRefreshIndicator(
      onRefresh: () async {
        ref.invalidate(vehicleLogsProvider);
        ref.invalidate(serviceLogsProvider);
        await ref.read(weatherAdviceProvider.notifier).refresh();
        await Future.delayed(const Duration(milliseconds: 300));
      },
      child: _HomeContent(
        logs: logs,
        serviceLogs: serviceLogs,
        vehicle: vehicle,
        isEV: isEV,
        unit: unit,
        mileageUnit: mileageUnit,
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.logs,
    required this.serviceLogs,
    required this.vehicle,
    required this.isEV,
    required this.unit,
    required this.mileageUnit,
  });

  final List<FuelLog> logs;
  final List<ServiceLog> serviceLogs;
  final Vehicle? vehicle;
  final bool isEV;
  final String unit;
  final String mileageUnit;

  @override
  Widget build(BuildContext context) {
    final recent = logs.isEmpty ? null : logs.first;
    final avgMileage = calculateAverageMileage(logs);

    final totalFuelSpend = logs.fold<double>(0, (sum, l) => sum + l.cost);
    final totalServiceSpend =
        serviceLogs.fold<double>(0, (sum, s) => sum + s.cost);
    final totalFuelConsumed =
        logs.fold<double>(0, (sum, l) => sum + l.amount);

    double totalDistance = 0.0;
    double lastMileage = 0.0;

    if (logs.length >= 2) {
      final sorted = List<FuelLog>.from(logs)
        ..sort((a, b) => a.odometer.compareTo(b.odometer));
      totalDistance =
          (sorted.last.odometer - sorted.first.odometer).clamp(0, double.infinity);
      final deltaDist = sorted.last.odometer - sorted[sorted.length - 2].odometer;
      final deltaFuel = sorted.last.amount;
      if (deltaDist > 0 && deltaFuel > 0) {
        lastMileage = deltaDist / deltaFuel;
      }
    } else if (logs.length == 1 &&
        vehicle != null &&
        logs.first.odometer > vehicle!.startOdo) {
      totalDistance =
          (logs.first.odometer - vehicle!.startOdo).clamp(0, double.infinity);
    }

    final totalSpend = totalFuelSpend + totalServiceSpend;
    final costPerKm = totalDistance > 0 ? (totalSpend / totalDistance) : 0.0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.appBarBodyGap,
        AppSpacing.screenPadding,
        DashboardBottomBar.contentBottomInset(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MileageLogScreen(),
                  ),
                );
              },
              child: EfficiencyGauge(
                value: avgMileage,
                unit: mileageUnit,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const WeatherDriveCard(),
          const SizedBox(height: AppSpacing.md),
          HomeKeyMetricsGrid(
            avgMileage: avgMileage,
            totalFuelSpend: totalFuelSpend,
            totalServiceSpend: totalServiceSpend,
            costPerKm: costPerKm,
            mileageUnit: mileageUnit,
            isEV: isEV,
            onTapMileage: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MileageLogScreen(),
                ),
              );
            },
            onTapFuelSpend: () {
              LogsTab.open(context);
            },
            onTapServiceSpend: () {
              ServicesScreen.open(context);
            },
            onTapCostPerKm: () {
              CostPerKmDetailSheet.show(
                context,
                vehicle: vehicle,
                costPerKm: costPerKm,
                totalFuelSpend: totalFuelSpend,
                totalServiceSpend: totalServiceSpend,
                totalDistance: totalDistance,
                isEV: isEV,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          HomeVehicleVitalsCard(
            totalDistance: totalDistance,
            totalFuelConsumed: totalFuelConsumed,
            recentLog: recent,
            lastMileage: lastMileage,
            unit: unit,
            mileageUnit: mileageUnit,
            isEV: isEV,
            onTap: () {
              VehicleVitalsDetailSheet.show(
                context,
                vehicle: vehicle,
                totalDistance: totalDistance,
                totalFuelConsumed: totalFuelConsumed,
                avgMileage: avgMileage,
                lastMileage: lastMileage,
                recentLog: recent,
                logsCount: logs.length,
                unit: unit,
                mileageUnit: mileageUnit,
                isEV: isEV,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          HomeQuickActionCards(
            isEV: isEV,
            onTapAddFuel: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RefuelingFormScreen(),
                ),
              );
            },
            onTapAddService: () {
              if (vehicle != null) {
                final currentOdo = recent?.odometer ?? vehicle!.startOdo;
                AddCostServiceSheet.show(
                  context,
                  vehicleId: vehicle!.id,
                  currentOdometer: currentOdo,
                );
              } else {
                ServicesScreen.open(context);
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  isEV ? 'recentCharge'.tr() : 'recentRefueling'.tr(),
                  style: AppTextStyles.label.copyWith(fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () => LogsTab.open(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'viewAll'.tr(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (recent == null)
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.listCardPaddingH,
                vertical: AppSpacing.listCardPaddingV,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RefuelingFormScreen(),
                  ),
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ListLeadIcon(
                    icon: isEV
                        ? LucideIcons.batteryCharging
                        : LucideIcons.fuel,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEV
                              ? 'addFirstChargeTitle'.tr()
                              : 'addFirstRefuelTitle'.tr(),
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEV
                              ? 'addFirstChargeSubtitle'.tr()
                              : 'addFirstRefuelSubtitle'.tr(),
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2A2A3C),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.plus,
                      size: 14,
                      color: Color(0xFFA1A1AA),
                    ),
                  ),
                ],
              ),
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.listCardPaddingH,
                vertical: AppSpacing.listCardPaddingV,
              ),
              onTap: () => FuelLogDetailSheet.show(
                context,
                log: recent,
                unit: unit,
                isEV: isEV,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ListLeadIcon(
                    icon: isEV
                        ? LucideIcons.batteryCharging
                        : LucideIcons.fuel,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vehicle?.name ?? 'Vehicle'} • '
                          '${recent.amount.toStringAsFixed(1)} $unit',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${AppDateFormats.formatLogDate(recent.date)} • '
                          '${recent.odometer.toStringAsFixed(0)} km',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    AppCurrency.format(recent.cost),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


