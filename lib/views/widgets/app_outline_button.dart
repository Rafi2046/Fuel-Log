import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_motion.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

/// Outlined dark CTA (reference "Get Started" style).
class AppOutlineButton extends StatefulWidget {
  const AppOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_ios_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  State<AppOutlineButton> createState() => _AppOutlineButtonState();
}

class _AppOutlineButtonState extends State<AppOutlineButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusLg);

    return AnimatedScale(
      scale: _pressed && _enabled ? AppMotion.tapScale : 1,
      duration: AppMotion.instant,
      curve: AppMotion.emphasized,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: radius,
          child: Container(
            height: AppSpacing.buttonHeight,
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppColors.borderStrong, width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label.toUpperCase(),
                    style: AppTextStyles.button.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.icon != null)
                  Icon(widget.icon, size: 16, color: AppColors.textPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
