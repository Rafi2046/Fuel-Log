import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/weather_models.dart';

/// Fetches current weather from Open-Meteo (no API key) with short cache.
class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  static const _cacheKey = 'weather_snapshot_cache_v1';
  static const _cacheTtl = Duration(minutes: 25);
  static const _defaultLat = 23.7925;
  static const _defaultLon = 90.4078;

  WeatherSnapshot? _memoryCache;

  Future<WeatherSnapshot> getCurrent({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _readCache();
      if (cached != null &&
          DateTime.now().difference(cached.fetchedAt) < _cacheTtl) {
        return cached;
      }
    }

    final coords = await _resolveLocation();
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': coords.$1.toStringAsFixed(4),
      'longitude': coords.$2.toStringAsFixed(4),
      'current':
          'temperature_2m,weather_code,precipitation,wind_speed_10m',
      'wind_speed_unit': 'kmh',
      'timezone': 'auto',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Weather request failed (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>?;
    if (current == null) {
      throw Exception('Weather response missing current data');
    }

    final snapshot = WeatherSnapshot(
      temperatureC: (current['temperature_2m'] as num?)?.toDouble() ?? 0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      precipitationMm: (current['precipitation'] as num?)?.toDouble() ?? 0,
      windSpeedKmh: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      visibilityM: null,
      fetchedAt: DateTime.now(),
      latitude: coords.$1,
      longitude: coords.$2,
    );

    await _writeCache(snapshot);
    return snapshot;
  }

  Future<(double, double)> _resolveLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (_defaultLat, _defaultLon);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (_defaultLat, _defaultLon);
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return (pos.latitude, pos.longitude);
    } catch (_) {
      return (_defaultLat, _defaultLon);
    }
  }

  Future<WeatherSnapshot?> _readCache() async {
    if (_memoryCache != null) return _memoryCache;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final snap =
          WeatherSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      _memoryCache = snap;
      return snap;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(WeatherSnapshot snap) async {
    _memoryCache = snap;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(snap.toJson()));
    } catch (_) {}
  }
}
