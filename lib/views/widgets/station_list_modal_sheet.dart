import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../screens/tabs/trip_log_tab.dart';
import 'trip_manual_entry_sheet.dart';

/// Luxury frosted glass modal sheet showing all nearby stations in rich detail
class StationListModalSheet extends StatefulWidget {
  const StationListModalSheet({
    super.key,
    required this.stations,
    required this.initialIndex,
    required this.onStationSelected,
    required this.onNavigate,
  });

  final List<MockGasStation> stations;
  final int initialIndex;
  final ValueChanged<int> onStationSelected;
  final ValueChanged<MockGasStation> onNavigate;

  static Future<void> show(
    BuildContext context, {
    required List<MockGasStation> stations,
    int initialIndex = 0,
    required ValueChanged<int> onStationSelected,
    required ValueChanged<MockGasStation> onNavigate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => StationListModalSheet(
        stations: stations,
        initialIndex: initialIndex,
        onStationSelected: onStationSelected,
        onNavigate: onNavigate,
      ),
    );
  }

  @override
  State<StationListModalSheet> createState() => _StationListModalSheetState();
}

class _StationListModalSheetState extends State<StationListModalSheet> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, widget.stations.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final selectedStation = widget.stations.isNotEmpty
        ? widget.stations[_selectedIndex]
        : null;

    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.78;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: const Color(0xFF14141B).withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: const Color(0xFF2C2C38),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Top Drag Handle
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 42,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A4A58),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.fuel,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'nearbyStations'.tr(),
                              style: AppTextStyles.title.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.stations.length} stations found nearby',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22222D),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF333342)),
                          ),
                          child: const Icon(
                            LucideIcons.x,
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF262633), height: 1),

                // 3. Station List (Scrollable)
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shrinkWrap: true,
                    itemCount: widget.stations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final station = widget.stations[index];
                      final isSelected = index == _selectedIndex;

                      return _StationListRowItem(
                        station: station,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _selectedIndex = index);
                          widget.onStationSelected(index);
                        },
                      );
                    },
                  ),
                ),

                // 4. Bottom Action Area for Selected Station
                if (selectedStation != null) ...[
                  const Divider(color: Color(0xFF262633), height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Row(
                      children: [
                        // Quick Fuel Log Button
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            showTripManualEntrySheet(context);
                          },
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: const Text('Log Fuel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: Color(0xFF3A3A4A)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Full-Width Primary Navigate Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onNavigate(selectedStation);
                            },
                            icon: const Icon(
                              LucideIcons.navigation,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Navigate to ${selectedStation.name.split(' ').first}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              elevation: 4,
                              shadowColor:
                                  AppColors.primary.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StationListRowItem extends StatelessWidget {
  const _StationListRowItem({
    required this.station,
    required this.isSelected,
    required this.onTap,
  });

  final MockGasStation station;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF22222E)
            : const Color(0xFF181822),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : const Color(0xFF2A2A38),
          width: isSelected ? 1.4 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // 1. Squircle Station Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 58,
                    height: 58,
                    color: const Color(0xFF22222C),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (station.imageUrl != null)
                          station.imageUrl!.startsWith('http')
                              ? Image.network(
                                  station.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const _ThumbnailFallback(),
                                )
                              : Image.asset(
                                  station.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const _ThumbnailFallback(),
                                )
                        else
                          const _ThumbnailFallback(),
                        Positioned(
                          left: 3,
                          bottom: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3.5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF101014)
                                  .withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'OPEN',
                              style: TextStyle(
                                color: Color(0xFF81C784),
                                fontSize: 7.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Center Details (No Truncation)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Rating
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              station.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.star,
                                size: 12,
                                color: Color(0xFFFFB74D),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                station.rating.toString(),
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Full address & Distance
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              station.distance,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Fuels
                      Text(
                        station.fuelTypes,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // 3. Selection Check / Arrow Indicator
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFF333342),
                    ),
                  ),
                  child: Icon(
                    isSelected
                        ? LucideIcons.check
                        : LucideIcons.chevronRight,
                    size: 14,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF20202A),
      child: const Center(
        child: Icon(
          LucideIcons.fuel,
          color: AppColors.textTertiary,
          size: 20,
        ),
      ),
    );
  }
}
