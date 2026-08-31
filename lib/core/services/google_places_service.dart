import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../models/mock_gas_station.dart';
import '../config/google_places_config.dart';
import 'station_image_resolver.dart';

/// Official Google Places (New) API — real station photos & ratings.
class GooglePlacesService {
  GooglePlacesService._();
  static final GooglePlacesService instance = GooglePlacesService._();

  static const _distanceCalc = Distance();
  static const _baseUrl = 'https://places.googleapis.com/v1';
  static const _fieldMask =
      'places.id,places.displayName,places.formattedAddress,'
      'places.location,places.photos,places.rating,places.primaryType';

  bool get isAvailable => GooglePlacesConfig.isConfigured;

  /// Nearby gas stations with user-contributed Google Maps photos.
  Future<List<MockGasStation>> searchNearbyGasStations({
    required LatLng center,
    double radiusMeters = 5000,
    int maxResults = 20,
  }) async {
    if (!isAvailable) return const [];

    final body = jsonEncode({
      'includedPrimaryTypes': ['gas_station'],
      'maxResultCount': maxResults.clamp(1, 20),
      'locationRestriction': {
        'circle': {
          'center': {
            'latitude': center.latitude,
            'longitude': center.longitude,
          },
          'radius': radiusMeters.clamp(500, 50000),
        },
      },
      'rankPreference': 'DISTANCE',
    });

    final response = await http
        .post(
          Uri.parse('$_baseUrl/places:searchNearby'),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': GooglePlacesConfig.apiKey,
            'X-Goog-FieldMask': _fieldMask,
          },
          body: body,
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return const [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final places = (data['places'] as List<dynamic>?) ?? [];
    final stations = <MockGasStation>[];

    for (var i = 0; i < places.length; i++) {
      final place = places[i] as Map<String, dynamic>;
      final station = _mapPlace(place, index: i, center: center);
      if (station != null) stations.add(station);
    }

    stations.sort((a, b) {
      final distA = _distanceCalc.as(LengthUnit.Meter, center, a.location);
      final distB = _distanceCalc.as(LengthUnit.Meter, center, b.location);
      return distA.compareTo(distB);
    });

    return stations;
  }

  /// Matches Google photos onto OSM stations by proximity.
  Future<List<MockGasStation>> enrichWithGooglePhotos(
    List<MockGasStation> stations, {
    required LatLng center,
    double radiusMeters = 5000,
  }) async {
    if (!isAvailable || stations.isEmpty) return stations;

    final googlePlaces = await searchNearbyGasStations(
      center: center,
      radiusMeters: radiusMeters,
    );
    if (googlePlaces.isEmpty) return stations;

    return stations.map((station) {
      if (station.googlePhotoResource != null) return station;

      final match = _findPhotoMatch(station, googlePlaces);
      if (match == null) return station;

      return station.copyWith(
        googlePhotoResource: match.googlePhotoResource,
        imageUrl: photoUrl(match.googlePhotoResource!),
        rating: match.rating > 0 ? match.rating : station.rating,
      );
    }).toList();
  }

  MockGasStation? _findPhotoMatch(
    MockGasStation station,
    List<MockGasStation> googlePlaces,
  ) {
    MockGasStation? best;
    var bestDist = double.infinity;

    for (final candidate in googlePlaces) {
      if (candidate.googlePhotoResource == null) continue;
      final dist = _distanceCalc.as(
        LengthUnit.Meter,
        station.location,
        candidate.location,
      );
      if (dist > 120 || dist >= bestDist) continue;
      best = candidate;
      bestDist = dist;
    }

    return best;
  }

  MockGasStation? _mapPlace(
    Map<String, dynamic> place, {
    required int index,
    required LatLng center,
  }) {
    final location = place['location'] as Map<String, dynamic>?;
    final lat = (location?['latitude'] as num?)?.toDouble();
    final lon = (location?['longitude'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    final displayName = place['displayName'] as Map<String, dynamic>?;
    final name = (displayName?['text'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;

    final photos = (place['photos'] as List<dynamic>?) ?? [];
    String? photoResource;
    if (photos.isNotEmpty) {
      photoResource = (photos.first as Map<String, dynamic>)['name'] as String?;
    }

    final address = (place['formattedAddress'] as String?) ?? name;
    final rating = (place['rating'] as num?)?.toDouble() ?? 0;
    final stationLoc = LatLng(lat, lon);

    return MockGasStation(
      id: place['id'] as String? ?? 'google_$index',
      name: name,
      distance: '',
      fuelTypes: 'Octane • Petrol • Diesel • CNG',
      rating: rating > 0 ? rating : 4.2,
      location: stationLoc,
      imageUrl: photoResource != null
          ? photoUrl(photoResource)
          : StationImageResolver.resolve(
              name: name,
              fuelTypes: 'Octane • Petrol • Diesel • CNG',
              location: stationLoc,
            ),
      addressHint: address,
      googlePhotoResource: photoResource,
    );
  }

  /// Public photo URL for [Image.network]. Requires API key in query string.
  static String photoUrl(String photoResource) {
    final encoded = Uri.encodeComponent(photoResource);
    return '$_baseUrl/$encoded/media'
        '?maxHeightPx=320&maxWidthPx=320'
        '&key=${GooglePlacesConfig.apiKey}';
  }
}
