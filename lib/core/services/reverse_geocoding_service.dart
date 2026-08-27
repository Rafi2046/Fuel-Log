import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Resolves GPS coordinates to a short human-readable place label (OSM Nominatim).
abstract final class ReverseGeocodingService {
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
            headers: const {'User-Agent': 'FuelLogApp/1.0'},
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
}
