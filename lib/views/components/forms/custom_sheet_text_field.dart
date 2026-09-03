import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import 'sheet_field_style.dart';

/// Labeled text field for dark modal sheets (cost, reminder, etc.).
class CustomSheetTextField extends StatelessWidget {
  const CustomSheetTextField({
    super.key,
    this.label,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixText,
    this.suffixText,
    this.prefixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.onChanged,
  });

  final String? label;
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? prefixText;
  final String? suffixText;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: SheetFieldStyle.decoration(
        hintText: hintText,
        labelText: labelText,
        prefixText: prefixText,
        suffixText: suffixText,
        prefixIcon: prefixIcon,
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label!,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}
