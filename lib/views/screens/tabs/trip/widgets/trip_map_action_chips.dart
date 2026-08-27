import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';

class TripMapActionChips extends StatelessWidget {
  const TripMapActionChips({
    super.key,
    required this.isLoadingStations,
    required this.isStationsActive,
    required this.onStations,
    required this.onNavigate,
    this.onHistory,
  });

  final bool isLoadingStations;
  final bool isStationsActive;
  final VoidCallback onStations;
  final VoidCallback onNavigate;
  final VoidCallback? onHistory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TripMapChip(
            icon: LucideIcons.fuel,
            label: 'nearbyStations'.tr(),
            isLoading: isLoadingStations,
            isActive: isStationsActive,
            onTap: onStations,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TripMapChip(
            icon: LucideIcons.route,
            label: 'tripHistory'.tr(),
            isLoading: false,
            isActive: false,
            onTap: onHistory ?? onNavigate,
          ),
        ),
      ],
    );
  }
}

class TripMapChip extends StatelessWidget {
  const TripMapChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF18181F).withValues(alpha: 0.94),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: isActive
                  ? AppColors.primary
                  : const Color(0xFF2E2E38),
              width: isActive ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 15,
                  color: AppColors.primary,
                ),
              const SizedBox(width: 8),
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

