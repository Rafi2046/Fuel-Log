import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../viewmodels/gas_station_viewmodel.dart';

Future<void> showStationSortSheet(
  BuildContext context, {
  required GasStationsNotifier notifier,
  required StationSortOption currentSort,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.cardElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Sort & Filter Stations',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _sortTile(
              ctx,
              notifier,
              'Nearest Distance',
              Icons.near_me_rounded,
              StationSortOption.distance,
              currentSort,
            ),
            _sortTile(
              ctx,
              notifier,
              'Lowest Fuel Price',
              Icons.sell_rounded,
              StationSortOption.price,
              currentSort,
            ),
            _sortTile(
              ctx,
              notifier,
              'Most Upvoted / Popular',
              Icons.thumb_up_alt_rounded,
              StationSortOption.upvotes,
              currentSort,
            ),
            _sortTile(
              ctx,
              notifier,
              'Alphabetical (Name)',
              Icons.sort_by_alpha_rounded,
              StationSortOption.name,
              currentSort,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _sortTile(
  BuildContext ctx,
  GasStationsNotifier notifier,
  String title,
  IconData icon,
  StationSortOption option,
  StationSortOption current,
) {
  final isSelected = current == option;
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryMuted : AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        size: 20,
      ),
    ),
    title: Text(
      title,
      style: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 14,
      ),
    ),
    trailing: isSelected
        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
        : null,
    onTap: () {
      notifier.setSortOption(option);
      Navigator.of(ctx).pop();
    },
  );
}
