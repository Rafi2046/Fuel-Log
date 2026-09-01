part of '../trip_log_tab.dart';

/// Business logic for [TripLogTabState] (GPS, stations, navigation).
mixin TripLogTabController on State<TripLogTab>, TickerProviderStateMixin<TripLogTab> {
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
  StreamSubscription<Position>? _gpsStream;
  Timer? _tripTimer;
  Duration _tripDuration = Duration.zero;
  double _tripDistanceCoveredKm = 0.0;
  LatLng? _lastGpsPoint;
  LatLng? _tripStartLocation;
  DateTime? _tripStartedAt;
  bool _isGeneralTripTracking = false;
  final List<LatLng> _tripTrackPoints = [];

  late final MapController _mapController;
  late final PageController _carouselController;
  AnimationController? _mapAnimController;
  double _mapZoom = 15.0;
  LatLng _mapCenter = kDefaultUserLocation;

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

    final startCenter = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;

    final latTween = Tween<double>(
      begin: startCenter.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: startCenter.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: startZoom,
      end: clampedZoom,
    );

    _mapAnimController?.stop();
    _mapAnimController?.dispose();
    final controller = AnimationController(duration: duration, vsync: this);
    _mapAnimController = controller;

    final animation = CurvedAnimation(parent: controller, curve: curve);

    controller.addListener(() {
      try {
        final newCenter = LatLng(
          latTween.evaluate(animation),
          lngTween.evaluate(animation),
        );
        final newZoom = zoomTween.evaluate(animation);
        _mapController.move(newCenter, newZoom);
        _mapZoom = newZoom;
        _mapCenter = newCenter;
      } catch (_) {}
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
        if (_mapAnimController == controller) {
          _mapAnimController = null;
        }
      }
    });

    controller.forward();
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
    GasStationService.instance.clearCache();

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
      // Keep the map on the user's location — do not jump to the first station.
      _animatedMapMove(center, 14.6);
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
      if (movedM < 150) {
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

  void onTripAppLifecycle(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!_isGeneralTripTracking && !_isNavigating) return;
    if (_tripStartedAt == null) return;
    setState(() {
      _tripDuration = DateTime.now().difference(_tripStartedAt!);
    });
  }

  void _syncTripElapsedFromClock() {
    if (_tripStartedAt == null) return;
    _tripDuration = DateTime.now().difference(_tripStartedAt!);
    NotificationService().updateActiveTripNotification(
      distanceKm: _tripDistanceCoveredKm,
      duration: _tripDuration,
      destination: _navigatingStation?.name,
    );
  }

  void _startTripClock() {
    _tripTimer?.cancel();
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _tripStartedAt == null) return;
      setState(_syncTripElapsedFromClock);
    });
  }

  LocationSettings _tripLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
        intervalDuration: const Duration(seconds: 1),
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 2,
    );
  }

  void _handleTripGpsPosition(Position position) {
    if (!mounted) return;
    if (!_isGeneralTripTracking && !_isNavigating) return;
    if (position.accuracy > 65) return;

    final currentLatLng = LatLng(position.latitude, position.longitude);

    if (_lastGpsPoint != null) {
      final deltaM = _distanceCalc.as(
        LengthUnit.Meter,
        _lastGpsPoint!,
        currentLatLng,
      );
      if (deltaM >= 2.0 && deltaM < 500.0) {
        _tripDistanceCoveredKm += deltaM / 1000.0;
        _lastGpsPoint = currentLatLng;
        _tripTrackPoints.add(currentLatLng);
      } else if (deltaM >= 12.0) {
        // GPS jump — move anchor without adding bogus distance.
        _lastGpsPoint = currentLatLng;
      }
    } else {
      _lastGpsPoint = currentLatLng;
      if (_tripTrackPoints.isEmpty) {
        _tripTrackPoints.add(currentLatLng);
      }
    }

    NotificationService().updateActiveTripNotification(
      distanceKm: _tripDistanceCoveredKm,
      duration: _tripDuration,
      destination: _navigatingStation?.name,
    );

    if (_isNavigating && _navigatingStation != null) {
      final remainingMeters = _distanceCalc.as(
        LengthUnit.Meter,
        currentLatLng,
        _navigatingStation!.location,
      );
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

      if (remainingMeters < 30) {
        _onArrivedAtStation(_navigatingStation!);
      }
    } else {
      setState(() => _userLocation = currentLatLng);
    }

    if (_isGeneralTripTracking || _isNavigating) {
      _animatedMapMove(
        currentLatLng,
        _mapController.camera.zoom,
        duration: const Duration(milliseconds: 140),
        curve: Curves.linear,
      );
    }
  }

  static const _distanceCalc = Distance();

  void _beginTripTracking() {
    _tripStartedAt = DateTime.now();
    _tripStartLocation = _userLocation;
    _tripDuration = Duration.zero;
    _tripDistanceCoveredKm = 0.0;
    _lastGpsPoint = _userLocation;
    _tripTrackPoints
      ..clear()
      ..add(_userLocation);
    NotificationService().updateActiveTripNotification(
      distanceKm: 0.0,
      duration: Duration.zero,
      destination: _navigatingStation?.name,
    );
  }

  void _resetTripTrackingState() {
    _tripTimer?.cancel();
    _tripTimer = null;
    _cancelGpsTracking();
    NotificationService().cancelActiveTripNotification();
    _tripDuration = Duration.zero;
    _tripDistanceCoveredKm = 0.0;
    _lastGpsPoint = null;
    _tripStartLocation = null;
    _tripStartedAt = null;
    _tripTrackPoints.clear();
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

    if (!mounted) return;

    await showTripManualEntrySheet(
      context,
      prefill: TripManualEntryPrefill(
        initialDistanceKm: distanceKm > 0 ? distanceKm : null,
        initialDurationSec: durationSec > 0 ? durationSec : null,
        initialDestination: destinationHint,
        startPoint: startPoint,
        endPoint: endPoint,
        startedAt: startedAt,
        endedAt: endedAt,
        source: 'gps',
        routeJson: _tripTrackPoints.length >= 2
            ? jsonEncode(
                _tripTrackPoints
                    .map((p) => [p.latitude, p.longitude])
                    .toList(),
              )
            : null,
      ),
    );
  }

  Future<void> _startNavigation(MockGasStation station) async {
    if (!await _ensureGpsReady(forTripTracking: true)) return;

    _beginTripTracking();
    _startTripClock();

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

    _startLiveGpsStream();
    _chipSnack('Navigation started to ${station.name}');
  }

  void _cancelGpsTracking() {
    _gpsPollingTimer?.cancel();
    _gpsPollingTimer = null;
    _gpsStream?.cancel();
    _gpsStream = null;
  }

  Future<bool> _ensureGpsReady({bool forTripTracking = false}) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _chipSnack('liveTripNeedGps'.tr());
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _chipSnack('liveTripNeedPermission'.tr());
      return false;
    }
    if (forTripTracking &&
        Platform.isAndroid &&
        permission == LocationPermission.whileInUse) {
      final upgraded = await Geolocator.requestPermission();
      if (upgraded == LocationPermission.denied ||
          upgraded == LocationPermission.deniedForever) {
        _chipSnack('liveTripNeedPermission'.tr());
        return false;
      }
    }
    return true;
  }

  void _startLiveGpsStream() {
    _cancelGpsTracking();
    final stream = Geolocator.getPositionStream(
      locationSettings: _tripLocationSettings(),
    );
    _gpsStream = stream.listen(_handleTripGpsPosition);
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
      _cancelGpsTracking();
      final distanceKm = _tripDistanceCoveredKm;
      final durationMin = _tripDuration.inMinutes;
      setState(() => _isGeneralTripTracking = false);
      _chipSnack(
        'liveTripFinished'.tr(
          namedArgs: {
            'km': distanceKm.toStringAsFixed(2),
            'min': '$durationMin',
          },
        ),
      );
      await _openTripEntryWithGpsPrefill();
      if (!mounted) return;
      _resetTripTrackingState();
      return;
    }

    if (!await _ensureGpsReady(forTripTracking: true)) return;
    await _fetchLiveLocation();
    if (!mounted) return;

    _beginTripTracking();
    setState(() => _isGeneralTripTracking = true);

    _startTripClock();
    _startLiveGpsStream();
    _chipSnack('liveTripStarted'.tr());
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
