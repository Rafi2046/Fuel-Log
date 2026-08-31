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
  });

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
