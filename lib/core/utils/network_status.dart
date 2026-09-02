import 'package:http/http.dart' as http;

/// Reachability checks used by the trip map.
///
/// Prefer real HTTP probes over [InternetAddress.lookup] — on some Android
/// phones (Private DNS / carrier DNS) lookup fails even when HTTP works, and
/// Chrome may still load sites via DNS-over-HTTPS.
abstract final class NetworkStatus {
  static Future<bool> canReachUrl(
    String url, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: const {
            'User-Agent': 'FuelLog/1.0 (com.example.fuel_log)',
          })
          .timeout(timeout);
      // Any HTTP response means DNS + TCP worked (even 403/404).
      return response.statusCode > 0;
    } catch (_) {
      return false;
    }
  }

  /// True if any map-related endpoint answers over HTTP.
  static Future<bool> canReachMapTiles({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    const urls = <String>[
      'https://tile.openstreetmap.org/',
      'https://api.open-meteo.com/',
    ];
    for (final url in urls) {
      if (await canReachUrl(url, timeout: timeout)) return true;
    }
    return false;
  }

  static Future<bool> hasInternet({
    Duration timeout = const Duration(seconds: 5),
  }) =>
      canReachMapTiles(timeout: timeout);

  /// Kept for callers that still pass hostnames.
  static Future<bool> canReachAnyHost(
    Iterable<String> hosts, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    return canReachMapTiles(timeout: timeout);
  }
}
