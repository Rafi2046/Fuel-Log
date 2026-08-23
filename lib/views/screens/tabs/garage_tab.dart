import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/app_outline_button.dart';
import '../vehicle_setup_screen.dart';
import 'garage_vehicle_card.dart';

/// Soft cap — free tier allows up to this many vehicles.
const int kMaxVehicles = 3;

/// Garage tab listing vehicles with an Add Vehicle button.
class GarageTab extends ConsumerWidget {
  const GarageTab({super.key});

  /// Car vs bike icon from saved [Vehicle.type] (and light name fallback).
  IconData _iconFor(Vehicle vehicle) {
    if (_isBike(vehicle)) return Icons.two_wheeler_rounded;
    return Icons.directions_car_filled_rounded;
  }

  bool _isBike(Vehicle vehicle) {
    final type = vehicle.type.toLowerCase().trim();
    if (type == 'bike' ||
        type.contains('bike') ||
        type.contains('motorcycle') ||
        type.contains('scooter')) {
      return true;
    }
    final name = vehicle.name.toLowerCase();
    // Fallback for older rows that may have wrong type.
    if (name.contains('bike') ||
        name.contains('r15') ||
        name.contains('scooter') ||
        name.contains('motorcycle')) {
      return true;
    }
    return false;
  }

  String _typeLabel(Vehicle vehicle) =>
      _isBike(vehicle) ? 'vehicleTypeBike'.tr() : 'vehicleTypeCar'.tr();

  String _subtitle(Vehicle vehicle) {
    final parts = <String>[
      _typeLabel(vehicle),
      if (vehicle.model != null && vehicle.model!.trim().isNotEmpty)
        vehicle.model!.trim(),
      vehicle.fuelType,
      _odometerLabel(vehicle.startOdo),
    ];
    return parts.join(' • ');
  }

  String _odometerLabel(double km) {
    final formatted = NumberFormat('#,###').format(km.round());
    return '$formatted km';
  }

  Future<void> _onAddPressed(BuildContext context, int count) async {
    if (count >= kMaxVehicles) {
      await showVehicleLimitDialog(context);
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const VehicleSetupScreen(),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.card,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 26,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'deleteVehicleTitle'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'deleteVehicleMessage'.tr(
                    namedArgs: {'name': vehicle.name},
                  ),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary.copyWith(
                    height: 1.4,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.borderStrong),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm + 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                        child: Text('cancel'.tr()),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm + 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                        child: Text('delete'.tr()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    final ok =
        await ref.read(vehicleProvider.notifier).deleteVehicle(vehicle.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'vehicleDeleted'.tr() : 'vehicleDeleteFailed'.tr(),
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.cardElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return vehiclesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('errorPrefix'.tr(namedArgs: {'error': '$e'})),
      ),
      data: (vehicles) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            if (vehicles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Column(
                  children: [
                    Icon(
                      Icons.garage_outlined,
                      size: 40,
                      color: AppColors.textTertiary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'garageEmpty'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              )
            else
              for (var i = 0; i < vehicles.length; i++) ...[
                Dismissible(
                  key: ValueKey('vehicle_${vehicles[i].id}'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await _confirmDelete(context, ref, vehicles[i]);
                    // Deletion happens inside confirm; keep row if cancelled.
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.18),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                  ),
                  child: GarageVehicleCard(
                    name: vehicles[i].name,
                    subtitle: _subtitle(vehicles[i]),
                    icon: _iconFor(vehicles[i]),
                    onDelete: () =>
                        _confirmDelete(context, ref, vehicles[i]),
                  ),
                ),
                if (i < vehicles.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            const SizedBox(height: AppSpacing.lg),
            AppOutlineButton(
              label: 'addNewVehicle'.tr(),
              icon: Icons.add_rounded,
              onPressed: () => _onAddPressed(context, vehicles.length),
            ),
            if (vehicles.length >= kMaxVehicles) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'vehicleLimitHint'.tr(
                  namedArgs: {'count': '$kMaxVehicles'},
                ),
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }
}

/// Premium dark dialog when the user hits the free vehicle cap.
Future<void> showVehicleLimitDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (context) {
      return Dialog(
        backgroundColor: AppColors.card,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(
            color: AppColors.border.withValues(alpha: 0.9),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.garage_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'vehicleLimitTitle'.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.title.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'vehicleLimitMessage'.tr(
                  namedArgs: {'count': '$kMaxVehicles'},
                ),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary.copyWith(height: 1.45),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    'vehicleLimitGotIt'.tr(),
                    style: AppTextStyles.button.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
