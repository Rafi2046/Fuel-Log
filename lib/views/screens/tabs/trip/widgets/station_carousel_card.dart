import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../models/mock_gas_station.dart';
import 'station_carousel_thumbnail.dart';

class StationCarouselCard extends StatelessWidget {
  const StationCarouselCard({
    required this.station,
    required this.isSelected,
    required this.onTap,
    required this.onNavigate,
    required this.onViewRates,
  });

  final MockGasStation station;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onNavigate;
  final VoidCallback onViewRates;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF16161C),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : const Color(0xFF2A2A34),
          width: isSelected ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          if (isSelected)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Row(
              children: [
                StationCarouselThumbnail(station: station),
                const SizedBox(width: 10),

                // 2. Right Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top row: Station Name & Price
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              station.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '৳${station.primaryPrice.toStringAsFixed(0)}/L',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),

                      // Middle row: Distance First • Area + Rating
                      Row(
                        children: [
                          Text(
                            _getDist(station.distance),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          if (_getArea(station.distance).isNotEmpty &&
                              _getArea(station.distance) !=
                                  _getDist(station.distance)) ...[
                            Text(
                              ' • ',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 10.5,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                _getArea(station.distance),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.star,
                                size: 10.5,
                                color: Color(0xFFFFB74D),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                station.rating.toString(),
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Bottom row: Fuel types + Navigate button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              station.fuelTypes,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Material(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(7),
                            child: InkWell(
                              onTap: onNavigate,
                              borderRadius: BorderRadius.circular(7),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.navigation,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 3.5),
                                    Text(
                                      'navigate'.tr(),
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _getArea(String distanceStr) {
    if (distanceStr.contains('•')) {
      return distanceStr.split('•').first.trim();
    }
    return distanceStr;
  }

  static String _getDist(String distanceStr) {
    if (distanceStr.contains('•')) {
      return distanceStr.split('•').last.trim();
    }
    return distanceStr;
  }
}
