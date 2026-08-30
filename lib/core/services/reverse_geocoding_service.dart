import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Resolves GPS coordinates to a short human-readable place label (OSM Nominatim).
abstract final class ReverseGeocodingService {
  static const _userAgent = 'FuelLogApp/1.0';

  static Future<String?> resolveLabel(LatLng point) async {
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'lat': point.latitude.toString(),
          'lon': point.longitude.toString(),
          'format': 'json',
          'zoom': '16',
          'addressdetails': '1',
        },
      );

      final response = await http
          .get(
            uri,
            headers: const {'User-Agent': _userAgent},
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      if (address != null) {
        final short = _shortAddress(address);
        if (short != null && short.isNotEmpty) return short;
      }

      final display = data['display_name'] as String?;
      if (display == null || display.isEmpty) return null;
      return _truncateDisplayName(display);
    } catch (_) {
      return null;
    }
  }

  static String? _shortAddress(Map<String, dynamic> address) {
    final parts = <String>[
      if (address['road'] != null) address['road'] as String,
      if (address['suburb'] != null) address['suburb'] as String,
      if (address['neighbourhood'] != null) address['neighbourhood'] as String,
      if (address['city'] != null) address['city'] as String,
      if (address['town'] != null) address['town'] as String,
      if (address['village'] != null) address['village'] as String,
      if (address['county'] != null) address['county'] as String,
    ];
    if (parts.isEmpty) return null;
    return parts.take(3).join(', ');
  }

  static String _truncateDisplayName(String display) {
    final parts = display.split(', ').where((p) => p.trim().isNotEmpty).toList();
    if (parts.length <= 3) return display;
    return parts.take(3).join(', ');
  }

  static Future<List<GeocodedPlace>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final lower = q.toLowerCase();
    final searchQ = (lower.contains('dhaka') ||
            lower.contains('bangladesh') ||
            q.contains('ঢাকা'))
        ? q
        : '$q, Dhaka, Bangladesh';
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': searchQ,
          'format': 'json',
          'addressdetails': '1',
          'limit': '8',
          'countrycodes': 'bd',
        },
      );
      final response = await http
          .get(uri, headers: const {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return const [];
      final list = jsonDecode(response.body) as List<dynamic>;
      final places = list.map((raw) {
        final map = raw as Map<String, dynamic>;
        final lat = double.tryParse('${map['lat']}') ?? 0;
        final lon = double.tryParse('${map['lon']}') ?? 0;
        final osmClass = map['class'] as String?;
        final osmType = map['type'] as String?;
        final importance = (map['importance'] as num?)?.toDouble() ?? 0;
        final display = map['display_name'] as String? ?? q;
        final address = map['address'] as Map<String, dynamic>?;
        final label = address != null
            ? (_shortAddress(address) ?? display)
            : display;
        return GeocodedPlace(
          point: LatLng(lat, lon),
          label: label,
          osmClass: osmClass,
          osmType: osmType,
          importance: importance,
        );
      }).toList();

      places.sort((a, b) => _searchScore(b, q).compareTo(_searchScore(a, q)));
      return places;
    } catch (_) {
      return const [];
    }
  }

  static double _searchScore(GeocodedPlace place, String query) {
    final q = query.toLowerCase();
    final label = place.label.toLowerCase();
    var score = place.importance * 40;
    if (place.osmClass == 'place') score += 80;
    if (place.osmClass == 'boundary') score += 50;
    const areaTypes = {
      'suburb',
      'neighbourhood',
      'quarter',
      'city_district',
      'town',
      'city',
      'village',
    };
    if (areaTypes.contains(place.osmType)) score += 70;
    if (place.osmClass == 'highway' || place.osmClass == 'building') {
      score -= 40;
    }
    if (label.contains(q)) score += 30;
    if (label.startsWith(q)) score += 25;
    return score;
  }
}

class GeocodedPlace {
  const GeocodedPlace({
    required this.point,
    required this.label,
    this.osmClass,
    this.osmType,
    this.importance = 0,
  });

  final LatLng point;
  final String label;
  final String? osmClass;
  final String? osmType;
  final double importance;
}

