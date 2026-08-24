import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/fuel_price_model.dart';

/// Ultra-sleek, luxury dark station price item row with clear typography and no truncation
class StationPriceRow extends StatelessWidget {
  const StationPriceRow({
    super.key,
    required this.item,
    required this.onChangePressed,
  });

  final StationPriceItem item;
  final VoidCallback onChangePressed;

  IconData _getFuelIcon(String code) {
    final c = code.toUpperCase();
    if (c.contains('CNG') || c.contains('LPG')) {
      return Icons.propane_tank_rounded;
    }
    return Icons.local_gas_station_rounded;
  }

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
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF262632),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onChangePressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Sleek Fuel Icon Badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getFuelIcon(item.fuelGradeCode),
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(width: 12),

                // 2. Fuel Grade Title & Verified Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        grade.label,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${grade.unit} • $updatedText',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // 3. Price & Edit Chip
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '৳${item.price.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.edit_rounded,
                          size: 11,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
