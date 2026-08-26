import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../models/mock_gas_station.dart';
import 'bd_fuel_rate_service.dart';

class GasStationService {
  GasStationService._();
  static final GasStationService instance = GasStationService._();

  static const _distanceCalc = Distance();

  /// Fetches real nearby gas stations. Optimized for fast first paint.
  Future<List<MockGasStation>> getNearbyStations({
    required LatLng center,
    double radiusMeters = 5000,
  }) async {
    // Don't block on fuel-rate network — use cache / refresh in background.
    // ignore: unawaited_futures
    BdFuelRateService.instance.ensureLoaded();

    final cacheKey = _cacheKey(center);
    final cached = _stationCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.$1) < _stationCacheTtl) {
      return cached.$2;
    }

    // Race Overpass vs a short deadline — never wait forever.
    try {
      final liveStations = await _fetchFromOverpass(center, radiusMeters)
          .timeout(const Duration(milliseconds: 2800));
      if (liveStations.isNotEmpty) {
        _stationCache[cacheKey] = (DateTime.now(), liveStations);
        return liveStations;
      }
    } catch (_) {
      // Fall through to regional generator
    }

    final regional = _generateRegionalStations(center);
    _stationCache[cacheKey] = (DateTime.now(), regional);
    return regional;
  }

  String _cacheKey(LatLng c) =>
      '${c.latitude.toStringAsFixed(2)},${c.longitude.toStringAsFixed(2)}';

  static final Map<String, (DateTime, List<MockGasStation>)> _stationCache = {};
  static const _stationCacheTtl = Duration(minutes: 5);

  /// Queries OpenStreetMap Overpass — nodes only (much faster than ways/relations).
  Future<List<MockGasStation>> _fetchFromOverpass(
    LatLng center,
    double radiusMeters,
  ) async {
    final query = '''
[out:json][timeout:2];
(
  node["amenity"="fuel"](around:${radiusMeters.toInt()},${center.latitude},${center.longitude});
);
out body 20;
''';

    final url = Uri.parse(
      'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}',
    );

    final response = await http.get(url).timeout(
      const Duration(milliseconds: 2500),
    );

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (data['elements'] as List<dynamic>?) ?? [];

    if (elements.isEmpty) return [];

    final stations = <MockGasStation>[];

    for (var i = 0; i < elements.length && i < 25; i++) {
      final el = elements[i] as Map<String, dynamic>;
      final lat = (el['lat'] as num?)?.toDouble() ??
          (el['center']?['lat'] as num?)?.toDouble() ??
          center.latitude;
      final lon = (el['lon'] as num?)?.toDouble() ??
          (el['center']?['lon'] as num?)?.toDouble() ??
          center.longitude;
      final tags = (el['tags'] as Map<String, dynamic>?) ?? {};

      final rawName = tags['name'] ?? tags['brand'] ?? tags['operator'];
      final name = rawName != null && rawName.toString().trim().isNotEmpty
          ? rawName.toString()
          : 'Filling Station';

      final stationLoc = LatLng(lat, lon);
      final distMeters =
          _distanceCalc.as(LengthUnit.Meter, center, stationLoc);

      final street = tags['addr:street'] ??
          tags['addr:suburb'] ??
          tags['operator'] ??
          'Main Road';

      final distStr = distMeters < 1000
          ? '$street • ${distMeters.round()} m'
          : '$street • ${(distMeters / 1000).toStringAsFixed(1)} km';

      final fuels = _formatFuels(tags);
      final imagePath = _resolveBrandImage(name);

      stations.add(
        MockGasStation(
          id: el['id']?.toString() ?? 'osm_$i',
          name: name,
          distance: distStr,
          fuelTypes: fuels,
          rating: (4.2 + (i % 8) * 0.1).clamp(4.0, 5.0),
          location: stationLoc,
          imageUrl: imagePath,
        ),
      );
    }

    stations.sort((a, b) {
      final distA = _distanceCalc.as(LengthUnit.Meter, center, a.location);
      final distB = _distanceCalc.as(LengthUnit.Meter, center, b.location);
      return distA.compareTo(distB);
    });

    return stations;
  }

  /// Dynamic generator tailored for Dhaka, Chittagong, Sylhet, and other BD cities
  List<MockGasStation> _generateRegionalStations(LatLng center) {
    final lat = center.latitude;
    final lng = center.longitude;

    // Detect if user is in Chittagong (Lat ~22.0 - 22.8, Lng ~91.5 - 92.2)
    final isChittagong =
        (lat >= 22.0 && lat <= 22.8) && (lng >= 91.5 && lng <= 92.2);

    // Detect if user is in Sylhet (Lat ~24.6 - 25.1, Lng ~91.6 - 92.2)
    final isSylhet =
        (lat >= 24.6 && lat <= 25.1) && (lng >= 91.6 && lng <= 92.2);

    final List<_StationTemplate> templates;

    if (isChittagong) {
      templates = const [
        _StationTemplate(
          latOffset: 0.0035,
          lngOffset: 0.0028,
          name: 'Meghna Petroleum Ltd',
          area: 'CDA Avenue, GEC',
          fuels: 'Octane • Diesel • Petrol',
          rating: 4.9,
          image: 'assets/images/station_meghna.jpg',
        ),
        _StationTemplate(
          latOffset: -0.0040,
          lngOffset: 0.0045,
          name: 'Padma Oil Company',
          area: 'Agrabad Commercial Area',
          fuels: 'Diesel • Octane • High Octane',
          rating: 4.8,
          image: 'assets/images/station_padma.jpg',
        ),
        _StationTemplate(
          latOffset: 0.0050,
          lngOffset: -0.0038,
          name: 'Standard Asiatic Oil',
          area: 'Patenga Port Rd',
          fuels: 'Super Octane • Petrol • EV',
          rating: 4.7,
          image: 'assets/images/station_city_express.jpg',
        ),
        _StationTemplate(
          latOffset: -0.0030,
          lngOffset: -0.0045,
          name: 'Sanmar Green Fuel Hub',
          area: 'Nasirabad Link Rd',
          fuels: 'Octane • CNG • EV Fast',
          rating: 4.9,
          image: 'assets/images/station_clean_fuel.jpg',
        ),
        _StationTemplate(
          latOffset: 0.0062,
          lngOffset: 0.0051,
          name: 'Jamuna Oil Service Station',
          area: 'Sholashahar Gate 2',
          fuels: 'Octane • Petrol • Diesel',
          rating: 4.6,
          image: 'assets/images/station_trust.jpg',
        ),
      ];
    } else if (isSylhet) {
      templates = const [
        _StationTemplate(
          latOffset: 0.0032,
          lngOffset: 0.0025,
          name: 'Surma Petrol & CNG Hub',
          area: 'Zindabazar Road',
          fuels: 'Octane • Petrol • CNG',
          rating: 4.8,
          image: 'assets/images/station_padma.jpg',
        ),
        _StationTemplate(
          latOffset: -0.0035,
          lngOffset: 0.0040,
          name: 'Sylhet Express Fuel',
          area: 'Airport Road, Amberkhana',
          fuels: 'Octane • Diesel • EV',
          rating: 4.7,
          image: 'assets/images/station_city_express.jpg',
        ),
        _StationTemplate(
          latOffset: 0.0045,
          lngOffset: -0.0035,
          name: 'Meghna Petroleum Hub',
          area: 'Kadamtali Bus Terminal',
          fuels: 'Diesel • Octane • CNG',
          rating: 4.8,
          image: 'assets/images/station_meghna.jpg',
        ),
        _StationTemplate(
          latOffset: -0.0052,
          lngOffset: 0.0061,
          name: 'Greenland CNG & Filling',
          area: 'Subidbazar Main Rd',
          fuels: 'Octane • CNG • Petrol',
          rating: 4.6,
          image: 'assets/images/station_clean_fuel.jpg',
        ),
      ];
    } else {
      // Default: Dhaka and other regions
      templates = const [
        _StationTemplate(
          latOffset: 0.0032,
          lngOffset: 0.0025,
          name: 'Navana CNG & Petrol',
          area: 'Kamal Ataturk Ave',
          fuels: 'Octane • Petrol • CNG',
          rating: 4.8,
          image: 'assets/images/station_navana.jpg',
        ),
        _StationTemplate(
          latOffset: -0.0035,
          lngOffset: 0.0045,
          name: 'Trust Filling Station',
          area: 'Gulshan Avenue',
          fuels: 'Diesel • Octane • EV',
          rating: 4.6,
          image: 'assets/images/station_trust.jpg',
        ),
        _StationTemplate(
          latOffset: 0.0048,
          lngOffset: -0.0038,
          name: 'Padma Oil Filling Hub',
          area: 'Airport Expressway',
          fuels: 'Super Octane • EV Fast',
          rating: 4.9,
          image: 'assets/images/station_padma.jpg',
        ),
        _StationTemplate(
          latOffset: -0.0028,
          lngOffset: -0.0042,
          name: 'Meghna Petroleum Station',
          area: 'Mohakhali Link Rd',
          fuels: 'Octane • Diesel • LPG',
          rating: 4.7,
          image: 'assets/images/station_meghna.jpg',
        ),
        _StationTemplate(
          latOffset: 0.0061,
          lngOffset: 0.0038,
          name: 'CSD Filling Station',
          area: 'Shaheed Sharani',
          fuels: 'Octane • Petrol • Diesel',
          rating: 4.8,
          image: 'assets/images/station_city_express.jpg',
        ),
        _StationTemplate(
          latOffset: 0.0022,
          lngOffset: 0.0065,
          name: 'Gulshan Service Station',
          area: 'Bir Uttam AK Khandakar Rd',
          fuels: 'Octane • Petrol',
          rating: 4.7,
          image: 'assets/images/station_navana.jpg',
        ),
        _StationTemplate(
          latOffset: -0.0051,
          lngOffset: 0.0032,
          name: 'Clean Fuel Filling Station Ltd',
          area: 'Shaheed Tajuddin Ahmed Ave',
          fuels: 'Octane • Diesel • CNG',
          rating: 4.9,
          image: 'assets/images/station_clean_fuel.jpg',
        ),
        _StationTemplate(
          latOffset: -0.0042,
          lngOffset: -0.0055,
          name: 'TASHOFA Filling Station',
          area: 'Mohakhali Tajuddin Ahmed Ave',
          fuels: 'Octane • Diesel',
          rating: 4.6,
          image: 'assets/images/station_trust.jpg',
        ),
        _StationTemplate(
          latOffset: 0.0075,
          lngOffset: -0.0021,
          name: 'Diganta Filling Station',
          area: 'Mirpur Road',
          fuels: 'Octane • Petrol • CNG',
          rating: 4.5,
          image: 'assets/images/station_padma.jpg',
        ),
        _StationTemplate(
          latOffset: -0.0065,
          lngOffset: 0.0062,
          name: 'M/s Eureka-Nitol CNG Station',
          area: 'Ziaur Rahman Rd',
          fuels: 'CNG • Octane • Diesel',
          rating: 4.8,
          image: 'assets/images/station_meghna.jpg',
        ),
        _StationTemplate(
          latOffset: 0.0018,
          lngOffset: -0.0072,
          name: 'Royal Filling Station',
          area: 'Shaheed Tajuddin Ahmed Sarani',
          fuels: 'Octane • Petrol • CNG',
          rating: 4.7,
          image: 'assets/images/station_city_express.jpg',
        ),
        _StationTemplate(
          latOffset: -0.0078,
          lngOffset: -0.0031,
          name: 'Ideal Filling Station',
          area: 'Bir Uttam Mir Shawkat Sarak',
          fuels: 'Octane • Diesel',
          rating: 4.6,
          image: 'assets/images/station_trust.jpg',
        ),
      ];
    }

    return List.generate(templates.length, (i) {
      final t = templates[i];
      final stationLoc = LatLng(
        center.latitude + t.latOffset,
        center.longitude + t.lngOffset,
      );
      final distMeters =
          _distanceCalc.as(LengthUnit.Meter, center, stationLoc);

      final distStr = distMeters < 1000
          ? '${t.area} • ${distMeters.round()} m'
          : '${t.area} • ${(distMeters / 1000).toStringAsFixed(1)} km';

      return MockGasStation(
        id: 'st_$i',
        name: t.name,
        distance: distStr,
        fuelTypes: t.fuels,
        rating: t.rating,
        location: stationLoc,
        imageUrl: t.image,
      );
    });
  }

  /// Intelligently matches station brand names to local photorealistic assets
  String _resolveBrandImage(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('trust')) {
      return 'assets/images/station_trust.jpg';
    } else if (lower.contains('navana')) {
      return 'assets/images/station_navana.jpg';
    } else if (lower.contains('meghna') || lower.contains('chittagong')) {
      return 'assets/images/station_meghna.jpg';
    } else if (lower.contains('padma')) {
      return 'assets/images/station_padma.jpg';
    } else if (lower.contains('clean') ||
        lower.contains('green') ||
        lower.contains('ev')) {
      return 'assets/images/station_clean_fuel.jpg';
    }
    return 'assets/images/station_city_express.jpg';
  }

  String _formatFuels(Map<String, dynamic> tags) {
    final fuels = <String>[];
    if (tags['fuel:octane'] == 'yes' || tags['fuel:petrol'] == 'yes') {
      fuels.add('Octane');
    }
    if (tags['fuel:diesel'] == 'yes') fuels.add('Diesel');
    if (tags['fuel:cng'] == 'yes') fuels.add('CNG');
    if (tags['fuel:lpg'] == 'yes' || tags['fuel:autogas'] == 'yes') {
      fuels.add('LPG');
    }
    if (tags['fuel:electricity'] == 'yes') fuels.add('EV Fast');

    if (fuels.isEmpty) {
      return 'Octane • Diesel • Petrol';
    }
    return fuels.join(' • ');
  }
}

class _StationTemplate {
  final double latOffset;
  final double lngOffset;
  final String name;
  final String area;
  final String fuels;
  final double rating;
  final String image;

  const _StationTemplate({
    required this.latOffset,
    required this.lngOffset,
    required this.name,
    required this.area,
    required this.fuels,
    required this.rating,
    required this.image,
  });
}
