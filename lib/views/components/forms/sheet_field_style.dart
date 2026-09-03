import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Shared dark fill / border tokens for modal sheet form fields.
abstract final class SheetFieldStyle {
  static const fill = Color(0xFF1E1E2A);
  static const border = Color(0xFF2E2E3E);
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
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
