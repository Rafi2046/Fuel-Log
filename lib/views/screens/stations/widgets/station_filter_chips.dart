import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// Horizontal scrolling fuel category chips styled with FuelLog dark luxury theme
class StationFilterChips extends StatelessWidget {
  const StationFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  static const _categories = ['ALL', '95', '98', '91', 'D', 'CNG', 'LPG'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        itemCount: _categories.length,
        separatorBuilder: (context, _) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final cat = _categories[idx];
          final isSelected = selectedFilter == cat;

          String label = cat;
          if (cat == 'ALL') label = 'All Fuels';
          if (cat == '95') label = 'Octane 95';
          if (cat == '98') label = 'Octane 98';
          if (cat == '91') label = 'Petrol 91';
          if (cat == 'D') label = 'Diesel';

          return ChoiceChip(
            label: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.card,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            onSelected: (_) => onFilterChanged(cat),
          );
        },
      ),
    );
  }
}
