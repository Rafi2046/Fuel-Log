import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// Minimalist, luxury horizontal tags for available fuel types
class FuelTypeBadges extends StatelessWidget {
  const FuelTypeBadges({
    super.key,
    required this.categories,
  });

  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: categories.map((category) {
        String label = category;
        if (category == 'G') {
          label = 'Petrol';
        } else if (category == 'D') {
          label = 'Diesel';
        } else if (category == 'E') {
          label = 'Octane';
        } else if (category == 'LPG') {
          label = 'LPG / AutoGas';
        } else if (category == 'CNG') {
          label = 'CNG';
        } else if (category == 'EV') {
          label = 'EV Charging';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A22),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: const Color(0xFF2C2C38),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
