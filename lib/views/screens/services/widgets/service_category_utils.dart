import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// Helpers for Service category icons and colors.
abstract final class ServiceCategoryUtils {
  static IconData getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('maintenance')) return Icons.build_rounded;
    if (lower.contains('repair')) return Icons.handyman_rounded;
    if (lower.contains('parking') || lower.contains('toll')) {
      return Icons.local_parking_rounded;
    }
    if (lower.contains('tax') ||
        lower.contains('legal') ||
        lower.contains('document')) {
      return Icons.description_rounded;
    }
    if (lower.contains('wash') || lower.contains('detailing')) {
      return Icons.clean_hands_rounded;
    }
    if (lower.contains('parts') || lower.contains('accessories')) {
      return Icons.shopping_bag_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  static Color getCategoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('maintenance')) return AppColors.primary;
    if (lower.contains('repair')) return const Color(0xFFB45309);
    if (lower.contains('parking') || lower.contains('toll')) {
      return const Color(0xFF64748B);
    }
    if (lower.contains('tax') || lower.contains('document')) {
      return const Color(0xFF78716C);
    }
    if (lower.contains('wash')) return const Color(0xFF57534E);
    if (lower.contains('parts')) return const Color(0xFFA8A29E);
    return AppColors.textSecondary;
  }
}

/// Reusable Metric Card for Services Analytics.
class ServiceMetricCard extends StatelessWidget {
  const ServiceMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.wash,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
