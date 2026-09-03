import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../models/mock_gas_station.dart';
import 'bd_fuel_rate_service.dart';
import 'google_places_service.dart';
import 'navigation_routing_service.dart';
import 'station_image_resolver.dart';

class GasStationService {
  GasStationService._();
  static final GasStationService instance = GasStationService._();

  static const _distanceCalc = Distance();
  static const _userAgent = 'FuelLogApp/1.0';
  static const _maxResults = 50;
  static const _overpassEndpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  /// Fetches real nearby gas stations sorted strictly by ascending distance.
  Future<List<MockGasStation>> getNearbyStations({
    required LatLng center,
    double radiusMeters = 5000,
  }) async {
    // Refresh fuel rates in background
    // ignore: unawaited_futures
    BdFuelRateService.instance.ensureLoaded();

    final cacheKey = _cacheKey(center);
    final cached = _stationCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.$1) < _stationCacheTtl) {
      return _withDistancesFrom(center, cached.$2);
    }

    // 1. Google Places (real user photos) when API key is configured
    List<MockGasStation> combined = [];
    if (GooglePlacesService.instance.isAvailable) {
      try {
        final googleStations =
            await GooglePlacesService.instance.searchNearbyGasStations(
          center: center,
          radiusMeters: radiusMeters,
        );
        combined.addAll(googleStations);
      } catch (_) {}
    }

    // 2. Live OSM queries (Overpass + Nominatim) in parallel
    final liveStations = await _fetchLiveStations(center, radiusMeters);

    // 3. Curated fallback — only within search radius
    final curatedStations =
        _getCuratedStationsForLocation(center, radiusMeters: radiusMeters);

    // 4. Merge with confidence scoring.
    // Trust order: Google/curated > OSM/Nominatim.
    for (final station in liveStations) {
      _upsertStationWithConfidence(
        candidate: station,
        target: combined,
        preferCandidate: false,
      );
    }
    for (final station in curatedStations) {
      _upsertStationWithConfidence(
        candidate: station,
        target: combined,
        preferCandidate: true,
      );
    }

    // 5. Attach Google photos to OSM stations when possible
    if (GooglePlacesService.instance.isAvailable && combined.isNotEmpty) {
      try {
        combined = await GooglePlacesService.instance.enrichWithGooglePhotos(
          combined,
          center: center,
          radiusMeters: radiusMeters,
        );
      } catch (_) {}
    }

    // 6. Sort by real distance and cap result count
    combined.sort((a, b) {
      final distA = _distanceCalc.as(LengthUnit.Meter, center, a.location);
      final distB = _distanceCalc.as(LengthUnit.Meter, center, b.location);
      return distA.compareTo(distB);
    });

    final withinRadius = combined
        .where(
          (s) =>
              _distanceCalc.as(LengthUnit.Meter, center, s.location) <=
              radiusMeters,
        )
        .take(_maxResults)
        .toList();

    final withStraightLine = _withDistancesFrom(center, withinRadius);
    final result = await _enrichWithDrivingDistances(center, withStraightLine);
    _stationCache[cacheKey] = (DateTime.now(), result);
    return result;
  }

  /// Fetches real road distances for the nearest stations (OSRM table API).
  Future<List<MockGasStation>> _enrichWithDrivingDistances(
    LatLng center,
    List<MockGasStation> stations, {
    int maxEnrich = 15,
  }) async {
    if (stations.isEmpty) return stations;

    final enrichCount = stations.length < maxEnrich ? stations.length : maxEnrich;
    final toEnrich = stations.take(enrichCount).toList();
    final rest = stations.skip(enrichCount).toList();

    final table = await NavigationRoutingService.instance.getDrivingDistancesTable(
      origin: center,
      destinations: toEnrich.map((s) => s.location).toList(),
    );

    final enriched = <MockGasStation>[];
    for (var i = 0; i < toEnrich.length; i++) {
      final station = toEnrich[i];
      final driving = i < table.length ? table[i] : null;
      enriched.add(
        _stationWithDistanceLabels(
          station,
          straightMeters: station.straightLineMeters,
          driving: driving,
        ),
      );
    }

    final enrichedRest = rest
        .map(
          (s) => _stationWithDistanceLabels(
            s,
            straightMeters: s.straightLineMeters,
          ),
        )
        .toList();

    final merged = [...enriched, ...enrichedRest]
      ..sort((a, b) => a.sortDistanceMeters.compareTo(b.sortDistanceMeters));
    return merged;
  }

  MockGasStation _stationWithDistanceLabels(
    MockGasStation s, {
    required double straightMeters,
    DrivingDistanceResult? driving,
  }) {
    return MockGasStation(
      id: s.id,
      name: s.name,
      distance: _formatDistanceLabel(
        s.addressHint,
        straightMeters,
        drivingMeters: driving?.distanceMeters,
        drivingSeconds: driving?.durationSeconds,
      ),
      fuelTypes: s.fuelTypes,
      rating: s.rating,
      location: s.location,
      imageUrl: s.imageUrl,
      stationInfo: s.stationInfo,
      addressHint: s.addressHint,
      googlePhotoResource: s.googlePhotoResource,
      straightLineMeters: straightMeters,
      drivingDistanceMeters: driving?.distanceMeters,
      drivingDurationSeconds: driving?.durationSeconds,
    );
  }

  List<MockGasStation> _withDistancesFrom(
    LatLng center,
    List<MockGasStation> stations,
  ) {
    return stations
        .map((s) {
          final distMeters =
              _distanceCalc.as(LengthUnit.Meter, center, s.location);
          return _stationWithDistanceLabels(
            s,
            straightMeters: distMeters,
          );
        })
        .toList()
      ..sort(
        (a, b) => a.sortDistanceMeters.compareTo(b.sortDistanceMeters),
      );
  }

  Future<List<MockGasStation>> _fetchLiveStations(
    LatLng center,
    double radiusMeters,
  ) async {
    final results = await Future.wait([
      _fetchFromOverpass(center, radiusMeters),
      _fetchFromNominatim(center, radiusMeters),
    ]);

    final merged = <MockGasStation>[];
    for (final batch in results) {
      for (final station in batch) {
        if (!_isDuplicate(station, merged)) {
          merged.add(station);
        }
      }
    }
    return merged;
  }

  String _cacheKey(LatLng c) =>
      '${c.latitude.toStringAsFixed(3)},${c.longitude.toStringAsFixed(3)}';

  static final Map<String, (DateTime, List<MockGasStation>)> _stationCache = {};
  static const _stationCacheTtl = Duration(minutes: 3);

  void clearCache() => _stationCache.clear();

  /// Queries OpenStreetMap Overpass (nodes, ways, relations).
  Future<List<MockGasStation>> _fetchFromOverpass(
    LatLng center,
    double radiusMeters,
  ) async {
    final query = '''
[out:json][timeout:10];
(
  nwr["amenity"="fuel"](around:${radiusMeters.toInt()},${center.latitude},${center.longitude});
  nwr["shop"="gas"](around:${radiusMeters.toInt()},${center.latitude},${center.longitude});
);
out center tags 60;
''';

    Object? lastError;
    for (final endpoint in _overpassEndpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: const {'User-Agent': _userAgent},
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 9));

        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final elements = (data['elements'] as List<dynamic>?) ?? [];
        if (elements.isEmpty) continue;

        final ranked = <({Map<String, dynamic> el, double dist})>[];
        for (final raw in elements) {
          final el = raw as Map<String, dynamic>;
          final lat = (el['lat'] as num?)?.toDouble() ??
              (el['center']?['lat'] as num?)?.toDouble();
          final lon = (el['lon'] as num?)?.toDouble() ??
              (el['center']?['lon'] as num?)?.toDouble();
          if (lat == null || lon == null) continue;
          final dist =
              _distanceCalc.as(LengthUnit.Meter, center, LatLng(lat, lon));
          ranked.add((el: el, dist: dist));
        }

        ranked.sort((a, b) => a.dist.compareTo(b.dist));

        final stations = <MockGasStation>[];
        for (var i = 0; i < ranked.length && i < _maxResults; i++) {
          final station = _stationFromOsmElement(
            ranked[i].el,
            center: center,
            index: i,
            source: 'osm',
          );
          if (station != null) stations.add(station);
        }
        if (stations.isNotEmpty) return stations;
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      // Both Overpass mirrors failed — caller falls back to Nominatim/curated.
    }
    return [];
  }

  /// Nominatim POI search inside a bounding box around [center].
  Future<List<MockGasStation>> _fetchFromNominatim(
    LatLng center,
    double radiusMeters,
  ) async {
    final delta = (radiusMeters / 111000).clamp(0.02, 0.08);
    final viewbox =
        '${center.longitude - delta},${center.latitude + delta},'
        '${center.longitude + delta},${center.latitude - delta}';

    final stations = <MockGasStation>[];
    for (final query in const [
      'filling station',
      'CNG station',
      'petrol pump',
    ]) {
      try {
        final uri = Uri.https(
          'nominatim.openstreetmap.org',
          '/search',
          {
            'q': query,
            'format': 'json',
            'addressdetails': '1',
            'limit': '15',
            'countrycodes': 'bd',
            'viewbox': viewbox,
            'bounded': '1',
          },
        );
        final response = await http
            .get(uri, headers: const {'User-Agent': _userAgent})
            .timeout(const Duration(seconds: 6));
        if (response.statusCode != 200) continue;

        final list = jsonDecode(response.body) as List<dynamic>;
        for (var i = 0; i < list.length; i++) {
          final map = list[i] as Map<String, dynamic>;
          final station = _stationFromNominatim(map, center: center, index: i);
          if (station == null) continue;
          final dist = _distanceCalc.as(
            LengthUnit.Meter,
            center,
            station.location,
          );
          if (dist > radiusMeters) continue;
          if (!_isDuplicate(station, stations)) stations.add(station);
        }
      } catch (_) {}
    }
    return stations;
  }

  MockGasStation? _stationFromOsmElement(
    Map<String, dynamic> el, {
    required LatLng center,
    required int index,
    required String source,
  }) {
    final lat = (el['lat'] as num?)?.toDouble() ??
        (el['center']?['lat'] as num?)?.toDouble();
    final lon = (el['lon'] as num?)?.toDouble() ??
        (el['center']?['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    final tags = (el['tags'] as Map<String, dynamic>?) ?? {};
    final rawName = tags['name'] ??
        tags['name:en'] ??
        tags['brand'] ??
        tags['operator'];
    final name = rawName != null && rawName.toString().trim().isNotEmpty
        ? rawName.toString().trim()
        : 'Filling Station';

    final stationLoc = LatLng(lat, lon);
    final street = tags['addr:street'] as String? ??
        tags['addr:suburb'] as String? ??
        tags['addr:road'] as String? ??
        tags['operator'] as String? ??
        'Fuel Point';

    return MockGasStation(
      id: '${source}_${el['id'] ?? index}',
      name: name,
      distance: '',
      fuelTypes: _formatFuels(tags),
      rating: _pseudoRating(name),
      location: stationLoc,
      imageUrl: StationImageResolver.resolve(
        name: name,
        fuelTypes: _formatFuels(tags),
        osmTags: tags,
        location: stationLoc,
      ),
      addressHint: street,
    );
  }

  MockGasStation? _stationFromNominatim(
    Map<String, dynamic> map, {
    required LatLng center,
    required int index,
  }) {
    final lat = double.tryParse('${map['lat']}');
    final lon = double.tryParse('${map['lon']}');
    if (lat == null || lon == null) return null;

    final display = map['display_name'] as String? ?? 'Filling Station';
    final osmClass = map['class'] as String?;
    final osmType = map['type'] as String?;
    final displayLower = display.toLowerCase();
    final isFuelPoi = (osmClass == 'amenity' && osmType == 'fuel') ||
        displayLower.contains('station') ||
        displayLower.contains('cng') ||
        displayLower.contains('petrol') ||
        displayLower.contains('filling');
    if (!isFuelPoi) return null;
    final name = (map['name'] as String?)?.trim().isNotEmpty == true
        ? (map['name'] as String).trim()
        : display.split(',').first.trim();

    final address = map['address'] as Map<String, dynamic>?;
    final street = address?['road'] as String? ??
        address?['suburb'] as String? ??
        address?['neighbourhood'] as String? ??
        display.split(',').skip(1).take(2).join(', ');

    return MockGasStation(
      id: 'nom_${index}_${lat.toStringAsFixed(5)}',
      name: name,
      distance: '',
      fuelTypes: 'Octane • Petrol • Diesel • CNG',
      rating: _pseudoRating(name),
      location: LatLng(lat, lon),
      imageUrl: StationImageResolver.resolve(
        name: name,
        fuelTypes: 'Octane • Petrol • Diesel • CNG',
        location: LatLng(lat, lon),
      ),
      addressHint: street,
    );
  }

  /// Curated real-world stations — only those within [radiusMeters].
  List<MockGasStation> _getCuratedStationsForLocation(
    LatLng center, {
    required double radiusMeters,
  }) {
    final list = <MockGasStation>[];

    for (var i = 0; i < _bangladeshRealStations.length; i++) {
      final item = _bangladeshRealStations[i];
      final stationLoc = LatLng(item.latitude, item.longitude);
      final distMeters =
          _distanceCalc.as(LengthUnit.Meter, center, stationLoc);
      if (distMeters > radiusMeters) continue;

      list.add(
        MockGasStation(
          id: 'real_st_$i',
          name: item.name,
          distance: '',
          fuelTypes: item.fuels,
          rating: item.rating,
          location: stationLoc,
          imageUrl: item.image,
          addressHint: item.area,
        ),
      );
    }

    return list;
  }

  String _formatDistanceLabel(
    String area,
    double straightMeters, {
    double? drivingMeters,
    int? drivingSeconds,
  }) {
    final place = area.trim().isEmpty ? 'Fuel Point' : area.trim();
    if (drivingMeters != null && drivingMeters > 0) {
      final distDisplay = drivingMeters < 1000
          ? '${drivingMeters.round()} m'
          : '${(drivingMeters / 1000).toStringAsFixed(1)} km';
      if (drivingSeconds != null && drivingSeconds > 0) {
        final mins = (drivingSeconds / 60).round();
        final eta = mins < 1 ? '1 min' : '$mins min';
        return '$place • $eta • $distDisplay drive';
      }
      return '$place • $distDisplay drive';
    }

    final distStr = straightMeters < 1000
        ? '${straightMeters.round()} m'
        : '${(straightMeters / 1000).toStringAsFixed(1)} km';
    return '$place • $distStr away';
  }

  bool _isDuplicate(MockGasStation candidate, List<MockGasStation> existing) {
    final candidateName = _normalizeName(candidate.name);
    for (final station in existing) {
      final dist = _distanceCalc.as(
        LengthUnit.Meter,
        candidate.location,
        station.location,
      );
      if (dist < 75) return true;

      final existingName = _normalizeName(station.name);
      if (candidateName == existingName) return true;
      if (candidateName.length > 4 &&
          existingName.length > 4 &&
          (candidateName.contains(existingName) ||
              existingName.contains(candidateName))) {
        return true;
      }
    }
    return false;
  }

  void _upsertStationWithConfidence({
    required MockGasStation candidate,
    required List<MockGasStation> target,
    required bool preferCandidate,
  }) {
    for (var i = 0; i < target.length; i++) {
      final current = target[i];
      if (!_looksLikeSameStation(candidate, current)) continue;

      final currentIsLowConfidence = _isLowConfidenceStation(current);
      final candidateIsLowConfidence = _isLowConfidenceStation(candidate);
      final shouldReplace = preferCandidate ||
          (currentIsLowConfidence && !candidateIsLowConfidence);

      if (shouldReplace) {
        target[i] = _mergeStationPreferred(candidate, current);
      }
      return;
    }
    target.add(candidate);
  }

  bool _looksLikeSameStation(MockGasStation a, MockGasStation b) {
    final dist = _distanceCalc.as(LengthUnit.Meter, a.location, b.location);
    if (dist < 120) return true;

    final aName = _normalizeName(a.name);
    final bName = _normalizeName(b.name);
    if (aName == bName) return true;
    if (aName.length > 5 &&
        bName.length > 5 &&
        (aName.contains(bName) || bName.contains(aName))) {
      return true;
    }
    return false;
  }

  bool _isLowConfidenceStation(MockGasStation s) {
    return s.id.startsWith('nom_') || s.id.startsWith('osm_');
  }

  MockGasStation _mergeStationPreferred(
    MockGasStation preferred,
    MockGasStation fallback,
  ) {
    return preferred.copyWith(
      googlePhotoResource:
          preferred.googlePhotoResource ?? fallback.googlePhotoResource,
      imageUrl: preferred.imageUrl ?? fallback.imageUrl,
      stationInfo: preferred.stationInfo ?? fallback.stationInfo,
    );
  }

  String _normalizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u0980-\u09FF]+'), ' ')
        .trim();
  }

  double _pseudoRating(String name) {
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    return (4.0 + (hash % 9) * 0.1).clamp(4.0, 4.8);
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
      return 'Octane • Petrol • Diesel';
    }
    return fuels.join(' • ');
  }
}

