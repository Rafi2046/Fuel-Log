import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';

class StartTripFab extends StatelessWidget {
  const StartTripFab({
    required this.onPressed,
    this.isTracking = false,
  });

  final VoidCallback onPressed;
  final bool isTracking;

  // Soft pill — matches reference Start Trip (not sharp rect, not full capsule)
  static final _radius = BorderRadius.circular(28);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: isTracking ? const Color(0xFFD32F2F) : AppColors.primary,
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: _radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: _radius,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isTracking ? LucideIcons.square : LucideIcons.play,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isTracking ? 'endTripLog'.tr() : 'startTrip'.tr(),
                  style: AppTextStyles.button.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

