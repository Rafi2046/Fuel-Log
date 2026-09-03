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
  DateTime? _lastGpsAt;
  LatLng? _tripStartLocation;
  DateTime? _tripStartedAt;
  bool _isGeneralTripTracking = false;
  final List<LatLng> _tripTrackPoints = [];

  late final MapController _mapController;
  late final PageController _carouselController;
  AnimationController? _mapAnimController;
  double _mapZoom = 15.0;
  LatLng _mapCenter = kDefaultUserLocation;
  bool _mapIsOnline = true;
  int _mapTileGeneration = 0;
  Timer? _networkCheckTimer;

  void _startMapNetworkMonitor() {
    unawaited(_checkMapNetwork());
    _networkCheckTimer?.cancel();
    _networkCheckTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => unawaited(_checkMapNetwork()),
    );
  }

  void _stopMapNetworkMonitor() {
    _networkCheckTimer?.cancel();
    _networkCheckTimer = null;
  }

  Future<void> _checkMapNetwork() async {
    final online = await NetworkStatus.canReachMapTiles();
    if (!mounted) return;
    if (online == _mapIsOnline) return;
    setState(() {
      _mapIsOnline = online;
      if (online) _mapTileGeneration++;
    });
  }

  bool get _canMoveMap {
    if (!mounted) return false;
    try {
      final camera = _mapController.camera;
      final size = camera.nonRotatedSize;
      if (!size.isFinite || size.width <= 0 || size.height <= 0) {
        return false;
      }
      return camera.zoom.isFinite &&
          camera.center.latitude.isFinite &&
          camera.center.longitude.isFinite;
    } catch (_) {
      return false;
    }
  }

  void _safeMoveMap(LatLng center, double zoom) {
    if (!center.latitude.isFinite ||
        !center.longitude.isFinite ||
        !zoom.isFinite) {
      return;
    }
    final clampedZoom = zoom.clamp(AppMapTiles.minZoom, AppMapTiles.maxZoom);
    _mapCenter = center;
    _mapZoom = clampedZoom;
    if (!_canMoveMap) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_canMoveMap) {
          try {
            _mapController.move(center, clampedZoom);
          } catch (_) {}
        }
      });
      return;
    }
    try {
      _mapController.move(center, clampedZoom);
    } catch (_) {}
  }

  Future<void> _retryMapTiles() async {
    setState(() => _mapTileGeneration++);
    await _checkMapNetwork();
    if (!mounted) return;
    _safeMoveMap(_userLocation, _mapZoom);
  }

  @override
  void didUpdateWidget(covariant TripLogTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      unawaited(_checkMapNetwork());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fetchLiveLocation();
        _safeMoveMap(_userLocation, _mapZoom);
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
    if (!destLocation.latitude.isFinite ||
        !destLocation.longitude.isFinite ||
        !destZoom.isFinite) {
      return;
    }

    final clampedZoom =
        destZoom.clamp(AppMapTiles.minZoom, AppMapTiles.maxZoom);

    void applyInstantMove() {
      _safeMoveMap(destLocation, clampedZoom);
    }

    if (duration <= Duration.zero || !_canMoveMap) {
      applyInstantMove();
      return;
    }

    final startCenter = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;
    if (!startCenter.latitude.isFinite ||
        !startCenter.longitude.isFinite ||
        !startZoom.isFinite) {
      applyInstantMove();
      return;
    }

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
      if (!_canMoveMap) return;
      try {
        final newCenter = LatLng(
          latTween.evaluate(animation),
          lngTween.evaluate(animation),
        );
        final newZoom = zoomTween.evaluate(animation);
        if (newCenter.latitude.isFinite &&
            newCenter.longitude.isFinite &&
            newZoom.isFinite) {
          _mapController.move(newCenter, newZoom);
          _mapZoom = newZoom;
          _mapCenter = newCenter;
        }
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
    if (!_canMoveMap) return;
    final zoom = _mapController.camera.zoom;
    if (zoom < AppMapTiles.maxZoom) {
      _animatedMapMove(
        _mapController.camera.center,
        zoom + 1.0,
        duration: Duration.zero,
      );
    }
  }

  void _zoomOut() {
    if (!_canMoveMap) return;
    final zoom = _mapController.camera.zoom;
    if (zoom > AppMapTiles.minZoom) {
      _animatedMapMove(
        _mapController.camera.center,
        zoom - 1.0,
        duration: Duration.zero,
      );
    }
  }

  void _recenterUser() {
    _resetMapNorth();
    _fetchLiveLocation(showFeedback: true);
  }

  void _resetMapNorth() {
    try {
      _mapController.rotate(0);
    } catch (_) {}
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
        distanceFilter: 3,
        intervalDuration: const Duration(seconds: 2),
        forceLocationManager: false,
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,
    );
  }

  // ── GPS Trip Tracking — Production-Grade Algorithm ─────────────────────

  // Kalman-inspired position filter state.
  double _kalmanLat = 0;
  double _kalmanLng = 0;
  double _kalmanVariance = 1e6; // starts uncertain
  int _consecutiveRejects = 0;
  int _acceptedSamples = 0;
  double _maxSpeedSoFar = 0;

  // Tuning constants.
  static const _accuracyHardCap = 30.0; // reject anything worse than 30m
  static const _minMovementM = 5.0; // minimum Haversine delta to count
  static const _maxJumpM = 180.0; // reject teleports > 180m (~650 km/h)
  static const _minSpeedMs = 1.2; // ~4.3 km/h — walking pace floor
  static const _driftAnchorM = 25.0; // reset anchor without adding distance
  static const _coldStartSamples = 3; // discard first N for GPS warm-up
  static const _processNoisePerSec = 4.0; // m² per second of process noise

  /// 1-D Kalman update for latitude or longitude (in meters).
  double _kalman1D(double measured, double current, double measVariance) {
    final gain = _kalmanVariance / (_kalmanVariance + measVariance);
    final updated = current + gain * (measured - current);
    _kalmanVariance = (1 - gain) * _kalmanVariance;
    return updated;
  }

  void _kalmanPredict(double dtSec) {
    _kalmanVariance += _processNoisePerSec * dtSec;
  }

  void _handleTripGpsPosition(Position position) {
    if (!mounted) return;
    if (!_isGeneralTripTracking && !_isNavigating) return;

    // ── Gate 1: hard accuracy reject ──
    if (position.accuracy > _accuracyHardCap) {
      _consecutiveRejects++;
      // After many consecutive rejects, relax slightly to avoid total blackout.
      if (_consecutiveRejects < 10 || position.accuracy > 50) return;
    }
    _consecutiveRejects = 0;

    final rawLatLng = LatLng(position.latitude, position.longitude);
    final sampleTime = position.timestamp;
    final measVariance = position.accuracy * position.accuracy;

    // ── Gate 2: Kalman filter ──
    LatLng filteredLatLng;
    if (_lastGpsPoint == null || _kalmanVariance > 1e5) {
      // Cold start — seed filter with this reading.
      _kalmanLat = position.latitude;
      _kalmanLng = position.longitude;
      _kalmanVariance = measVariance;
      filteredLatLng = rawLatLng;
    } else {
      final dtSec = _lastGpsAt != null
          ? sampleTime.difference(_lastGpsAt!).inMilliseconds / 1000.0
          : 1.0;
      if (dtSec <= 0) return;

      _kalmanPredict(dtSec);

      // Reject measurements that are too far from prediction (chi² gate).
      final innovLat = position.latitude - _kalmanLat;
      final innovLng = position.longitude - _kalmanLng;
      // Approximate meters from degree delta at this latitude.
      final mPerDegLat = 111320.0;
      final mPerDegLng =
          111320.0 * cos(_kalmanLat * pi / 180.0);
      final innovM = sqrt(
        (innovLat * mPerDegLat) * (innovLat * mPerDegLat) +
            (innovLng * mPerDegLng) * (innovLng * mPerDegLng),
      );
      final totalVariance = _kalmanVariance + measVariance;
      final chiSq = (innovM * innovM) / totalVariance;

      // 3-sigma gate (~99.7%) — reject wild outliers.
      if (chiSq > 9.0 && _acceptedSamples > _coldStartSamples) {
        // Don't update filter; discard this sample.
        return;
      }

      _kalmanLat = _kalman1D(position.latitude, _kalmanLat, measVariance);
      _kalmanLng = _kalman1D(position.longitude, _kalmanLng, measVariance);
      filteredLatLng = LatLng(_kalmanLat, _kalmanLng);
    }

    _acceptedSamples++;

    // ── Gate 3: distance + speed validation ──
    if (_lastGpsPoint != null && _lastGpsAt != null) {
      final deltaM = _distanceCalc.as(
        LengthUnit.Meter,
        _lastGpsPoint!,
        filteredLatLng,
      );
      final elapsedSec =
          sampleTime.difference(_lastGpsAt!).inMilliseconds / 1000.0;

      if (elapsedSec > 0) {
        // Prefer device-reported speed when valid (> 0 and not 0.0 fallback).
        final deviceSpeedMs =
            position.speed > 0.1 && position.speedAccuracy < 5.0
                ? position.speed
                : null;
        final impliedSpeedMs = deltaM / elapsedSec;
        final speedMs = deviceSpeedMs ?? impliedSpeedMs;

        // Track max observed speed for adaptive jump capping.
        if (speedMs > _minSpeedMs && speedMs < 50) {
          _maxSpeedSoFar = max(_maxSpeedSoFar, speedMs);
        }

        // Adaptive jump cap: max(180m, 3× maxSpeed × dt).
        final adaptiveJumpCap =
            max(_maxJumpM, _maxSpeedSoFar * 3.0 * elapsedSec);

        final isMoving = speedMs >= _minSpeedMs &&
            deltaM >= _minMovementM &&
            deltaM < adaptiveJumpCap;
        final isAccurate =
            position.accuracy <= 20 || speedMs >= 3.0;

        // Skip first few samples (GPS warm-up jitter).
        final warmedUp = _acceptedSamples > _coldStartSamples;

        if (isMoving && isAccurate && warmedUp) {
          _tripDistanceCoveredKm += deltaM / 1000.0;
          _lastGpsPoint = filteredLatLng;
          _tripTrackPoints.add(filteredLatLng);
        } else if (deltaM >= _driftAnchorM) {
          // Stationary drift reset — move anchor without adding distance.
          _lastGpsPoint = filteredLatLng;
        }
      }
    } else {
      _lastGpsPoint = filteredLatLng;
      if (_tripTrackPoints.isEmpty) {
        _tripTrackPoints.add(filteredLatLng);
      }
    }
    _lastGpsAt = sampleTime;

    NotificationService().updateActiveTripNotification(
      distanceKm: _tripDistanceCoveredKm,
      duration: _tripDuration,
      destination: _navigatingStation?.name,
    );

    // Update map / navigation state with filtered position.
    final displayLatLng = filteredLatLng;

    if (_isNavigating && _navigatingStation != null) {
      final remainingMeters = _distanceCalc.as(
        LengthUnit.Meter,
        displayLatLng,
        _navigatingStation!.location,
      );
      final speedMs = position.speed > 1.0 ? position.speed : 6.9;
      final remainingSeconds = (remainingMeters / speedMs).round();

      setState(() {
        _userLocation = displayLatLng;
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
      setState(() => _userLocation = displayLatLng);
    }

    if (_isGeneralTripTracking || _isNavigating) {
      final z = _canMoveMap ? _mapController.camera.zoom : _mapZoom;
      _animatedMapMove(
        displayLatLng,
        z,
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
    _lastGpsPoint = null;
    _lastGpsAt = null;
    _kalmanLat = 0;
    _kalmanLng = 0;
    _kalmanVariance = 1e6;
    _consecutiveRejects = 0;
    _acceptedSamples = 0;
    _maxSpeedSoFar = 0;
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
    _lastGpsAt = null;
    _tripStartLocation = null;
    _tripStartedAt = null;
    _tripTrackPoints.clear();
    _kalmanLat = 0;
    _kalmanLng = 0;
    _kalmanVariance = 1e6;
    _consecutiveRejects = 0;
    _acceptedSamples = 0;
    _maxSpeedSoFar = 0;
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
