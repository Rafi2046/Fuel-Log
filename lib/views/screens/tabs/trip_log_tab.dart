import 'dart:async';
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
import '../../../core/services/bd_fuel_rate_service.dart';
import '../../../core/services/gas_station_service.dart';
import '../../../core/services/navigation_routing_service.dart';
import '../../../models/fuel_price_model.dart';
import '../stations/station_detail_screen.dart';
import '../../widgets/station_list_modal_sheet.dart';
import '../../widgets/trip_manual_entry_sheet.dart';
import '../../widgets/weather_drive_card.dart';

class MockGasStation {
  final String id;
  final String name;
  final String distance;
  final String fuelTypes;
  final double rating;
  final LatLng location;
  final String? imageUrl;
  final StationInfo? stationInfo;

  const MockGasStation({
    required this.id,
    required this.name,
    required this.distance,
    required this.fuelTypes,
    required this.rating,
    required this.location,
    this.imageUrl,
    this.stationInfo,
  });

  /// Always BPC Octane — same nationwide (live via [BdFuelRateService]).
  double get primaryPrice => BdFuelRateService.instance.octane;

  StationInfo toStationInfo() {
    if (stationInfo != null) return stationInfo!;
    final rates = BdFuelRateService.instance.current;
    final now = DateTime.now();
    return StationInfo(
      id: id,
      name: name,
      address: distance,
      location: location,
      availableCategories: ['G', 'D', 'E', 'CNG', 'LPG'],
      prices: [
        StationPriceItem(
          fuelGradeCode: '95',
          price: rates.octane,
          lastUpdated: rates.updatedAt,
        ),
        StationPriceItem(
          fuelGradeCode: '91',
          price: rates.petrol,
          lastUpdated: rates.updatedAt,
        ),
        StationPriceItem(
          fuelGradeCode: 'D',
          price: rates.diesel,
          lastUpdated: rates.updatedAt,
        ),
        StationPriceItem(
          fuelGradeCode: 'CNG',
          price: FuelTypeGrade.cng.defaultBpcPrice,
          lastUpdated: now,
        ),
        StationPriceItem(
          fuelGradeCode: 'LPG',
          price: FuelTypeGrade.lpg.defaultBpcPrice,
          lastUpdated: now,
        ),
      ],
    );
  }
}

const LatLng kDefaultUserLocation = LatLng(23.7925, 90.4078);

/// Map-centric trip logging — free OpenStreetMap tiles (no API key / card).
class TripLogTab extends StatefulWidget {
  const TripLogTab({super.key, this.isActive = true});

  final bool isActive;

  @override
  TripLogTabState createState() => TripLogTabState();
}

class TripLogTabState extends State<TripLogTab> {
  bool _isLoadingStations = false;
  bool _showStations = false;
  bool _isFetchingLocation = false;
  bool _isNavigating = false;
  MockGasStation? _navigatingStation;
  NavigationRouteResult? _activeRoute;
  int _selectedStationIndex = 0;
  List<MockGasStation> _stations = [];
  LatLng _userLocation = kDefaultUserLocation;
  Timer? _gpsPollingTimer;
  Timer? _tripTimer;
  Duration _tripDuration = Duration.zero;
  double _tripDistanceCoveredKm = 0.0;
  LatLng? _lastGpsPoint;
  bool _isGeneralTripTracking = false;

