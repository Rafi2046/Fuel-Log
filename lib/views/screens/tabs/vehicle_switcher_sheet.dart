import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/vehicle_display.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import 'garage/confirm_delete_vehicle.dart';

/// Premium bottom sheet to switch the active vehicle.
class VehicleSwitcherSheet extends ConsumerWidget {
  const VehicleSwitcherSheet({
    super.key,
    required this.onManageGarage,
  });

  final VoidCallback onManageGarage;

  static final _sheetRadius = BorderRadius.circular(AppSpacing.radiusXl);
  static final _listRadius = BorderRadius.circular(AppSpacing.radiusLg);

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onManageGarage,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (_) => VehicleSwitcherSheet(onManageGarage: onManageGarage),
    );
  }

  Future<void> _deleteVehicle(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    await deleteVehicleWithConfirmation(context, ref, vehicle);
    if (!context.mounted) return;
    final remaining = ref.read(vehiclesProvider).valueOrNull ?? [];
    if (remaining.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider).valueOrNull ?? [];
    final currentActive = ref.watch(activeVehicleProvider).valueOrNull;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: _sheetRadius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: _sheetRadius,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.32),
                  blurRadius: 22,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'switchVehicleTitle'.tr(),
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'switchVehicleDeleteHint'.tr(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: _listRadius,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: _listRadius,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < vehicles.length; i++) ...[
                              Dismissible(
                                key: ValueKey('switcher_vehicle_${vehicles[i].id}'),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) async {
                                  await _deleteVehicle(
                                    context,
                                    ref,
                                    vehicles[i],
                                  );
                                  return false;
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  color: AppColors.error.withValues(alpha: 0.14),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                ),
                                child: _VehicleRow(
                                  vehicle: vehicles[i],
                                  selected:
                                      vehicles[i].id == currentActive?.id,
                                  onTap: () {
                                    ref
                                        .read(
                                          selectedVehicleIdProvider.notifier,
                                        )
                                        .select(vehicles[i].id);
                                    Navigator.of(context).pop();
                                  },
                                  onLongPress: () => _deleteVehicle(
                                    context,
                                    ref,
                                    vehicles[i],
                                  ),
                                ),
                              ),
                              if (i < vehicles.length - 1)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  indent: 12,
                                  endIndent: 12,
                                  color: AppColors.divider,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ManageGarageRow(onTap: () {
                      Navigator.of(context).pop();
                      onManageGarage();
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({
    required this.vehicle,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final Vehicle vehicle;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  static final _rowRadius = BorderRadius.circular(AppSpacing.radiusMd);

  String get _subtitle {
    if (vehicle.model != null && vehicle.model!.trim().isNotEmpty) {
      return '${vehicle.model!.trim()} • ${vehicle.fuelType}';
    }
    return vehicle.fuelType;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: _rowRadius,
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: _rowRadius,
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.07)
                  : Colors.transparent,
              border: selected
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.28),
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  _VehicleIconBadge(
                    icon: VehicleDisplay.iconFor(vehicle),
                    selected: selected,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.name,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          _subtitle,
                          style: AppTextStyles.caption.copyWith(
                            color: selected
                                ? AppColors.textSecondary
                                : AppColors.textTertiary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleIconBadge extends StatelessWidget {
  const _VehicleIconBadge({
    required this.icon,
    required this.selected,
  });

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: selected ? AppColors.primary : AppColors.textTertiary,
      ),
    );
  }
}

class _ManageGarageRow extends StatelessWidget {
  const _ManageGarageRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: EdgeInsets.fromLTRB(4, 6, 4, 2),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.garage_rounded,
                  size: 17,
                  color: AppColors.textTertiary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'manageGarage'.tr(),
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textTertiary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
