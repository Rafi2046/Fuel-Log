import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../clean_glass_panel.dart';

/// Glass container section wrapper for grouped form fields.
class GlassSection extends StatelessWidget {
  const GlassSection({
    super.key,
    required this.child,
    this.label,
  });

  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return CleanGlassPanel(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          child,
        ],
      ),
    );
  }
}

/// Borderless field styling utility for manual trip entry.
class TripFieldDecor {
  TripFieldDecor._();

  static const prefixConstraints = BoxConstraints(minWidth: 34, minHeight: 28);
  static const contentPadding = EdgeInsets.symmetric(vertical: 4);
  static const multiLinePadding = EdgeInsets.only(top: 8, bottom: 4);
  static final _iconColor = AppColors.textTertiary;
  static final _labelColor = AppColors.textTertiary;
  static final _focusedLabelColor = AppColors.textSecondary;

  static InputDecoration base({
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    String? prefixText,
    String? suffixText,
    int maxLines = 1,
    bool showBorder = true,
  }) {
    final borderSide =
        showBorder ? BorderSide(color: AppColors.border) : BorderSide.none;
    final focusedBorder = showBorder
        ? UnderlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.65),
              width: 1.2,
            ),
          )
        : InputBorder.none;

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon:
          prefixIcon == null ? null : Icon(prefixIcon, color: _iconColor, size: 18),
      prefixIconConstraints: prefixConstraints,
      prefixText: prefixText,
      prefixStyle: AppTextStyles.body.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
      suffixText: suffixText,
      suffixStyle: AppTextStyles.caption.copyWith(
        color: AppColors.textTertiary,
        fontSize: 11,
      ),
      isDense: true,
      filled: false,
      alignLabelWithHint: maxLines > 1,
      contentPadding: maxLines > 1 ? multiLinePadding : contentPadding,
      border: UnderlineInputBorder(borderSide: borderSide),
      enabledBorder: UnderlineInputBorder(borderSide: borderSide),
      focusedBorder: focusedBorder,
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.error, width: 1.4),
      ),
      labelStyle: AppTextStyles.caption.copyWith(
        fontSize: 11,
        color: _labelColor,
      ),
      floatingLabelStyle: AppTextStyles.caption.copyWith(
        color: _focusedLabelColor,
        fontSize: 11,
      ),
      hintStyle: AppTextStyles.bodySecondary.copyWith(
        color: AppColors.textTertiary,
        fontSize: 13,
      ),
    );
  }
}

/// Circular glass button for modal close or auxiliary actions.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputFill,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

/// Underline-styled text form field.
class UnderlineField extends StatelessWidget {
  const UnderlineField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.prefixText,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.validator,
    this.maxLines = 1,
    this.showBorder = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final String? prefixText;
  final String? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      validator: validator,
      maxLines: maxLines,
      style: AppTextStyles.body.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      cursorColor: AppColors.primary,
      decoration: TripFieldDecor.base(
        labelText: label,
        hintText: hint,
        prefixIcon: icon,
        prefixText: prefixText,
        suffixText: suffix,
        maxLines: maxLines,
        showBorder: showBorder,
      ),
    );
  }
}

/// Tappable selector field (e.g. date & time pickers).
class TapField extends StatelessWidget {
  const TapField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InputDecorator(
        decoration: TripFieldDecor.base(
          labelText: label,
          prefixIcon: icon,
        ),
        child: Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Location input field with map picker button.
class LocationField extends StatelessWidget {
  const LocationField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onPickMap,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final VoidCallback onPickMap;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: UnderlineField(
            controller: controller,
            label: label,
            hint: hint,
            icon: icon,
            textInputAction: TextInputAction.next,
            validator: validator,
          ),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Tooltip(
            message: 'pickOnMap'.tr(),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPickMap,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(
                    LucideIcons.map,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
