import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/vehicle_display.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/clean_glass_panel.dart';
import '../vehicle_setup_screen.dart';
import 'garage/confirm_delete_vehicle.dart';
import 'garage/widgets/garage_empty_state.dart';
import 'garage/widgets/garage_slots_header.dart';
import 'garage_vehicle_card.dart';

/// Soft cap — free tier allows up to this many vehicles.
const int kMaxVehicles = 3;

/// Garage tab listing vehicles with an Add Vehicle button.
class GarageTab extends ConsumerWidget {
  const GarageTab({super.key});

  /// Car vs bike icon from saved [Vehicle.type].
  IconData _iconFor(Vehicle vehicle) => VehicleDisplay.iconFor(vehicle);

  bool _isBike(Vehicle vehicle) => VehicleDisplay.isBike(vehicle);

  String _typeLabel(Vehicle vehicle) =>
      _isBike(vehicle) ? 'vehicleTypeBike'.tr() : 'vehicleTypeCar'.tr();

  String _subtitle(Vehicle vehicle) {
    final parts = <String>[
      _typeLabel(vehicle),
      if (vehicle.model != null && vehicle.model!.trim().isNotEmpty)
        vehicle.model!.trim(),
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
    await deleteVehicleWithConfirmation(context, ref, vehicle);
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
        final isEmpty = vehicles.isEmpty;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            if (!isEmpty) ...[
              GarageSlotsHeader(used: vehicles.length, max: kMaxVehicles),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (isEmpty)
              GarageEmptyState(
                onAddPressed: () => _onAddPressed(context, 0),
              )
            else ...[
              CleanGlassPanel(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < vehicles.length; i++)
                      Dismissible(
                        key: ValueKey('vehicle_${vehicles[i].id}'),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          await _confirmDelete(context, ref, vehicles[i]);
                          return false;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppSpacing.md),
                          color: AppColors.error.withValues(alpha: 0.12),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                        ),
                        child: GarageVehicleCard(
                          name: vehicles[i].name,
                          subtitle: _subtitle(vehicles[i]),
                          fuelType: vehicles[i].fuelType,
                          icon: _iconFor(vehicles[i]),
                          embedded: true,
                          showDivider: i < vehicles.length - 1,
                          onDelete: () =>
                              _confirmDelete(context, ref, vehicles[i]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (!isEmpty) ...[
              const SizedBox(height: 10),
              _GarageAddButton(
                label: 'addNewVehicle'.tr(),
                onPressed: vehicles.length >= kMaxVehicles
                    ? null
                    : () => _onAddPressed(context, vehicles.length),
              ),
            ],
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

class _GarageAddButton extends StatelessWidget {
  const _GarageAddButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.32),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.add_rounded,
                  size: 17,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
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
