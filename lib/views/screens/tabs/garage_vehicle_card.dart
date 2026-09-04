import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/vehicle_display.dart';

/// Luxury automotive garage vehicle card with clean status and metrics.
class GarageVehicleCard extends StatelessWidget {
  const GarageVehicleCard({
    super.key,
    required this.vehicle,
    required this.isActive,
    required this.onTap,
    required this.onSetCurrent,
    required this.onDelete,
  });

  final Vehicle vehicle;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onSetCurrent;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isBike = VehicleDisplay.isBike(vehicle);
    final icon = VehicleDisplay.iconFor(vehicle);
    final regNo = vehicle.brand?.trim();
    final hasReg = regNo != null && regNo.isNotEmpty;
    final modelText = vehicle.model?.trim();
    final hasModel = modelText != null && modelText.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.55)
              : AppColors.border,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.25),
            blurRadius: isActive ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  children: [
                    // Vehicle Icon Badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary.withValues(alpha: 0.35)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Model
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.title.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            hasModel
                                ? '${vehicle.type} • $modelText'
                                : vehicle.type,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active Badge or Select Button
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: onSetCurrent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Text(
                            'Select',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),

                    SizedBox(width: 4),

                    // 3-Dots Action Menu
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      color: AppColors.cardElevated,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        side: BorderSide(color: AppColors.border),
                      ),
                      onSelected: (val) {
                        if (val == 'edit') onTap();
                        if (val == 'select') onSetCurrent();
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        if (!isActive)
                          const PopupMenuItem(
                            value: 'select',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 18,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 10),
                                Text('Set as Active'),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 10),
                              Text('Edit Vehicle'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.error,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Delete',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Specs Chips Row
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetricChip(
                      icon: Icons.speed_rounded,
                      label:
                          '${NumberFormat('#,###').format(vehicle.startOdo.round())} km',
                    ),
                    _MetricChip(
                      icon: vehicle.isElectric
                          ? Icons.ev_station_rounded
                          : Icons.local_gas_station_rounded,
                      label: vehicle.fuelType,
                    ),
                    if (vehicle.capacity > 0)
                      _MetricChip(
                        icon: vehicle.isElectric
                            ? Icons.battery_charging_full_rounded
                            : Icons.opacity_rounded,
                        label:
                            '${vehicle.capacity.toStringAsFixed(vehicle.capacity.truncateToDouble() == vehicle.capacity ? 0 : 1)} ${vehicle.isElectric ? 'kWh' : 'L'}',
                      ),
                  ],
                ),

                // License Plate Tag (if available)
                if (hasReg) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isBike
                              ? Icons.two_wheeler_outlined
                              : Icons.directions_car_outlined,
                          size: 13,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          regNo.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: AppColors.textTertiary,
          ),
          SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
