import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../models/fuel_price_model.dart';

/// Single station list item card with sleek, modern, lightweight luxury design
class StationListCard extends StatelessWidget {
  const StationListCard({
    super.key,
    required this.station,
    required this.onTap,
    required this.onShowDetails,
    required this.onShowMap,
    required this.onNavigate,
  });

  final StationInfo station;
  final VoidCallback onTap;
  final VoidCallback onShowDetails;
  final VoidCallback onShowMap;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final priceStr = '৳${station.primaryPrice.toStringAsFixed(2)}';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Sleek, minimal Circular Station Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_gas_station_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                // 2. Station Name & Distance & Upvotes
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        station.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            station.formattedDistance,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            station.isUserUpvoted
                                ? Icons.thumb_up_alt_rounded
                                : Icons.thumb_up_alt_outlined,
                            size: 12,
                            color: station.isUserUpvoted
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${station.upvotes}',
                            style: TextStyle(
                              color: station.isUserUpvoted
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (station.isFavorite) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Color(0xFFFBBF24),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // 3. Price & Last Updated Tag
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      priceStr,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      station.latestUpdateRelative,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 2),

                // 4. 3-Dot Options Menu
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textTertiary,
                    size: 18,
                  ),
                  color: AppColors.cardElevated,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onSelected: (val) {
                    if (val == 'details') {
                      onShowDetails();
                    } else if (val == 'map') {
                      onShowMap();
                    } else if (val == 'navigate') {
                      onNavigate();
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text('Details',
                              style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'map',
                      child: Row(
                        children: [
                          Icon(Icons.map_rounded,
                              size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text('Show on map',
                              style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'navigate',
                      child: Row(
                        children: [
                          Icon(Icons.directions_rounded,
                              size: 16, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Get Directions',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
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
