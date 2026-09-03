import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/station_search_filter.dart';
import '../../models/mock_gas_station.dart';
import '../../models/station_search_filter.dart';
import '../screens/refueling_form_screen.dart';
import '../screens/stations/station_detail_screen.dart';
import '../screens/tabs/trip/widgets/station_image_placeholder.dart';
import '../screens/tabs/trip/widgets/station_search_filter_bar.dart';

/// Luxury frosted glass modal sheet showing all nearby stations in rich detail
class StationListModalSheet extends StatefulWidget {
  const StationListModalSheet({
    super.key,
    required this.stations,
    required this.initialIndex,
    required this.onStationSelected,
    required this.onNavigate,
    this.initialFilter = const StationSearchFilter(),
    this.onFilterChanged,
  });

  final List<MockGasStation> stations;
  final int initialIndex;
  final ValueChanged<int> onStationSelected;
  final ValueChanged<MockGasStation> onNavigate;
  final StationSearchFilter initialFilter;
  final ValueChanged<StationSearchFilter>? onFilterChanged;

  static Future<void> show(
    BuildContext context, {
    required List<MockGasStation> stations,
    int initialIndex = 0,
    required ValueChanged<int> onStationSelected,
    required ValueChanged<MockGasStation> onNavigate,
    StationSearchFilter initialFilter = const StationSearchFilter(),
    ValueChanged<StationSearchFilter>? onFilterChanged,
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
        initialFilter: initialFilter,
        onFilterChanged: onFilterChanged,
      ),
    );
  }

  @override
  State<StationListModalSheet> createState() => _StationListModalSheetState();
}

class _StationListModalSheetState extends State<StationListModalSheet> {
  late int _selectedIndex;
  late StationSearchFilter _draft;
  late StationSearchFilter _applied;
  final _listController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, widget.stations.length - 1);
    _draft = widget.initialFilter;
    _applied = widget.initialFilter;
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  void _scrollResultsToTop() {
    if (!_listController.hasClients) return;
    _listController.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  List<MockGasStation> get _visibleStations =>
      applyStationSearchFilter(widget.stations, _applied);

  void _applyFilters() {
    setState(() {
      _applied = _draft;
      _selectedIndex = 0;
    });
    widget.onFilterChanged?.call(_applied);
    final nextVisible = applyStationSearchFilter(widget.stations, _applied);
    if (nextVisible.isNotEmpty) {
      final originalIndex = widget.stations.indexOf(nextVisible.first);
      if (originalIndex >= 0) {
        widget.onStationSelected(originalIndex);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollResultsToTop();
    });
  }

  void _resetFilters() {
    setState(() {
      _draft = const StationSearchFilter();
      _applied = const StationSearchFilter();
      _selectedIndex = 0;
    });
    widget.onFilterChanged?.call(_applied);
    if (widget.stations.isNotEmpty) {
      widget.onStationSelected(0);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollResultsToTop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleStations;
    final selectedStation = visible.isNotEmpty
        ? visible[_selectedIndex.clamp(0, visible.length - 1)]
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
            color: AppColors.card.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: AppColors.border,
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
                      color: AppColors.borderStrong,
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
                            SizedBox(height: 2),
                            Text(
                              '${visible.length} of ${widget.stations.length} stations',
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
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.control,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
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
                StationSearchFilterBar(
                  draft: _draft,
                  applied: _applied,
                  resultCount: visible.length,
                  onDraftChanged: (next) => setState(() => _draft = next),
                  onApply: _applyFilters,
                  onReset: _resetFilters,
                ),
                Divider(color: AppColors.divider, height: 1),

                Flexible(
                  child: visible.isEmpty
                      ? Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No stations match these filters. Try a wider radius or another fuel type.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        )
                      : ListView.separated(
                    controller: _listController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shrinkWrap: true,
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final station = visible[index];
                      final isSelected = index == _selectedIndex;

                      return _StationListRowItem(
                        station: station,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _selectedIndex = index);
                          final originalIndex = widget.stations.indexOf(station);
                          widget.onStationSelected(
                            originalIndex >= 0 ? originalIndex : index,
                          );
                        },
                      );
                    },
                  ),
                ),

                // 4. Bottom Action Area for Selected Station
                if (selectedStation != null) ...[
                  Divider(color: AppColors.divider, height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Row(
                      children: [
                        // Symmetrical Log Fuel Button
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const RefuelingFormScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.local_gas_station_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              label: Text(
                                'Log Fuel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Symmetrical Navigate Button
                        Expanded(
                          child: SizedBox(
                            height: 48,
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
                              label: const Text(
                                'Navigate',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
        color: isSelected ? AppColors.inputFill : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.4 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // 1. Station Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: AppColors.inputFill,
                    child: station.imageUrl != null
                        ? (station.imageUrl!.startsWith('http')
                            ? Image.network(
                                station.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    StationImagePlaceholder(
                                  fuelTypes: station.fuelTypes,
                                ),
                              )
                            : Image.asset(
                                station.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    StationImagePlaceholder(
                                  fuelTypes: station.fuelTypes,
                                ),
                              ))
                        : StationImagePlaceholder(fuelTypes: station.fuelTypes),
                  ),
                ),
                const SizedBox(width: 11),

                // 2. Center Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Line 1: Station Name
                      Text(
                        station.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),

                      // Line 2: ETA • drive distance • area
                      Row(
                        children: [
                          if (station.formattedEta != null) ...[
                            Text(
                              station.formattedEta!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ' • ',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          Text(
                            station.formattedDistanceBadge,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (station.addressHint.isNotEmpty) ...[
                            Text(
                              ' • ',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                station.addressHint,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 3),

                      // Line 3: Available Fuel Types
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

                // 3. Right Column: Clean Price & Star Rating
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => StationDetailScreen(
                          station: station.toStationInfo(),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '৳${station.primaryPrice.toStringAsFixed(0)}/L',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.star,
                              size: 11,
                              color: Color(0xFFFFB74D),
                            ),
                            SizedBox(width: 2.5),
                            Text(
                              station.rating.toString(),
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
