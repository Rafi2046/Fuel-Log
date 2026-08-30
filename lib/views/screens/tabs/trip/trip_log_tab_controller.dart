part of '../trip_log_tab.dart';

/// Business logic for [TripLogTabState] (GPS, stations, navigation).
mixin TripLogTabController on State<TripLogTab> {
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
  LatLng? _tripStartLocation;
  DateTime? _tripStartedAt;
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
        if (!mounted) return;
        _fetchLiveLocation();
        try {
          _mapController.move(_userLocation, _mapZoom);
        } catch (_) {}
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

  void _animatedMapMove(
    LatLng destLocation,
    double destZoom, {
    Duration duration = const Duration(milliseconds: 320),
    Curve curve = Curves.easeInOutCubic,
  }) {
    if (!mounted) return;

    final clampedZoom = destZoom.clamp(8.5, 18.0);

    void applyInstantMove() {
      try {
        _mapController.move(destLocation, clampedZoom);
        _mapZoom = clampedZoom;
        _mapCenter = destLocation;
      } catch (_) {}
    }

    if (duration <= Duration.zero) {
      applyInstantMove();
      return;
    }

    final impl = _mapController;
    if (impl is MapControllerImpl) {
      try {
        impl.moveAnimatedRaw(
          destLocation,
          clampedZoom,
          duration: duration,
          curve: curve,
          hasGesture: false,
          source: MapEventSource.mapController,
        );
        return;
      } catch (_) {}
    }

    applyInstantMove();
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
    final zoom = _mapController.camera.zoom;
    if (zoom < 18.0) {
      _animatedMapMove(
        _mapController.camera.center,
        zoom + 1.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _zoomOut() {
    final zoom = _mapController.camera.zoom;
    if (zoom > 9.0) {
      _animatedMapMove(
        _mapController.camera.center,
        zoom - 1.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _recenterUser() {
    _fetchLiveLocation(showFeedback: true);
  }

  void _onNavigateTo(MockGasStation station) {
    _startNavigation(station);
  }

  void _beginTripTracking() {
    _tripStartedAt = DateTime.now();
    _tripStartLocation = _userLocation;
    _tripDuration = Duration.zero;
    _tripDistanceCoveredKm = 0.0;
    _lastGpsPoint = _userLocation;
  }

  void _resetTripTrackingState() {
    _tripTimer?.cancel();
    _tripTimer = null;
    _cancelGpsTracking();
    _tripDuration = Duration.zero;
    _tripDistanceCoveredKm = 0.0;
    _lastGpsPoint = null;
    _tripStartLocation = null;
    _tripStartedAt = null;
  }

  Future<void> _openTripEntryWithGpsPrefill({
    String? destinationHint,
  }) async {
    final distanceKm = _tripDistanceCoveredKm;
    final durationSec = _tripDuration.inSeconds;
    final startedAt = _tripStartedAt ??
        DateTime.now().subtract(Duration(seconds: durationSec));
    final endedAt = DateTime.now();
    final startPoint = _tripStartLocation;
    final endPoint = _lastGpsPoint ?? _userLocation;

    String? origin;
    String? destination = destinationHint;
    if (startPoint != null) {
      origin = await ReverseGeocodingService.resolveLabel(startPoint);
    }
    if (destination == null || destination.isEmpty) {
      destination = await ReverseGeocodingService.resolveLabel(endPoint);
    }

    if (!mounted) return;

    await showTripManualEntrySheet(
      context,
      prefill: TripManualEntryPrefill(
        initialDistanceKm: distanceKm > 0 ? distanceKm : null,
        initialDurationSec: durationSec > 0 ? durationSec : null,
        initialOrigin: origin,
        initialDestination: destination,
        startedAt: startedAt,
        endedAt: endedAt,
      ),
    );
  }

  Future<void> _startNavigation(MockGasStation station) async {
    // Start live trip stopwatch
    _tripTimer?.cancel();
    _beginTripTracking();
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

      // Light camera follow while driving — short pan, no zoom animation.
      _animatedMapMove(
        currentLatLng,
        _mapController.camera.zoom,
        duration: const Duration(milliseconds: 140),
        curve: Curves.linear,
      );

      // Arrival detection within 30 meters
      if (remainingMeters < 30) {
        _onArrivedAtStation(station);
      }
    } catch (_) {}
  }

  Future<void> _onArrivedAtStation(MockGasStation station) async {
    _cancelGpsTracking();
    _tripTimer?.cancel();
    _chipSnack('🎉 You have arrived at ${station.name}!');

    final destination = station.name;
    await _openTripEntryWithGpsPrefill(destinationHint: destination);

    if (!mounted) return;
    setState(() {
      _isNavigating = false;
      _navigatingStation = null;
      _activeRoute = null;
      _showStations = true;
    });
    _resetTripTrackingState();
    _animatedMapMove(_userLocation, 15.0);
  }

  void _exitNavigation() {
    _resetTripTrackingState();
    setState(() {
      _isNavigating = false;
      _navigatingStation = null;
      _activeRoute = null;
      _showStations = true;
    });
    _animatedMapMove(_userLocation, 15.0);
  }

  Future<void> _toggleGeneralTripTracking() async {
    if (_isGeneralTripTracking) {
      final distanceKm = _tripDistanceCoveredKm;
      final durationMin = _tripDuration.inMinutes;
      setState(() => _isGeneralTripTracking = false);
      _chipSnack(
        'Trip finished! Total: ${distanceKm.toStringAsFixed(1)} km in $durationMin mins',
      );
      await _openTripEntryWithGpsPrefill();
      if (!mounted) return;
      _resetTripTrackingState();
    } else {
      _tripTimer?.cancel();
      _beginTripTracking();
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
            _animatedMapMove(
              currentLatLng,
              _mapController.camera.zoom,
              duration: const Duration(milliseconds: 140),
              curve: Curves.linear,
            );
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
}
