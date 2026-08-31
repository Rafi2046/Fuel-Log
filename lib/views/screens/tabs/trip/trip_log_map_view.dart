part of '../trip_log_tab.dart';

mixin TripLogMapViewMixin on TripLogMapLayersMixin {
  Widget buildTripMapScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildMapLayer(),
          _buildTopHud(),
          _buildZoomControls(context),
          _buildBottomArea(context),
        ],
      ),
    );
  }

  Widget _buildTopHud() {
    return SafeArea(
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
                      child: TripStatsPill(
                        distanceKm: _tripDistanceCoveredKm,
                        elapsed: _tripDuration,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    NavigationTopHud(
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
                      child: TripStatsPill(
                        distanceKm: _tripDistanceCoveredKm,
                        elapsed: _tripDuration,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TripMapActionChips(
                      isLoadingStations: _isLoadingStations,
                      isStationsActive: _showStations,
                      onStations: _onToggleStations,
                      onNavigate: _onTopNavigateChip,
                      onHistory: () => showTripHistoryModalSheet(context),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  double _estimateBottomOverlayHeight() {
    if (_isNavigating && _navigatingStation != null) return 136;
    if (_showStations && _stations.isNotEmpty) {
      // Header chips (~34) + gap (6) + carousel (132) + breathing room (8)
      return 180;
    }

    var height = 48.0; // Start Trip row
    final showWeather = !_isNavigating &&
        !_isGeneralTripTracking &&
        !(_showStations && _stations.isNotEmpty);
    if (showWeather) height += 64; // weather strip + margin
    return height;
  }

  Widget _buildZoomControls(BuildContext context) {
    final bottom = DashboardBottomBar.overlayBottom(context) +
        _estimateBottomOverlayHeight() +
        12;

    return Positioned(
      right: AppSpacing.screenPadding,
      bottom: bottom,
      child: TripMapZoomControls(
        onZoomIn: _zoomIn,
        onZoomOut: _zoomOut,
        onRecenter: _recenterUser,
      ),
    );
  }

  Widget _buildBottomArea(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: DashboardBottomBar.overlayBottom(context),
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
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: _isNavigating && _navigatingStation != null
                ? ActiveNavigationBottomBar(
                    key: const ValueKey('active_nav_bar'),
                    station: _navigatingStation!,
                    route: _activeRoute,
                    onExit: _exitNavigation,
                    onExternalMaps: _launchExternalVoiceNavigation,
                    onLogFuel: () => showTripManualEntrySheet(context),
                  )
                : (_showStations && _stations.isNotEmpty
                    ? NearbyStationsCarousel(
                        key: const ValueKey('stations_carousel'),
                        stations: _stations,
                        selectedIndex: _selectedStationIndex,
                        controller: _carouselController,
                        onPageChanged: (idx) {
                          setState(() => _selectedStationIndex = idx);
                          if (idx < _stations.length) {
                            _animatedMapMove(_stations[idx].location, 15.0);
                          }
                        },
                        onStationSelected: (idx) =>
                            _selectStation(idx, openModal: true),
                        onNavigate: _onNavigateTo,
                        onViewAll: () =>
                            _openStationModalSheet(_selectedStationIndex),
                      )
                    : TripDefaultFabs(
                        key: const ValueKey('default_fabs'),
                        isTracking: _isGeneralTripTracking,
                        onManualEntry: () =>
                            showTripManualEntrySheet(context),
                        onToggleTracking: _toggleGeneralTripTracking,
                        onHistory: () => showTripHistoryModalSheet(context),
                      )),
          ),
        ],
      ),
    );
  }
}
