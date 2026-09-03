import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Shared fill / border tokens for modal sheet form fields (theme-aware).
abstract final class SheetFieldStyle {
  static Color get fill => AppColors.inputFill;
  static Color get border => AppColors.border;
  static final radius = BorderRadius.circular(12);

  static InputDecoration decoration({
    String? hintText,
    String? labelText,
    String? prefixText,
    String? suffixText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: fill,
      hintText: hintText,
      labelText: labelText,
      prefixText: prefixText,
      suffixText: suffixText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
      labelStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
      prefixStyle: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
      suffixStyle: TextStyle(color: AppColors.textTertiary, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
