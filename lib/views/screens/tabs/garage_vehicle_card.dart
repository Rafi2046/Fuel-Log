import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/clean_glass_panel.dart';

/// Vehicle row for the garage list.
class GarageVehicleCard extends StatelessWidget {
  const GarageVehicleCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.fuelType,
    required this.icon,
    required this.onDelete,
    this.embedded = false,
    this.showDivider = false,
  });

  final String name;
  final String subtitle;
  final String fuelType;
  final IconData icon;
  final VoidCallback onDelete;
  final bool embedded;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: EdgeInsets.fromLTRB(
        embedded ? 12 : AppSpacing.md,
        embedded ? 11 : AppSpacing.md,
        embedded ? 4 : AppSpacing.sm,
        embedded ? 11 : AppSpacing.md,
      ),
      child: Row(
        children: [
          _VehicleIconBadge(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FuelChip(label: fuelType),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'delete'.tr(),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 19,
              color: AppColors.textTertiary.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );

    if (embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row,
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

    return CleanGlassPanel(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: row,
    );
  }
}

class _VehicleIconBadge extends StatelessWidget {
  const _VehicleIconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Icon(icon, color: AppColors.primary, size: 21),
    );
  }
}

class _FuelChip extends StatelessWidget {
  const _FuelChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }
}