class _RealStationData {
  final double latitude;
  final double longitude;
  final String name;
  final String area;
  final String fuels;
  final double rating;
  final String image;

  const _RealStationData({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.area,
    required this.fuels,
    required this.rating,
    required this.image,
  });
}

/// Verified real geographic coordinates of major fuel stations in Bangladesh
const List<_RealStationData> _bangladeshRealStations = [
  // ── DHAKA: Mohakhali / Gulshan / Banani / Tejgaon (Dhaka 1212) ──────────
  _RealStationData(
    latitude: 23.7735,
    longitude: 90.4008,
    name: 'Royal Filling Station',
    area: '51/1 Shaheed Tajuddin Ahmed Sarani, Mohakhali',
    fuels: 'Octane • Petrol • Diesel • CNG',
    rating: 4.1,
    image: 'assets/images/station_city_express.jpg',
  ),
  _RealStationData(
    latitude: 23.7719,
    longitude: 90.4012,
    name: 'Southern Automobiles Ltd',
    area: '80 Shaheed Tajuddin Ahmed Sarani, Mohakhali',
    fuels: 'Octane • Petrol • CNG',
    rating: 4.4,
    image: 'assets/images/station_clean_fuel.jpg',
  ),
  _RealStationData(
    latitude: 23.7708,
    longitude: 90.4018,
    name: 'Clean Fuel Filling Station Ltd',
    area: 'Shaheed Tajuddin Ahmed Ave, Mohakhali',
    fuels: 'Octane • Diesel • CNG • EV Fast',
    rating: 4.9,
    image: 'assets/images/station_clean_fuel.jpg',
  ),
  _RealStationData(
    latitude: 23.7745,
    longitude: 90.4002,
    name: 'TASHOFA Filling Station',
    area: 'Mohakhali Tajuddin Ahmed Ave',
    fuels: 'Octane • Diesel • Petrol',
    rating: 4.6,
    image: 'assets/images/station_trust.jpg',
  ),
  _RealStationData(
    latitude: 23.7788,
    longitude: 90.4075,
    name: 'Meghna Petrol Pump',
    area: '96-98 Bir Uttam AK Khandakar Rd, Mohakhali',
    fuels: 'Octane • Diesel • Petrol • LPG',
    rating: 4.7,
    image: 'assets/images/station_meghna.jpg',
  ),
  _RealStationData(
    latitude: 23.7785,
    longitude: 90.4170,
    name: 'Gulshan Service Station',
    area: 'Bir Uttam AK Khandakar Rd, Gulshan-1',
    fuels: 'Octane • Petrol • Diesel',
    rating: 4.7,
    image: 'assets/images/station_navana.jpg',
  ),
  _RealStationData(
    latitude: 23.7742,
    longitude: 90.4085,
    name: 'Navana CNG & LPG Ltd',
    area: '214/D Bir Uttam Mir Shawkat Sarak, Tejgaon',
    fuels: 'CNG • LPG • Autogas',
    rating: 4.8,
    image: 'assets/images/station_navana.jpg',
  ),
  _RealStationData(
    latitude: 23.7885,
    longitude: 90.4020,
    name: 'Chairmanbari Filling Station',
    area: 'Dhaka-Mymensingh Hwy, Banani',
    fuels: 'Octane • Petrol • Diesel',
    rating: 4.3,
    image: 'assets/images/station_city_express.jpg',
  ),
  _RealStationData(
    latitude: 23.8050,
    longitude: 90.4060,
    name: 'Trust Filling Station',
    area: 'Army Golf Club, Airport Rd',
    fuels: 'Diesel • Octane • EV',
    rating: 4.6,
    image: 'assets/images/station_trust.jpg',
  ),
  _RealStationData(
    latitude: 23.7650,
    longitude: 90.4010,
    name: 'Anupom Filling Station',
    area: 'Tejgaon Industrial Area',
    fuels: 'Octane • Petrol • Diesel',
    rating: 4.5,
    image: 'assets/images/station_city_express.jpg',
  ),
  _RealStationData(
    latitude: 23.7640,
    longitude: 90.3870,
    name: 'Sonar Bangla CNG & Filling',
    area: 'Bijoy Sarani Link Rd',
    fuels: 'CNG • Octane • Petrol',
    rating: 4.6,
    image: 'assets/images/station_clean_fuel.jpg',
  ),
  _RealStationData(
    latitude: 23.8010,
    longitude: 90.4240,
    name: 'Intraco CNG & Refueling',
    area: 'Pragati Sarani, Baridhara',
    fuels: 'CNG • Octane • Diesel',
    rating: 4.5,
    image: 'assets/images/station_padma.jpg',
  ),
  _RealStationData(
    latitude: 23.8226,
    longitude: 90.3918,
    name: 'CSD Filling Station',
    area: 'Shaheed Sharani, Dhaka Cantt',
    fuels: 'Octane • Petrol • Diesel',
    rating: 4.8,
    image: 'assets/images/station_city_express.jpg',
  ),

  // ── DHAKA: Mirpur / Matikata / Mirpur 10 ─────────────────────────────────
  _RealStationData(
    latitude: 23.8004,
    longitude: 90.3558,
    name: 'SAM Associates Ltd.',
    area: 'Mirpur Rd, Mirpur',
    fuels: 'CNG • Octane • Diesel',
    rating: 4.5,
    image: 'assets/images/station_city_express.jpg',
  ),
  _RealStationData(
    latitude: 23.8004,
    longitude: 90.3566,
    name: 'Omera Gas One',
    area: 'Matikata Rd, Mirpur',
    fuels: 'CNG • LPG',
    rating: 4.4,
    image: 'assets/images/station_clean_fuel.jpg',
  ),
  _RealStationData(
    latitude: 23.8051,
    longitude: 90.3635,
    name: 'Kingshuk CNG Station',
    area: 'Mirpur Rd, Mirpur 10',
    fuels: 'CNG • Octane',
    rating: 4.5,
    image: 'assets/images/station_padma.jpg',
  ),
  _RealStationData(
    latitude: 23.8048,
    longitude: 90.3697,
    name: 'Minerva CNG Filling Station',
    area: 'Mirpur 10 Roundabout',
    fuels: 'CNG • Octane • Diesel',
    rating: 4.6,
    image: 'assets/images/station_navana.jpg',
  ),
  _RealStationData(
    latitude: 23.8037,
    longitude: 90.3700,
    name: 'Dhaka CNG Ltd.',
    area: 'Mirpur 10, Matikata',
    fuels: 'CNG',
    rating: 4.3,
    image: 'assets/images/station_padma.jpg',
  ),
  _RealStationData(
    latitude: 23.8062,
    longitude: 90.3741,
    name: 'Shatabdi CNG Filling Station',
    area: 'Mirpur 14, Senpara',
    fuels: 'CNG • Octane',
    rating: 4.5,
    image: 'assets/images/station_clean_fuel.jpg',
  ),
  _RealStationData(
    latitude: 23.8067,
    longitude: 90.3714,
    name: 'Ariya CNG Filling Station',
    area: 'Mirpur 14, Senpara',
    fuels: 'CNG • Octane',
    rating: 4.4,
    image: 'assets/images/station_city_express.jpg',
  ),
  _RealStationData(
    latitude: 23.8127,
    longitude: 90.3673,
    name: 'Skamco CNG Station',
    area: 'Begum Rokeya Sarani, Mirpur 10',
    fuels: 'CNG • Octane • Diesel',
    rating: 4.5,
    image: 'assets/images/station_trust.jpg',
  ),
  _RealStationData(
    latitude: 23.8200,
    longitude: 90.3864,
    name: 'Sumatra Filling & LPG Station',
    area: '5 Matikata Rd, Mirpur',
    fuels: 'Octane • Petrol • Diesel • CNG • LPG',
    rating: 4.6,
    image: 'assets/images/station_meghna.jpg',
  ),
  _RealStationData(
    latitude: 23.7826,
    longitude: 90.3504,
    name: 'Denso Filling Station',
    area: 'Bir Uttam A.W Chowdhury Rd, Mirpur',
    fuels: 'Octane • Diesel • CNG',
    rating: 4.4,
    image: 'assets/images/station_trust.jpg',
  ),
  _RealStationData(
    latitude: 23.7882,
    longitude: 90.3770,
    name: 'M/S Sobahan Filling Station',
    area: 'Begum Rokeya Sarani, Mirpur',
    fuels: 'Octane • Diesel • CNG',
    rating: 4.5,
    image: 'assets/images/station_city_express.jpg',
  ),

  // ── DHAKA: Dhanmondi / Asad Gate / Kalyanpur ─────────────────────────────
  _RealStationData(
    latitude: 23.7595,
    longitude: 90.3690,
    name: 'M/S Talukder Filling & Servicing Centre',
    area: 'Asad Gate Bus Stand, Mirpur Rd',
    fuels: 'Octane • Petrol • Diesel • CNG',
    rating: 3.8,
    image: 'assets/images/station_trust.jpg',
  ),
  _RealStationData(
    latitude: 23.7420,
    longitude: 90.3750,
    name: 'Dhanmondi Filling Station',
    area: 'Mirpur Rd, Dhanmondi 27',
    fuels: 'Octane • Petrol • Diesel',
    rating: 4.4,
    image: 'assets/images/station_city_express.jpg',
  ),
  _RealStationData(
    latitude: 23.7988,
    longitude: 90.3870,
    name: 'Diganta Filling Station',
    area: 'Plot-A, 4 Mirpur Rd, Mirpur',
    fuels: 'Octane • Petrol • CNG',
    rating: 4.5,
    image: 'assets/images/station_padma.jpg',
  ),
  _RealStationData(
    latitude: 23.8550,
    longitude: 90.4030,
    name: 'Padma Oil Filling Hub',
    area: 'Airport Expressway, Uttara',
    fuels: 'Super Octane • EV Fast • Diesel',
    rating: 4.9,
    image: 'assets/images/station_padma.jpg',
  ),

  // ── CHITTAGONG & SYLHET ──────────────────────────────────────────────────
  _RealStationData(
    latitude: 22.3569,
    longitude: 91.8214,
    name: 'Meghna Petroleum Ltd (GEC)',
    area: 'CDA Avenue, GEC, Chittagong',
    fuels: 'Octane • Diesel • Petrol',
    rating: 4.9,
    image: 'assets/images/station_meghna.jpg',
  ),
  _RealStationData(
    latitude: 22.3250,
    longitude: 91.8150,
    name: 'Padma Oil Agrabad',
    area: 'Agrabad Commercial Area, Chittagong',
    fuels: 'Diesel • Octane • High Octane',
    rating: 4.8,
    image: 'assets/images/station_padma.jpg',
  ),
  _RealStationData(
    latitude: 24.8949,
    longitude: 91.8687,
    name: 'Surma Petrol & CNG Hub',
    area: 'Zindabazar Road, Sylhet',
    fuels: 'Octane • Petrol • CNG',
    rating: 4.8,
    image: 'assets/images/station_padma.jpg',
  ),
];
