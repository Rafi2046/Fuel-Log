import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/constants/app_shadows.dart';

class TripStatsPill extends StatelessWidget {
  const TripStatsPill({
    super.key,
    required this.distanceKm,
    required this.elapsed,
  });

  final double distanceKm;
  final Duration elapsed;

  String get _timeLabel {
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = elapsed.inHours;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:$m:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.72;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.mapOverlay,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.mapOverlayBorder),
        boxShadow: AppShadows.floating,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.navigation,
                size: 15,
                color: AppColors.primary,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                '${distanceKm >= 1000 ? distanceKm.toStringAsFixed(0) : distanceKm.toStringAsFixed(2)} ${'km'.tr()}',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.onMapOverlay,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  '|',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.onMapOverlayMuted,
                  ),
                ),
              ),
              Text(
                _timeLabel,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.onMapOverlay,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

