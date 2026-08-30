part of '../trip_log_tab.dart';

mixin TripLogMapLayersMixin on TripLogTabController {
  Widget _buildMapLayer() {
    return LayoutBuilder(
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
              onMapReady: () {
                try {
                  _mapController.move(_mapCenter, _mapZoom);
                } catch (_) {}
              },
              onPositionChanged: (camera, _) {
                _mapZoom = camera.zoom;
                _mapCenter = camera.center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fuel_log',
                maxNativeZoom: 19,
                maxZoom: 18,
                retinaMode: false,
                keepBuffer: 6,
                panBuffer: 3,
                tileDisplay: const TileDisplay.fadeIn(
                  duration: Duration(milliseconds: 100),
                ),
                tileBuilder: (context, tileWidget, tile) {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
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
        for (var i = 0; i < _stations.length; i++)
          Marker(
            point: _stations[i].location,
            width: 36,
            height: 44,
            alignment: Alignment.bottomCenter,
            child: TripStationPinMarker(
              isSelected: i == _selectedStationIndex,
              onTap: () => _selectStation(i),
            ),
          ),
    ];
  }

}
