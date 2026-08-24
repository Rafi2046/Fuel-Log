import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../models/fuel_price_model.dart';

/// Single fuel price row item with grade badge, price, timestamp, and change button
class StationPriceRow extends StatelessWidget {
  const StationPriceRow({
    super.key,
    required this.item,
    required this.onChangePressed,
  });

  final StationPriceItem item;
  final VoidCallback onChangePressed;

  @override
  Widget build(BuildContext context) {
    final grade = item.grade;
    final diff = DateTime.now().difference(item.lastUpdated);
    String updatedText;
    if (diff.inDays == 0) {
      updatedText = diff.inHours == 0 ? 'Today' : '${diff.inHours}h ago';
    } else {
      updatedText = '${diff.inDays}d ago';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Grade Badge (e.g. 95, 98, Diesel, CNG, LPG)
          Container(
            width: 44,
            height: 38,
            decoration: BoxDecoration(
              color: grade.badgeColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
            ),
            alignment: Alignment.center,
            child: Text(
              item.fuelGradeCode,
              style: TextStyle(
                color: grade.category == 'E' && grade.shortCode == 'E85'
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // 2. Price & Grade details (Expanded so it never overflows)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '৳${item.price.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        updatedText,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  grade.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 3. Change Button (Compact and clean)
          OutlinedButton(
            onPressed: onChangePressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primaryMuted),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(56, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.edit_rounded, size: 12, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
