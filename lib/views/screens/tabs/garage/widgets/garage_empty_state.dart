import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../widgets/app_primary_button.dart';

/// Premium empty garage — abstract vehicle motif (no stock car photo).
class GarageEmptyState extends StatelessWidget {
  const GarageEmptyState({
    super.key,
    required this.onAddPressed,
  });

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        const _GarageHeroIllustration(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'garageEmptyTitle'.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'garageEmptySubtitle'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            _FeatureChip(
              icon: Icons.local_gas_station_rounded,
              label: 'garageEmptyChipFuel'.tr(),
            ),
            _FeatureChip(
              icon: Icons.route_rounded,
              label: 'garageEmptyChipTrips'.tr(),
            ),
            _FeatureChip(
              icon: Icons.build_rounded,
              label: 'garageEmptyChipService'.tr(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppPrimaryButton(
          label: 'garageAddFirstVehicle'.tr(),
          icon: Icons.add_rounded,
          onPressed: onAddPressed,
        ),
      ],
    );
  }
}

/// Soft glow + car/bike silhouettes — scalable, on-brand, no photo asset.
class _GarageHeroIllustration extends StatelessWidget {
  const _GarageHeroIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.22),
                  AppColors.primary.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardElevated,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.garage_rounded,
                  size: 72,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _VehicleGlyph(
                      icon: Icons.directions_car_filled_rounded,
                      offset: const Offset(-8, 4),
                    ),
                    const SizedBox(width: 6),
                    _VehicleGlyph(
                      icon: Icons.two_wheeler_rounded,
                      offset: const Offset(8, 6),
                      size: 34,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleGlyph extends StatelessWidget {
  _VehicleGlyph({
    required this.icon,
    this.offset = Offset.zero,
    this.size = 38,
  });

  final IconData icon;
  final Offset offset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: size, color: AppColors.primary),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  _FeatureChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
