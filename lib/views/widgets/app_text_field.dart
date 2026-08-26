import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

/// Soft rounded field matching premium dark form cards.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixText,
    this.suffixIcon,
    this.inputFormatters,
    this.onChanged,
    this.onEditingComplete,
    this.obscureText = false,
    this.maxLines = 1,
    this.dense = false,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final String? suffixText;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final bool obscureText;
  final int maxLines;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final labelStyle = dense
        ? AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontSize: 11,
          )
        : AppTextStyles.label;
    final fieldStyle = dense
        ? AppTextStyles.body.copyWith(fontSize: 14, height: 1.25)
        : AppTextStyles.body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        SizedBox(height: dense ? 6 : AppSpacing.sm),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          obscureText: obscureText,
          maxLines: maxLines,
          style: fieldStyle,
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            isDense: dense,
            contentPadding: dense
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
                : null,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(
                    prefixIcon,
                    color: AppColors.textTertiary,
                    size: dense ? 18 : 20,
                  ),
            suffixText: suffixText,
            suffixStyle: AppTextStyles.label.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: dense ? 12 : 14,
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
