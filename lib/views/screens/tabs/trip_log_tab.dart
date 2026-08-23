import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/trip_manual_entry_sheet.dart';

class MockGasStation {
  final String id;
  final String name;
  final String distance;
  final String fuelTypes;
  final double rating;
  final LatLng location;

  const MockGasStation({
    required this.id,
    required this.name,
    required this.distance,
    required this.fuelTypes,
    required this.rating,
    required this.location,
  });
}

const LatLng kDefaultUserLocation = LatLng(23.7925, 90.4078);

/// Map-centric trip logging with real-time GPS location, ultra-clean dark map, smooth animated camera, and buffered tile streaming.
class TripLogTab extends StatefulWidget {
  const TripLogTab({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<TripLogTab> createState() => _TripLogTabState();
}

class _TripLogTabState extends State<TripLogTab>
    with SingleTickerProviderStateMixin {
  bool _isLoadingStations = false;
  bool _showStations = false;
  bool _isFetchingLocation = false;
  int _selectedStationIndex = 0;
  List<MockGasStation> _stations = [];
  LatLng _userLocation = kDefaultUserLocation;

  late final MapController _mapController;
  late final PageController _carouselController;
  AnimationController? _cameraAnimController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _carouselController = PageController(viewportFraction: 0.86);

    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchLiveLocation();
      });
    }
  }

  @override
  void didUpdateWidget(covariant TripLogTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchLiveLocation();
      });
    }
  }

  @override
  void dispose() {
    _cameraAnimController?.dispose();
    _mapController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  /// Silky smooth 60fps camera movement with easeOutCubic curve
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    _cameraAnimController?.dispose();
    final animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _cameraAnimController = animController;

    LatLng startCenter = _userLocation;
    double startZoom = 15.0;
    try {
      startCenter = _mapController.camera.center;
      startZoom = _mapController.camera.zoom;
    } catch (_) {}

    final latTween = _LatLngTween(begin: startCenter, end: destLocation);
    final zoomTween = Tween<double>(begin: startZoom, end: destZoom);

    final animation = CurvedAnimation(
      parent: animController,
      curve: Curves.easeOutCubic,
    );

    animation.addListener(() {
      try {
        _mapController.move(
          latTween.evaluate(animation),
          zoomTween.evaluate(animation),
        );
      } catch (_) {}
    });

    animController.forward();
  }

  /// Automatically requests permission and fetches live device GPS coordinates
  Future<void> _fetchLiveLocation({bool showFeedback = false}) async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showFeedback && mounted) {
          _chipSnack('Please enable device GPS / Location services');
        }
        setState(() => _isFetchingLocation = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (showFeedback && mounted) {
            _chipSnack('Location permission was denied');
          }
          setState(() => _isFetchingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (showFeedback && mounted) {
          _chipSnack('Location permission is permanently denied in settings');
        }
        setState(() => _isFetchingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (!mounted) return;

      final liveLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _userLocation = liveLatLng;
        _isFetchingLocation = false;
      });

      _animatedMapMove(liveLatLng, 15.2);

      if (showFeedback && mounted) {
        _chipSnack('📍 Current location locked');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
        if (showFeedback) {
          _chipSnack('Could not fetch current GPS location');
        }
      }
    }
  }

  /// Generates dynamic gas stations with real area/landmark addresses
  List<MockGasStation> _generateStationsForLocation(LatLng center) {
    const distanceCalc = Distance();

    final templates = [
      (
        latOffset: 0.0032,
        lngOffset: 0.0025,
        name: 'Navana CNG & Petrol',
        area: 'Kamal Ataturk Ave',
        fuels: 'Octane • Petrol • CNG',
        rating: 4.8,
      ),
      (
        latOffset: -0.0035,
        lngOffset: 0.0045,
        name: 'Trust Filling Station',
        area: 'Gulshan Avenue',
        fuels: 'Diesel • Octane • EV',
        rating: 4.6,
      ),
      (
        latOffset: 0.0048,
        lngOffset: -0.0038,
        name: 'Clean Fuel & Power',
        area: 'Airport Expressway',
        fuels: 'Super Octane • EV Fast',
        rating: 4.9,
      ),
      (
        latOffset: -0.0028,
        lngOffset: -0.0042,
        name: 'City Express Fuel Hub',
        area: 'Mohakhali Link Rd',
        fuels: 'Octane • Diesel • LPG',
        rating: 4.7,
      ),
    ];

    return List.generate(templates.length, (i) {
      final t = templates[i];
      final stationLoc = LatLng(
        center.latitude + t.latOffset,
        center.longitude + t.lngOffset,
      );
      final distMeters =
          distanceCalc.as(LengthUnit.Meter, center, stationLoc);

      final distStr = distMeters < 1000
          ? '${t.area} • ${distMeters.round()} m'
          : '${t.area} • ${(distMeters / 1000).toStringAsFixed(1)} km';

      return MockGasStation(
        id: 'st_$i',
        name: t.name,
        distance: distStr,
        fuelTypes: t.fuels,
        rating: t.rating,
        location: stationLoc,
      );
    });
  }

  Future<void> _onToggleStations() async {
    if (_isLoadingStations) return;

    if (_showStations) {
      _closeStations();
      return;
    }

    setState(() => _isLoadingStations = true);
    await Future.delayed(const Duration(milliseconds: 550));

    if (!mounted) return;

    LatLng currentCenter = _userLocation;
    try {
      currentCenter = _mapController.camera.center;
    } catch (_) {
      currentCenter = _userLocation;
    }

    final newStations = _generateStationsForLocation(currentCenter);

    setState(() {
      _isLoadingStations = false;
      _showStations = true;
      _stations = newStations;
      _selectedStationIndex = 0;
    });

    if (newStations.isNotEmpty) {
      _animatedMapMove(newStations.first.location, 15.0);
    }
  }

  void _closeStations() {
    setState(() {
      _showStations = false;
      _isLoadingStations = false;
    });
    _animatedMapMove(_userLocation, 14.8);
  }

  void _selectStation(int index) {
    if (index >= _stations.length) return;
    setState(() => _selectedStationIndex = index);
    if (_carouselController.hasClients) {
      _carouselController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
    _animatedMapMove(_stations[index].location, 15.4);
  }

  void _zoomIn() {
    try {
      final currentZoom = _mapController.camera.zoom;
      final currentCenter = _mapController.camera.center;
      if (currentZoom < 18.0) {
        _animatedMapMove(currentCenter, currentZoom + 1.0);
      }
    } catch (_) {}
  }

  void _zoomOut() {
    try {
      final currentZoom = _mapController.camera.zoom;
      final currentCenter = _mapController.camera.center;
      if (currentZoom > 9.0) {
        _animatedMapMove(currentCenter, currentZoom - 1.0);
      }
    } catch (_) {}
  }

  void _recenterUser() {
    _fetchLiveLocation(showFeedback: true);
  }

  void _onNavigateTo(MockGasStation station) {
    _animatedMapMove(station.location, 16.2);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              LucideIcons.navigation,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Starting navigation to ${station.name} (${station.distance})',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.cardElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _chipSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.cardElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const ColoredBox(color: Color(0xFF0F0F12));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Clean Minimalist Dark Map with Locked Rotation and Buffered Seamless Zoom
          LayoutBuilder(
            builder: (context, constraints) {
              if (!constraints.hasBoundedWidth ||
                  !constraints.hasBoundedHeight ||
                  constraints.maxWidth <= 0 ||
                  constraints.maxHeight <= 0) {
                return const ColoredBox(color: Color(0xFF0F0F12));
              }

              return Container(
                color: const Color(0xFF0F0F12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _userLocation,
                    initialZoom: 15.0,
                    minZoom: 8.5,
                    maxZoom: 18.5,
                    cameraConstraint: CameraConstraint.containCenter(
                      bounds: LatLngBounds(
                        const LatLng(-85.0, -180.0),
                        const LatLng(85.0, 180.0),
                      ),
                    ),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.drag |
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom |
                          InteractiveFlag.scrollWheelZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}@2x.png',
                      userAgentPackageName: 'com.fuel_log.app',
                      maxZoom: 19,
                      minZoom: 1,
                      keepBuffer: 3,
                      panBuffer: 1,
                      retinaMode: true,
                      subdomains: const ['a', 'b', 'c', 'd'],
                      tileBuilder: (context, tileWidget, tile) {
                        return ColoredBox(
                          color: const Color(0xFF0F0F12),
                          child: tileWidget,
                        );
                      },
                    ),
                    MarkerLayer(
                      markers: [
                        // User Current Location Puck
                        Marker(
                          point: _userLocation,
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          child: _UserLocationMarker(
                            isLocating: _isFetchingLocation,
                          ),
                        ),
                        // Dynamic Gas Station Markers (Wide horizontal layout)
                        if (_showStations)
                          for (var i = 0; i < _stations.length; i++)
                            Marker(
                              point: _stations[i].location,
                              width: 140,
                              height: 62,
                              alignment: Alignment.bottomCenter,
                              child: _MapStationMarker(
                                station: _stations[i],
                                isSelected: i == _selectedStationIndex,
                                onTap: () => _selectStation(i),
                              ),
                            ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // 2. Top Floating Controls with Frosted Glass Look
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                0,
              ),
              child: Column(
                children: [
                  const _TripStatsPill(
                    distanceKm: 0,
                    elapsed: Duration.zero,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _MapActionChips(
                    isLoadingStations: _isLoadingStations,
                    isStationsActive: _showStations,
                    onStations: _onToggleStations,
                    onNavigate: () =>
                        _chipSnack('navigateComingSoon'.tr()),
                  ),
                ],
              ),
            ),
          ),

          // 3. Compact Floating Map Toolbar (Zoom & Recenter)
          Positioned(
            right: AppSpacing.screenPadding,
            bottom: _showStations ? 220 : 120,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Joined Zoom In / Zoom Out Pill
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181F).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2E2E38),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: _zoomIn,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(9),
                          child: Icon(
                            LucideIcons.plus,
                            size: 17,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 1,
                        color: const Color(0xFF2E2E38),
                      ),
                      InkWell(
                        onTap: _zoomOut,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(9),
                          child: Icon(
                            LucideIcons.minus,
                            size: 17,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Recenter My Location Button
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181F).withValues(alpha: 0.94),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2E2E38),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: _recenterUser,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        LucideIcons.locateFixed,
                        size: 17,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottom Area: Clean Floating Stations Carousel or Standard FABs
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: _showStations && _stations.isNotEmpty
                  ? _NearbyStationsCarousel(
                      key: const ValueKey('stations_carousel'),
                      stations: _stations,
                      selectedIndex: _selectedStationIndex,
                      controller: _carouselController,
                      onPageChanged: (idx) {
                        setState(() => _selectedStationIndex = idx);
                        if (idx < _stations.length) {
                          try {
                            _mapController.move(
                              _stations[idx].location,
                              15.0,
                            );
                          } catch (_) {}
                        }
                      },
                      onStationSelected: _selectStation,
                      onNavigate: _onNavigateTo,
                      onClose: _closeStations,
                    )
                  : Padding(
                      key: const ValueKey('default_fabs'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FloatingActionButton(
                            heroTag: 'trip_manual_entry',
                            onPressed: () =>
                                showTripManualEntrySheet(context),
                            backgroundColor: AppColors.cardElevated,
                            foregroundColor: AppColors.primary,
                            elevation: 6,
                            shape: const CircleBorder(),
                            tooltip: 'manualTripEntry'.tr(),
                            child: const Icon(
                              LucideIcons.mapPin,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StartTripFab(
                              onPressed: () =>
                                  _chipSnack('tripGpsComingSoon'.tr()),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker({this.isLocating = false});

  final bool isLocating;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isLocating ? 44 : 38,
            height: isLocating ? 44 : 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF29B6F6).withValues(
                alpha: isLocating ? 0.4 : 0.2,
              ),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0288D1),
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0288D1).withValues(alpha: 0.7),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapActionChips extends StatelessWidget {
  const _MapActionChips({
    required this.isLoadingStations,
    required this.isStationsActive,
    required this.onStations,
    required this.onNavigate,
  });

  final bool isLoadingStations;
  final bool isStationsActive;
  final VoidCallback onStations;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MapChip(
            icon: LucideIcons.fuel,
            label: 'nearbyStations'.tr(),
            isLoading: isLoadingStations,
            isActive: isStationsActive,
            onTap: onStations,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MapChip(
            icon: LucideIcons.navigation,
            label: 'navigate'.tr(),
            isLoading: false,
            isActive: false,
            onTap: onNavigate,
          ),
        ),
      ],
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF18181F).withValues(alpha: 0.94),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: isActive
                  ? AppColors.primary
                  : const Color(0xFF2E2E38),
              width: isActive ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 15,
                  color: AppColors.primary,
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapStationMarker extends StatelessWidget {
  const _MapStationMarker({
    required this.station,
    required this.isSelected,
    required this.onTap,
  });

  final MockGasStation station;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Floating Horizontal Capsule Badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFF16161A).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF2E2E38),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    station.name.split(' ').first,
                    maxLines: 1,
                    softWrap: false,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    LucideIcons.star,
                    size: 10,
                    color: Color(0xFFFFB74D),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            // Clean Glowing Circular Icon Pin
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFF202028),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : AppColors.primary,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: isSelected ? 0.6 : 0.25,
                    ),
                    blurRadius: isSelected ? 12 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.fuel,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyStationsCarousel extends StatelessWidget {
  const _NearbyStationsCarousel({
    super.key,
    required this.stations,
    required this.selectedIndex,
    required this.controller,
    required this.onPageChanged,
    required this.onStationSelected,
    required this.onNavigate,
    required this.onClose,
  });

  final List<MockGasStation> stations;
  final int selectedIndex;
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onStationSelected;
  final ValueChanged<MockGasStation> onNavigate;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Clean Header Bar: "4 Stations Found" + Minimal Close (X)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181F).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(color: const Color(0xFF2E2E38)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.fuel,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
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
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181F).withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF2E2E38)),
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

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

              return _StationCarouselCard(
                station: station,
                isSelected: isSelected,
                onTap: () => onStationSelected(index),
                onNavigate: () => onNavigate(station),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StationCarouselCard extends StatelessWidget {
  const _StationCarouselCard({
    required this.station,
    required this.isSelected,
    required this.onTap,
    required this.onNavigate,
  });

  final MockGasStation station;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onNavigate;

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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: Title & Star Rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        station.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.star,
                          size: 11,
                          color: Color(0xFFFFB74D),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          station.rating.toString(),
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Fuel types
                Text(
                  station.fuelTypes,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),

                // Bottom row: Distance & Navigate Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          station.distance,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                    Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: onNavigate,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5.5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.navigation,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'navigate'.tr(),
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripStatsPill extends StatelessWidget {
  const _TripStatsPill({
    required this.distanceKm,
    required this.elapsed,
  });

  final double distanceKm;
  final Duration elapsed;

  String get _timeLabel {
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = elapsed.inHours;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:$m:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF18181F).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: const Color(0xFF2E2E38)),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.navigation,
            size: 15,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${distanceKm.toStringAsFixed(1)} ${'km'.tr()}',
            style: AppTextStyles.label.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              '|',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Text(
            _timeLabel,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartTripFab extends StatelessWidget {
  const _StartTripFab({required this.onPressed});

  final VoidCallback onPressed;

  static final _radius = BorderRadius.circular(AppSpacing.radiusXl);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: AppColors.primary,
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: _radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: _radius,
          child: Container(
            height: AppSpacing.buttonHeight,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.play,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'startTrip'.tr(),
                  style: AppTextStyles.button.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
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

class _LatLngTween extends Tween<LatLng> {
  _LatLngTween({required LatLng begin, required LatLng end})
      : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    final lat = begin!.latitude + (end!.latitude - begin!.latitude) * t;
    final lng = begin!.longitude + (end!.longitude - begin!.longitude) * t;
    return LatLng(lat, lng);
  }
}