  late final MapController _mapController;
  late final PageController _carouselController;
  double _mapZoom = 15.0;
  LatLng _mapCenter = kDefaultUserLocation;

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
    _tripTimer?.cancel();
    _gpsPollingTimer?.cancel();
    _mapController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!mounted) return;
    _mapZoom = destZoom;
    _mapCenter = destLocation;
    try {
      _mapController.move(destLocation, destZoom);
    } catch (_) {}
  }

  /// Used on tab focus — non-blocking location warm-up.
  Future<void> _fetchLiveLocation({bool showFeedback = false}) async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);
    try {
      final live = await _resolveLocationFast();
      if (!mounted) return;
      setState(() {
        _userLocation = live;
        _isFetchingLocation = false;
      });
      _animatedMapMove(live, 15.2);
      if (showFeedback) {
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

  /// Fast location: last-known first, then a short medium-accuracy fix.
  Future<LatLng> _resolveLocationFast() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _userLocation;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _userLocation;
      }

      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        final quick = LatLng(last.latitude, last.longitude);
        _userLocation = quick;
        return quick;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 2),
        ),
      );
      final live = LatLng(position.latitude, position.longitude);
      _userLocation = live;
      return live;
    } catch (_) {
      return _userLocation;
    }
  }

  Future<void> _onToggleStations() async {
    if (_isLoadingStations) return;

    if (_showStations) {
      _closeStations();
      return;
    }

    await openNearbyStations();
  }

  /// Opens nearby stations quickly (last-known GPS + short network budget).
  Future<void> openNearbyStations() async {
    if (_isLoadingStations) return;

    setState(() => _isLoadingStations = true);

    final center = await _resolveLocationFast();
    if (!mounted) return;

    _animatedMapMove(center, 14.8);

    final newStations = await GasStationService.instance.getNearbyStations(
      center: center,
    );

    if (!mounted) return;

    setState(() {
      _isLoadingStations = false;
      _showStations = true;
      _stations = newStations;
      _selectedStationIndex = 0;
      _userLocation = center;
    });

    if (newStations.isNotEmpty) {
      _animatedMapMove(newStations.first.location, 15.0);
      if (_carouselController.hasClients) {
        _carouselController.jumpToPage(0);
      }
    } else {
      _chipSnack('No stations found nearby');
    }

    // Refine GPS in background; refresh list only if we moved meaningfully.
    // ignore: unawaited_futures
    _refineStationsInBackground(center);
  }

  Future<void> _refineStationsInBackground(LatLng previous) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
      if (!mounted) return;
      final live = LatLng(position.latitude, position.longitude);
      final movedM = Distance()(previous, live);
      if (movedM < 400) {
        setState(() => _userLocation = live);
        return;
      }

      final stations = await GasStationService.instance.getNearbyStations(
        center: live,
      );
      if (!mounted || !_showStations) return;
      setState(() {
        _userLocation = live;
        _stations = stations;
        _selectedStationIndex = 0;
      });
      if (stations.isNotEmpty) {
        _animatedMapMove(stations.first.location, 15.0);
      }
    } catch (_) {}
  }

  void _closeStations() {
    setState(() {
      _showStations = false;
      _isLoadingStations = false;
    });
    _animatedMapMove(_userLocation, 14.8);
  }

  void _selectStation(int index, {bool openModal = false}) {
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
    if (openModal) {
      _openStationModalSheet(index);
    }
  }

  void _openStationModalSheet([int initialIndex = 0]) {
    if (_stations.isEmpty) return;
    StationListModalSheet.show(
      context,
      stations: _stations,
      initialIndex: initialIndex,
      onStationSelected: (idx) {
        setState(() => _selectedStationIndex = idx);
        if (_carouselController.hasClients) {
          _carouselController.animateToPage(
            idx,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
        if (idx < _stations.length) {
          _animatedMapMove(_stations[idx].location, 15.4);
        }
      },
      onNavigate: (station) {
        _onNavigateTo(station);
      },
    );
  }

  void _zoomIn() {
    if (_mapZoom < 18.0) {
      _animatedMapMove(_mapCenter, (_mapZoom + 1.0).clamp(8.5, 18.0));
    }
  }

  void _zoomOut() {
    if (_mapZoom > 9.0) {
      _animatedMapMove(_mapCenter, (_mapZoom - 1.0).clamp(8.5, 18.0));
    }
  }

  void _recenterUser() {
    _fetchLiveLocation(showFeedback: true);
  }

  void _onNavigateTo(MockGasStation station) {
    _startNavigation(station);
  }

  Future<void> _startNavigation(MockGasStation station) async {
    // Start live trip stopwatch
    _tripTimer?.cancel();
    _tripDuration = Duration.zero;
    _tripDistanceCoveredKm = 0.0;
    _lastGpsPoint = _userLocation;
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _tripDuration += const Duration(seconds: 1);
        });
      }
    });

    setState(() {
      _isNavigating = true;
      _navigatingStation = station;
      _showStations = false;
      _activeRoute = null;
    });

    final midLat = (_userLocation.latitude + station.location.latitude) / 2;
    final midLng = (_userLocation.longitude + station.location.longitude) / 2;
    _animatedMapMove(LatLng(midLat, midLng), 15.2);

    final routeResult =
        await NavigationRoutingService.instance.getDrivingRoute(
      start: _userLocation,
      destination: station.location,
    );

    if (!mounted) return;

    setState(() {
      _activeRoute = routeResult;
    });

    _startLiveGpsTracking(station);
    _chipSnack('Navigation started to ${station.name}');
  }

  void _cancelGpsTracking() {
    _gpsPollingTimer?.cancel();
    _gpsPollingTimer = null;
  }

  void _startLiveGpsTracking(MockGasStation station) {
    _cancelGpsTracking();
    const distanceCalc = Distance();

    // Immediate first check
    _updateNavLocation(station, distanceCalc);

    // Periodic live check every 2.5 seconds (rock solid, no MissingPluginException)
    _gpsPollingTimer = Timer.periodic(
      const Duration(milliseconds: 2500),
      (_) {
        if (!mounted || !_isNavigating) return;
        _updateNavLocation(station, distanceCalc);
      },
    );
  }

  Future<void> _updateNavLocation(
    MockGasStation station,
    Distance distanceCalc,
  ) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );

      if (!mounted || !_isNavigating) return;

      final currentLatLng = LatLng(position.latitude, position.longitude);
      final remainingMeters = distanceCalc.as(
        LengthUnit.Meter,
        currentLatLng,
        station.location,
      );

      // Accumulate live distance covered
      if (_lastGpsPoint != null) {
        final deltaM = distanceCalc.as(
          LengthUnit.Meter,
          _lastGpsPoint!,
          currentLatLng,
        );
        if (deltaM >= 2.0 && deltaM < 500.0) {
          _tripDistanceCoveredKm += (deltaM / 1000.0);
          _lastGpsPoint = currentLatLng;
        }
      } else {
        _lastGpsPoint = currentLatLng;
      }

      // Speed in m/s, fallback to ~25 km/h (6.9 m/s) if moving slow
      final speedMs = position.speed > 1.0 ? position.speed : 6.9;
      final remainingSeconds = (remainingMeters / speedMs).round();

      setState(() {
        _userLocation = currentLatLng;
        if (_activeRoute != null) {
          _activeRoute = NavigationRouteResult(
            points: _activeRoute!.points,
            distanceMeters: remainingMeters,
            durationSeconds: remainingSeconds,
            nextInstruction: _activeRoute!.nextInstruction,
          );
        }
      });

      // Smooth camera follow as you drive
      _animatedMapMove(currentLatLng, _mapZoom);

      // Arrival detection within 30 meters
      if (remainingMeters < 30) {
        _onArrivedAtStation(station);
      }
    } catch (_) {}
  }

  void _onArrivedAtStation(MockGasStation station) {
    _cancelGpsTracking();
    _tripTimer?.cancel();
    _chipSnack('🎉 You have arrived at ${station.name}!');
    showTripManualEntrySheet(context);
  }

  void _exitNavigation() {
    _tripTimer?.cancel();
    _tripTimer = null;
    _cancelGpsTracking();
    setState(() {
      _isNavigating = false;
      _navigatingStation = null;
      _activeRoute = null;
      _showStations = true;
      _tripDuration = Duration.zero;
      _tripDistanceCoveredKm = 0.0;
      _lastGpsPoint = null;
    });
    _animatedMapMove(_userLocation, 15.0);
  }

  void _toggleGeneralTripTracking() {
    if (_isGeneralTripTracking) {
      _tripTimer?.cancel();
      _tripTimer = null;
      _cancelGpsTracking();
      setState(() {
        _isGeneralTripTracking = false;
      });
      _chipSnack(
        'Trip finished! Total: ${_tripDistanceCoveredKm.toStringAsFixed(1)} km in ${_tripDuration.inMinutes} mins',
      );
      showTripManualEntrySheet(context);
    } else {
      _tripTimer?.cancel();
      _tripDuration = Duration.zero;
      _tripDistanceCoveredKm = 0.0;
      _lastGpsPoint = _userLocation;
      setState(() {
        _isGeneralTripTracking = true;
      });

      _tripTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _tripDuration += const Duration(seconds: 1);
          });
        }
      });

      const distanceCalc = Distance();
      _gpsPollingTimer?.cancel();
      _gpsPollingTimer = Timer.periodic(
        const Duration(milliseconds: 2500),
        (_) async {
          if (!mounted || !_isGeneralTripTracking) return;
          try {
            final position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 4),
              ),
            );
            if (!mounted || !_isGeneralTripTracking) return;
            final currentLatLng =
                LatLng(position.latitude, position.longitude);
            if (_lastGpsPoint != null) {
              final deltaM = distanceCalc.as(
                LengthUnit.Meter,
                _lastGpsPoint!,
                currentLatLng,
              );
              if (deltaM >= 2.0 && deltaM < 500.0) {
                _tripDistanceCoveredKm += (deltaM / 1000.0);
                _lastGpsPoint = currentLatLng;
              }
            } else {
              _lastGpsPoint = currentLatLng;
            }
            setState(() {
              _userLocation = currentLatLng;
            });
            try {
              _animatedMapMove(currentLatLng, _mapZoom);
            } catch (_) {}
          } catch (_) {}
        },
      );

      _chipSnack('Trip tracking started! Live timer & distance active');
    }
  }

  Future<void> _onTopNavigateChip() async {
    if (_isNavigating) {
      _exitNavigation();
      return;
    }

    if (_stations.isEmpty) {
      setState(() => _isLoadingStations = true);
      final list = await GasStationService.instance.getNearbyStations(
        center: _userLocation,
      );
      if (!mounted) return;
      setState(() {
        _isLoadingStations = false;
        _stations = list;
      });
    }

    if (_stations.isNotEmpty) {
      final target =
          _stations[_selectedStationIndex.clamp(0, _stations.length - 1)];
      _startNavigation(target);
    } else {
      _chipSnack('No nearby stations found to navigate');
    }
  }

  void _launchExternalVoiceNavigation() {
    if (_navigatingStation == null) return;
    NavigationRoutingService.instance.launchExternalMaps(
      destination: _navigatingStation!.location,
      stationName: _navigatingStation!.name,
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
          // 1. Free OpenStreetMap (dark-tinted) — no API key / card needed
          LayoutBuilder(
            builder: (context, constraints) {
              if (!constraints.hasBoundedWidth ||
                  !constraints.hasBoundedHeight ||
                  constraints.maxWidth <= 0 ||
                  constraints.maxHeight <= 0) {
                return const ColoredBox(color: Color(0xFF0F0F12));
              }

              return ColoredBox(
                color: const Color(0xFF0F0F12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _userLocation,
                    initialZoom: _mapZoom.clamp(8.5, 18.0),
                    minZoom: 8.5,
                    maxZoom: 18.0,
                    backgroundColor: const Color(0xFF0F0F12),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.drag |
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom |
                          InteractiveFlag.scrollWheelZoom,
                    ),
                    onPositionChanged: (camera, _) {
                      _mapZoom = camera.zoom;
                      _mapCenter = camera.center;
                    },
                  ),
                  children: [
                    // OpenStreetMap = more roads/labels (Google-like detail), free, no card.
                    // Single invert matrix → dark look without breaking tiles.
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.fuel_log',
                      maxNativeZoom: 19,
                      maxZoom: 18,
                      keepBuffer: 4,
                      panBuffer: 2,
                      retinaMode: true,
                      tileDisplay: const TileDisplay.instantaneous(),
                      tileBuilder: (context, tileWidget, tile) {
                        return ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            // Night invert (grayscale) — keeps street/label detail
                            -0.2126, -0.7152, -0.0722, 0, 255,
                            -0.2126, -0.7152, -0.0722, 0, 255,
                            -0.2126, -0.7152, -0.0722, 0, 255,
                            0, 0, 0, 1, 0,
                          ]),
                          child: tileWidget,
                        );
                      },
                    ),
                    if (_isNavigating &&
                        _activeRoute != null &&
                        _activeRoute!.points.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _activeRoute!.points,
                            strokeWidth: 9.0,
                            color:
                                const Color(0xFF00E5FF).withValues(alpha: 0.3),
                          ),
                          Polyline(
                            points: _activeRoute!.points,
                            strokeWidth: 4.8,
                            color: const Color(0xFF00E5FF),
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userLocation,
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          child: _UserLocationMarker(
                            isLocating: _isFetchingLocation,
                          ),
                        ),
                        if (_isNavigating && _navigatingStation != null)
                          Marker(
                            point: _navigatingStation!.location,
                            width: 40,
                            height: 40,
                            alignment: Alignment.topCenter,
                            child: const _DestinationFlagMarker(),
                          ),
                        if (!_isNavigating && _showStations)
                          for (var i = 0; i < _stations.length; i++)
                            Marker(
                              point: _stations[i].location,
                              width: 36,
                              height: 44,
                              alignment: Alignment.bottomCenter,
                              child: _StationPinMarker(
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

          // 2. Top Floating Controls: Turn HUD when navigating, standard pills otherwise
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                0,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _isNavigating && _navigatingStation != null
                    ? Column(
                        key: const ValueKey('nav_top_hud_col'),
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: _TripStatsPill(
                              distanceKm: _tripDistanceCoveredKm,
                              elapsed: _tripDuration,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _NavigationTopHud(
                            key: const ValueKey('nav_top_hud'),
                            station: _navigatingStation!,
                            route: _activeRoute,
                            onExit: _exitNavigation,
                          ),
                        ],
                      )
                    : Column(
                        key: const ValueKey('standard_top_hud'),
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: _TripStatsPill(
                              distanceKm: _tripDistanceCoveredKm,
                              elapsed: _tripDuration,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _MapActionChips(
                            isLoadingStations: _isLoadingStations,
                            isStationsActive: _showStations,
                            onStations: _onToggleStations,
                            onNavigate: _onTopNavigateChip,
                          ),
                        ],
                      ),
              ),
            ),
          ),

          // 3. Compact Floating Map Toolbar (Zoom & Recenter)
          Positioned(
            right: AppSpacing.screenPadding,
            bottom: _isNavigating
                ? 175
                : (_showStations ? 172 : 76),
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

          // 4. Bottom Area: Active Navigation ETA Card, Stations Carousel, or Standard FABs
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isNavigating &&
                    !_isGeneralTripTracking &&
                    !(_showStations && _stations.isNotEmpty))
                  const WeatherDriveTripBanner(),
                AnimatedSwitcher(
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
              child: _isNavigating && _navigatingStation != null
                  ? _ActiveNavigationBottomBar(
                      key: const ValueKey('active_nav_bar'),
                      station: _navigatingStation!,
                      route: _activeRoute,
                      onExit: _exitNavigation,
                      onExternalMaps: _launchExternalVoiceNavigation,
                      onLogFuel: () => showTripManualEntrySheet(context),
                    )
                  : (_showStations && _stations.isNotEmpty
                      ? _NearbyStationsCarousel(
                          key: const ValueKey('stations_carousel'),
                          stations: _stations,
                          selectedIndex: _selectedStationIndex,
                          controller: _carouselController,
                          onPageChanged: (idx) {
                            setState(() => _selectedStationIndex = idx);
                            if (idx < _stations.length) {
                              _animatedMapMove(
                                _stations[idx].location,
                                15.0,
                              );
                            }
                          },
                          onStationSelected: (idx) =>
                              _selectStation(idx, openModal: true),
                          onNavigate: _onNavigateTo,
                          onViewAll: () =>
                              _openStationModalSheet(_selectedStationIndex),
                        )
                      : Padding(
                          key: const ValueKey('default_fabs'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Manual entry — circular like reference
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF18181F)
                                      .withValues(alpha: 0.94),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF2E2E38),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () =>
                                        showTripManualEntrySheet(context),
                                    child: const Center(
                                      child: Icon(
                                        LucideIcons.mapPin,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StartTripFab(
                                  isTracking: _isGeneralTripTracking,
                                  onPressed: _toggleGeneralTripTracking,
                                ),
                              ),
                            ],
                          ),
                        )),
            ),
              ],
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
          Container(
            width: isLocating ? 40 : 34,
            height: isLocating ? 40 : 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF29B6F6).withValues(
                alpha: isLocating ? 0.35 : 0.2,
              ),
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0288D1),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationFlagMarker extends StatelessWidget {
  const _DestinationFlagMarker();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      LucideIcons.flag,
      size: 22,
      color: Color(0xFF00E5FF),
    );
  }
}

