import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import 'sheet_field_style.dart';

/// Tappable date row used inside modal sheets.
class CustomDatePickerRow extends StatelessWidget {
  const CustomDatePickerRow({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
    this.placeholder = 'Select date',
    this.dateFormat,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final String placeholder;
  final DateFormat? dateFormat;

  @override
  Widget build(BuildContext context) {
    final fmt = dateFormat ?? DateFormat('dd MMM yyyy');
    final text = date != null ? fmt.format(date!) : placeholder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: SheetFieldStyle.radius,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: SheetFieldStyle.fill,
              borderRadius: SheetFieldStyle.radius,
              border: Border.all(color: SheetFieldStyle.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: date != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
