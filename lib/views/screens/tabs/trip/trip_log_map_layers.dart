part of '../trip_log_tab.dart';

mixin TripLogMapLayersMixin on TripLogTabController {
  Widget _buildMapLayer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth ||
            !constraints.hasBoundedHeight ||
            constraints.maxWidth <= 0 ||
            constraints.maxHeight <= 0) {
          return ColoredBox(color: AppColors.background);
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppMapTiles.backgroundColor,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _mapCenter,
                  initialZoom:
                      _mapZoom.clamp(AppMapTiles.minZoom, AppMapTiles.maxZoom),
                  minZoom: AppMapTiles.minZoom,
                  maxZoom: AppMapTiles.maxZoom,
                  backgroundColor: AppMapTiles.backgroundColor,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag |
                        InteractiveFlag.flingAnimation |
                        InteractiveFlag.pinchMove |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.rotate |
                        InteractiveFlag.doubleTapZoom |
                        InteractiveFlag.scrollWheelZoom,
                  ),
                  onPositionChanged: (camera, hasGesture) {
                    if (camera.zoom.isFinite &&
                        camera.center.latitude.isFinite &&
                        camera.center.longitude.isFinite) {
                      _mapZoom = camera.zoom;
                      _mapCenter = camera.center;
                    }
                  },
                ),
                children: [
                  ...AppMapTiles.stackedLayers(
                    keepBuffer: 4,
                    panBuffer: 2,
                    context: context,
                    key: ValueKey('map-tiles-$_mapTileGeneration'),
                  ),
                  if (_isNavigating &&
                      _activeRoute != null &&
                      _activeRoute!.points.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _activeRoute!.points,
                          strokeWidth: 9.0,
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                        ),
                        Polyline(
                          points: _activeRoute!.points,
                          strokeWidth: 4.8,
                          color: const Color(0xFF00E5FF),
                        ),
                      ],
                    ),
                  if (_isGeneralTripTracking && _tripTrackPoints.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: List<LatLng>.from(_tripTrackPoints),
                          strokeWidth: 5.0,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: _buildMarkers()),
                ],
              ),
            ),
            if (!_mapIsOnline) MapOfflineBanner(onRetry: _retryMapTiles),
          ],
        );
      },
    );
  }

  List<Marker> _buildMarkers() {
    return [
      Marker(
        point: _userLocation,
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: TripUserLocationMarker(isLocating: _isFetchingLocation),
      ),
      if (_isNavigating && _navigatingStation != null)
        Marker(
          point: _navigatingStation!.location,
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: const TripDestinationFlagMarker(),
        ),
      if (!_isNavigating && _showStations)
        for (var i = 0; i < _visibleStations.length; i++)
          Marker(
            point: _visibleStations[i].location,
            width: 36,
            height: 44,
            alignment: Alignment.bottomCenter,
            child: TripStationPinMarker(
              isSelected: i ==
                  _selectedStationIndex.clamp(
                    0,
                    _visibleStations.isEmpty ? 0 : _visibleStations.length - 1,
                  ),
              onTap: () {
                final original = _stations.indexOf(_visibleStations[i]);
                _selectStation(original >= 0 ? original : i);
              },
            ),
          ),
    ];
  }
}
