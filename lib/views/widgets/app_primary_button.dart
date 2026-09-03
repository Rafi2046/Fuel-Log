import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

/// Full-width solid orange CTA (reference "Order now" style).
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final radius = BorderRadius.circular(
      compact ? AppSpacing.radiusMd : AppSpacing.radiusLg,
    );
    final height = compact
        ? AppSpacing.buttonHeightCompact
        : AppSpacing.buttonHeight;
    // Always white on brand orange — independent of light/dark textPrimary.
    const onPrimary = Colors.white;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: radius,
            boxShadow: enabled && !compact ? AppShadows.floating : null,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: onPrimary,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.button.copyWith(color: onPrimary),
                    ),
                    if (icon != null) ...[
                      SizedBox(width: AppSpacing.sm),
                      Icon(
                        icon,
                        size: 20,
                        color: onPrimary,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
