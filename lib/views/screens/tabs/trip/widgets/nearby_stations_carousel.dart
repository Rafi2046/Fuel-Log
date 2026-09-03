import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../models/mock_gas_station.dart';
import '../../../stations/station_detail_screen.dart';
import 'station_carousel_card.dart';

class NearbyStationsCarousel extends StatelessWidget {
  const NearbyStationsCarousel({
    super.key,
    required this.stations,
    required this.selectedIndex,
    required this.controller,
    required this.onPageChanged,
    required this.onStationSelected,
    required this.onNavigate,
    required this.onViewAll,
  });

  final List<MockGasStation> stations;
  final int selectedIndex;
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onStationSelected;
  final ValueChanged<MockGasStation> onNavigate;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clean Header Bar (Tap to open full list modal sheet)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Station count badge
              Material(
                color: AppColors.mapOverlay,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: InkWell(
                  onTap: onViewAll,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4.5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                      border: Border.all(color: AppColors.mapOverlayBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.fuel,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '${stations.length} Stations Found',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. "View List" pill button
              Material(
                color: AppColors.mapOverlay,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: InkWell(
                  onTap: onViewAll,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4.5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                      border: Border.all(color: AppColors.mapOverlayBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.list,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'View List & Rates',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Horizontal Carousel
        SizedBox(
          height: 132,
          child: PageView.builder(
            controller: controller,
            itemCount: stations.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final station = stations[index];
              final isSelected = index == selectedIndex;

              return StationCarouselCard(
                station: station,
                isSelected: isSelected,
                onTap: () => onStationSelected(index),
                onNavigate: () => onNavigate(station),
                onViewRates: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => StationDetailScreen(
                        station: station.toStationInfo(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

