import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/trip_manual_entry_sheet.dart';

/// Map-centric trip logging — full-bleed placeholder map + floating controls.
class TripLogTab extends StatelessWidget {
  const TripLogTab({super.key});

  void _chipSnack(BuildContext context, String key) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          key.tr(),
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.cardElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _MapPlaceholder(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                0,
              ),
              child: Column(
                children: [
                  const _TripStatsPill(
                    distanceKm: 0,
                    elapsed: Duration.zero,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _MapActionChips(
                    onStations: () =>
                        _chipSnack(context, 'nearbyStationsComingSoon'),
                    onNavigate: () =>
                        _chipSnack(context, 'navigateComingSoon'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'trip_manual_entry',
              onPressed: () => showTripManualEntrySheet(context),
              backgroundColor: AppColors.cardElevated,
              foregroundColor: AppColors.primary,
              elevation: 6,
              shape: const CircleBorder(),
              tooltip: 'manualTripEntry'.tr(),
              child: const Icon(Icons.edit_location_alt_rounded),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StartTripFab(
                onPressed: () => _chipSnack(context, 'tripGpsComingSoon'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapActionChips extends StatelessWidget {
  const _MapActionChips({
    required this.onStations,
    required this.onNavigate,
  });

  final VoidCallback onStations;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MapChip(
            icon: Icons.local_gas_station_rounded,
            label: 'nearbyStations'.tr(),
            onTap: onStations,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MapChip(
            icon: Icons.navigation_rounded,
            label: 'navigate'.tr(),
            onTap: onNavigate,
          ),
        ),
      ],
    );
  }
}

/// Floating dark chip — subtle border, not a heavy button.
class _MapChip extends StatelessWidget {
  const _MapChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardElevated.withValues(alpha: 0.92),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.9),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_rounded,
              size: 72,
              color: AppColors.textTertiary.withValues(alpha: 0.45),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'tripMapPlaceholder'.tr(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripStatsPill extends StatelessWidget {
  const _TripStatsPill({
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.navigation_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${distanceKm.toStringAsFixed(1)} ${'km'.tr()}',
            style: AppTextStyles.label.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              '|',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Text(
            _timeLabel,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartTripFab extends StatelessWidget {
  const _StartTripFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      elevation: 8,
      shadowColor: AppColors.primary.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Container(
          height: AppSpacing.buttonHeight,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.textPrimary,
                size: 26,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'startTrip'.tr(),
                style: AppTextStyles.button.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
