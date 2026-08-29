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

/// Premium glass bottom sheet to switch the active vehicle.
class VehicleSwitcherSheet extends ConsumerWidget {
  const VehicleSwitcherSheet({
    super.key,
    required this.onManageGarage,
  });

  final VoidCallback onManageGarage;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider).valueOrNull ?? [];
    final currentActive = ref.watch(activeVehicleProvider).valueOrNull;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
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
                const SizedBox(height: 10),
                CleanGlassPanel(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (var i = 0; i < vehicles.length; i++)
                        _VehicleRow(
                          vehicle: vehicles[i],
                          selected: vehicles[i].id == currentActive?.id,
                          showDivider: i < vehicles.length - 1,
                          onTap: () {
                            ref
                                .read(selectedVehicleIdProvider.notifier)
                                .select(vehicles[i].id);
                            Navigator.of(context).pop();
                          },
                        ),
                    ],
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
    );
  }
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({
    required this.vehicle,
    required this.selected,
    required this.onTap,
    this.showDivider = false,
  });

  final Vehicle vehicle;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  String get _subtitle {
    if (vehicle.model != null && vehicle.model!.trim().isNotEmpty) {
      return '${vehicle.model!.trim()} • ${vehicle.fuelType}';
    }
    return vehicle.fuelType;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _VehicleIconBadge(
                    icon: VehicleDisplay.iconFor(vehicle),
                    selected: selected,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.name,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subtitle,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
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
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
      ],
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
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: selected ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Icon(
        icon,
        size: 19,
        color: selected ? AppColors.primary : AppColors.textSecondary,
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
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.garage_rounded,
                  size: 17,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'manageGarage'.tr(),
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textTertiary.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