class _StationPinMarker extends StatelessWidget {
  const _StationPinMarker({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        LucideIcons.mapPin,
        size: isSelected ? 30 : 26,
        color: isSelected ? AppColors.primary : const Color(0xFF4A9EFF),
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

class _NearbyStationsCarousel extends StatelessWidget {
  const _NearbyStationsCarousel({
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
                color: const Color(0xFF18181F).withValues(alpha: 0.95),
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
                      border: Border.all(color: const Color(0xFF2E2E38)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                ),
              ),

              // 2. "View List" pill button
              Material(
                color: const Color(0xFF18181F).withValues(alpha: 0.95),
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
                      border: Border.all(color: const Color(0xFF2E2E38)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.list,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
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

              return _StationCarouselCard(
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

class _StationCarouselCard extends StatelessWidget {
  const _StationCarouselCard({
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
                // 1. Left Squircle Station Image Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 78,
                    height: double.infinity,
                    color: const Color(0xFF20202A),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (station.imageUrl != null)
                          station.imageUrl!.startsWith('http')
                              ? Image.network(
                                  station.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const _StationPlaceholder(),
                                )
                              : Image.asset(
                                  station.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const _StationPlaceholder(),
                                )
                        else
                          const _StationPlaceholder(),
                        // Bottom subtle OPEN badge
                        Positioned(
                          left: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF101014)
                                  .withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'OPEN',
                              style: TextStyle(
                                color: Color(0xFF81C784),
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 2. Right Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top row: Title & Star Rating & Price
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
                            '৳${station.primaryPrice.toStringAsFixed(0)}',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
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
                          fontSize: 10.5,
                        ),
                      ),

                      // Bottom row: Distance & Action Buttons (Rates + Navigate)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              station.distance,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // View Rates button
                          InkWell(
                            onTap: onViewRates,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryMuted,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Text(
                                'Rates',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Material(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(7),
                            child: InkWell(
                              onTap: onNavigate,
                              borderRadius: BorderRadius.circular(7),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.navigation,
                                      size: 10.5,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 3),
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
}

class _StationPlaceholder extends StatelessWidget {
  const _StationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF20202A),
      child: const Center(
        child: Icon(
          LucideIcons.fuel,
          color: AppColors.textTertiary,
          size: 22,
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
  const _StartTripFab({
    required this.onPressed,
    this.isTracking = false,
  });

  final VoidCallback onPressed;
  final bool isTracking;

  // Soft pill — matches reference Start Trip (not sharp rect, not full capsule)
  static final _radius = BorderRadius.circular(28);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: isTracking ? const Color(0xFFD32F2F) : AppColors.primary,
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: _radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: _radius,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isTracking ? LucideIcons.square : LucideIcons.play,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isTracking ? 'End Trip & Log' : 'startTrip'.tr(),
                  style: AppTextStyles.button.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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

class _NavigationTopHud extends StatelessWidget {
  const _NavigationTopHud({
    super.key,
    required this.station,
    required this.route,
    required this.onExit,
  });

  final MockGasStation station;
  final NavigationRouteResult? route;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF14141C).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          // Turn Maneuver Icon Box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              LucideIcons.arrowUpRight,
              color: Color(0xFF00E5FF),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Maneuver instruction + destination
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  route?.nextInstruction ?? 'Calculating optimal route...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Towards ${station.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF80DEEA),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Exit button
          IconButton(
            onPressed: onExit,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2E1A1A),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE53935).withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                LucideIcons.x,
                size: 14,
                color: Color(0xFFFF8A80),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveNavigationBottomBar extends StatelessWidget {
  const _ActiveNavigationBottomBar({
    super.key,
    required this.station,
    required this.route,
    required this.onExit,
    required this.onExternalMaps,
    required this.onLogFuel,
  });

  final MockGasStation station;
  final NavigationRouteResult? route;
  final VoidCallback onExit;
  final VoidCallback onExternalMaps;
  final VoidCallback onLogFuel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14141C).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2C2C3A),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Big Duration, Distance, and ETA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        route?.formattedDuration ?? '...',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${route?.formattedDistance ?? station.distance})',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Estimated Arrival: ${route?.formattedEta ?? '...'}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),

              // End Navigation Red Button
              Material(
                color: const Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onExit,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.x, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Exit',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFF262634), height: 1),
          const SizedBox(height: 10),

          // Bottom actions: Open in Google Maps voice nav + Log Fuel
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onExternalMaps,
                  icon: const Icon(LucideIcons.externalLink, size: 14),
                  label: const Text(
                    'Voice Nav (Maps)',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF80DEEA),
                    side: const BorderSide(color: Color(0xFF00838F)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onLogFuel,
                  icon: const Icon(LucideIcons.fuel, size: 14),
                  label: const Text(
                    'Log Fuel Here',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: Color(0xFF4E2C1A)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

