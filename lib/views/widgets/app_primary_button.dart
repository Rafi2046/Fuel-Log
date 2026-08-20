import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_motion.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

/// Full-width solid orange CTA (reference "Order now" style).
class AppPrimaryButton extends StatefulWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusLg);

    return AnimatedScale(
      scale: _pressed && _enabled ? AppMotion.tapScale : 1,
      duration: AppMotion.instant,
      curve: AppMotion.emphasized,
      child: AnimatedOpacity(
        duration: AppMotion.fast,
        opacity: _enabled ? 1 : 0.5,
        child: Material(
          color: AppColors.primary,
          borderRadius: radius,
          child: InkWell(
            onTap: _enabled ? widget.onPressed : null,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: radius,
            child: Container(
              height: AppSpacing.buttonHeight,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: _enabled ? AppShadows.floating : null,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.label, style: AppTextStyles.button),
                        if (widget.icon != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            widget.icon,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
