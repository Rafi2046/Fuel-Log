import 'package:latlong2/latlong.dart';

import '../core/services/bd_fuel_rate_service.dart';
import 'fuel_price_model.dart';

class MockGasStation {
  final String id;
  final String name;
  final String distance;
  final String fuelTypes;
  final double rating;
  final LatLng location;
  final String? imageUrl;
  final StationInfo? stationInfo;
  /// Street/area label without distance (used to rebuild distance text).
  final String addressHint;
  /// Google Places photo resource name (user-contributed Maps photos).
  final String? googlePhotoResource;
  /// Straight-line (air) distance from the user.
  final double straightLineMeters;
  /// Road driving distance from OSRM when available.
  final double? drivingDistanceMeters;
  /// Estimated driving time in seconds from OSRM when available.
  final int? drivingDurationSeconds;

  const MockGasStation({
    required this.id,
    required this.name,
    required this.distance,
    required this.fuelTypes,
    required this.rating,
    required this.location,
    this.imageUrl,
    this.stationInfo,
    this.addressHint = '',
    this.googlePhotoResource,
    this.straightLineMeters = 0,
    this.drivingDistanceMeters,
    this.drivingDurationSeconds,
  });

  /// Distance used for sorting — prefers road distance when known.
  double get sortDistanceMeters =>
      drivingDistanceMeters ?? straightLineMeters;

  /// Primary distance label for UI (e.g. "4.1 km drive" or "1.1 km away").
  String get formattedDistanceBadge {
    if (drivingDistanceMeters != null && drivingDistanceMeters! > 0) {
      return '${_formatMeters(drivingDistanceMeters!)} drive';
    }
    if (straightLineMeters > 0) {
      return '${_formatMeters(straightLineMeters)} away';
    }
    return _extractDistanceFromLegacyString();
  }

  /// ETA label when road routing is available (e.g. "17 min").
  String? get formattedEta {
    final seconds = drivingDurationSeconds;
    if (seconds == null || seconds <= 0) return null;
    final mins = (seconds / 60).round();
    if (mins < 1) return '1 min';
    if (mins >= 60) {
      final hours = mins ~/ 60;
      final rem = mins % 60;
      return rem == 0 ? '${hours}h' : '${hours}h ${rem}m';
    }
    return '$mins min';
  }

  static String _formatMeters(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _extractDistanceFromLegacyString() {
    if (!distance.contains('•')) return distance;
    return distance.split('•').last.trim();
  }

  bool get usesGooglePhoto =>
      googlePhotoResource != null && googlePhotoResource!.isNotEmpty;

  MockGasStation copyWith({
    String? id,
    String? name,
    String? distance,
    String? fuelTypes,
    double? rating,
    LatLng? location,
    String? imageUrl,
    StationInfo? stationInfo,
    String? addressHint,
    String? googlePhotoResource,
    double? straightLineMeters,
    double? drivingDistanceMeters,
    int? drivingDurationSeconds,
  }) {
    return MockGasStation(
      id: id ?? this.id,
      name: name ?? this.name,
      distance: distance ?? this.distance,
      fuelTypes: fuelTypes ?? this.fuelTypes,
      rating: rating ?? this.rating,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      stationInfo: stationInfo ?? this.stationInfo,
      addressHint: addressHint ?? this.addressHint,
      googlePhotoResource: googlePhotoResource ?? this.googlePhotoResource,
      straightLineMeters: straightLineMeters ?? this.straightLineMeters,
      drivingDistanceMeters:
          drivingDistanceMeters ?? this.drivingDistanceMeters,
      drivingDurationSeconds:
          drivingDurationSeconds ?? this.drivingDurationSeconds,
    );
  }

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
