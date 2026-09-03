import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Cancel + primary Save action row for modal bottom sheets.
class SheetActionBar extends StatelessWidget {
  const SheetActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.cancelLabel = 'Cancel',
    this.onCancel,
    this.primaryColor = const Color(0xFF2ECC71),
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final String cancelLabel;
  final VoidCallback? onCancel;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Color(0xFF2E2E3E)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                cancelLabel,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                primaryLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
