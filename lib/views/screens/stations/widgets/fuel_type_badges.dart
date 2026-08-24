import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// Badges row showing available fuel types at the station (e.g. G, D, E, LPG, CNG)
class FuelTypeBadges extends StatelessWidget {
  const FuelTypeBadges({
    super.key,
    required this.categories,
  });

  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        Color bg = AppColors.primary;
        Color textCol = Colors.white;
        String fullTitle = category;

        if (category == 'G') {
          bg = const Color(0xFF22C55E);
          fullTitle = 'Gasoline';
        } else if (category == 'D') {
          bg = const Color(0xFF475569);
          fullTitle = 'Diesel';
        } else if (category == 'E') {
          bg = const Color(0xFFEAB308);
          textCol = Colors.black;
          fullTitle = 'Octane';
        } else if (category == 'LPG') {
          bg = const Color(0xFFDC2626);
          fullTitle = 'LPG';
        } else if (category == 'CNG') {
          bg = const Color(0xFF0284C7);
          fullTitle = 'CNG';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: bg.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$category ($fullTitle)',
                style: TextStyle(
                  color: textCol == Colors.black ? const Color(0xFFFDE047) : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
