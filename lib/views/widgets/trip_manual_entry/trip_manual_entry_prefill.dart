import 'package:latlong2/latlong.dart';

/// Optional GPS / live-trip values to pre-fill the manual entry form.
class TripManualEntryPrefill {
  const TripManualEntryPrefill({
    this.initialDistanceKm,
    this.initialDurationSec,
    this.initialOrigin,
    this.initialDestination,
    this.startPoint,
    this.endPoint,
    this.startedAt,
    this.endedAt,
    this.source = 'gps',
    this.routeJson,
  });

  final double? initialDistanceKm;
  final int? initialDurationSec;
  final String? initialOrigin;
  final String? initialDestination;
  final LatLng? startPoint;
  final LatLng? endPoint;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String source;
  final String? routeJson;
}
