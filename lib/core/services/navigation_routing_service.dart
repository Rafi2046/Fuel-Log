import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationRouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final int durationSeconds;
  final String nextInstruction;

  const NavigationRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.nextInstruction,
  });

  String get formattedDuration {
    final mins = (durationSeconds / 60).round();
    if (mins < 1) return '1 min';
    if (mins >= 60) {
      final hours = mins ~/ 60;
      final remMins = mins % 60;
      return '${hours}h ${remMins}m';
    }
    return '$mins min';
  }

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get formattedEta {
    final arrival = DateTime.now().add(Duration(seconds: durationSeconds));
    final hour = arrival.hour == 0
        ? 12
        : (arrival.hour > 12 ? arrival.hour - 12 : arrival.hour);
    final minute = arrival.minute.toString().padLeft(2, '0');
    final period = arrival.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class NavigationRoutingService {
  NavigationRoutingService._();
  static final NavigationRoutingService instance = NavigationRoutingService._();

  static const _distanceCalc = Distance();

  /// Fetches real turn-by-turn driving route geometry from OSRM
  Future<NavigationRouteResult> getDrivingRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&steps=true',
      );

      final response = await http.get(url).timeout(
        const Duration(milliseconds: 3200),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = (data['routes'] as List<dynamic>?) ?? [];
        if (routes.isNotEmpty) {
          final firstRoute = routes.first as Map<String, dynamic>;
          final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
          final coords = (geometry?['coordinates'] as List<dynamic>?) ?? [];

          final points = coords.map((c) {
            final pair = c as List<dynamic>;
            return LatLng(
              (pair[1] as num).toDouble(),
              (pair[0] as num).toDouble(),
            );
          }).toList();

          final distance =
              (firstRoute['distance'] as num?)?.toDouble() ?? 500.0;
          final duration = (firstRoute['duration'] as num?)?.toInt() ?? 180;

          // Extract first maneuver instruction
          var instruction = 'Continue on main road';
          try {
            final legs = firstRoute['legs'] as List<dynamic>?;
            if (legs != null && legs.isNotEmpty) {
              final steps = legs.first['steps'] as List<dynamic>?;
              if (steps != null && steps.length > 1) {
                final stepName = steps[1]['name']?.toString();
                final maneuver = steps[1]['maneuver']?['type']?.toString();
                if (stepName != null && stepName.isNotEmpty) {
                  instruction = maneuver != null
                      ? '$maneuver onto $stepName'
                      : 'Head towards $stepName';
                }
              }
            }
          } catch (_) {}

          if (points.isNotEmpty) {
            return NavigationRouteResult(
              points: points,
              distanceMeters: distance,
              durationSeconds: duration,
              nextInstruction: instruction,
            );
          }
        }
      }
    } catch (_) {
      // Fallback gracefully on network error or timeout
    }

    // Fallback interpolated street route
    return _generateFallbackRoute(start, destination);
  }

  /// Generates a realistic curved road trajectory between start & destination
  NavigationRouteResult _generateFallbackRoute(
    LatLng start,
    LatLng destination,
  ) {
    final distMeters =
        _distanceCalc.as(LengthUnit.Meter, start, destination);

    final midLat = (start.latitude + destination.latitude) / 2;
    final midLng = (start.longitude + destination.longitude) / 2;

    // Slight perpendicular offset to simulate realistic road turns
    final dLat = destination.latitude - start.latitude;
    final dLng = destination.longitude - start.longitude;
    final way1 = LatLng(
      start.latitude + dLat * 0.35 + dLng * 0.15,
      start.longitude + dLng * 0.35 - dLat * 0.15,
    );
    final way2 = LatLng(
      midLat - dLng * 0.08,
      midLng + dLat * 0.08,
    );
    final way3 = LatLng(
      start.latitude + dLat * 0.75 + dLng * 0.1,
      start.longitude + dLng * 0.75 - dLat * 0.1,
    );

    final points = [start, way1, way2, way3, destination];
    // City average driving speed ~ 25 km/h -> ~ 7 m/s
    final durationSeconds = (distMeters / 6.9).round().clamp(60, 3600);

    return NavigationRouteResult(
      points: points,
      distanceMeters: distMeters * 1.25, // accounting for city turns
      durationSeconds: durationSeconds,
      nextInstruction: 'Follow route towards station',
    );
  }

  /// Batch road distances from [origin] to each destination via OSRM table API.
  Future<List<DrivingDistanceResult?>> getDrivingDistancesTable({
    required LatLng origin,
    required List<LatLng> destinations,
  }) async {
    if (destinations.isEmpty) return const [];

    final allPoints = [origin, ...destinations];
    final coordPath = allPoints
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/table/v1/driving/'
        '$coordPath?sources=0&annotations=distance,duration',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final distances =
            (data['distances'] as List<dynamic>?)?.cast<List<dynamic>>();
        final durations =
            (data['durations'] as List<dynamic>?)?.cast<List<dynamic>>();

        if (distances != null &&
            durations != null &&
            distances.isNotEmpty &&
            distances.first.length >= destinations.length + 1) {
          final row = distances.first;
          final durRow = durations.first;
          final results = <DrivingDistanceResult?>[];

          for (var i = 0; i < destinations.length; i++) {
            final dist = (row[i + 1] as num?)?.toDouble();
            final dur = (durRow[i + 1] as num?)?.toDouble();
            if (dist != null && dist > 0 && dur != null && dur > 0) {
              results.add(
                DrivingDistanceResult(
                  distanceMeters: dist,
                  durationSeconds: dur.round(),
                ),
              );
            } else {
              results.add(null);
            }
          }
          return results;
        }
      }
    } catch (_) {}

    return List<DrivingDistanceResult?>.filled(destinations.length, null);
  }

  /// Launches Google Maps / Apple Maps / Native GPS app for turn-by-turn voice directions
  Future<bool> launchExternalMaps({
    required LatLng destination,
    required String stationName,
  }) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        return await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {}

    final geoUri = Uri.parse(
      'geo:${destination.latitude},${destination.longitude}?q=${destination.latitude},${destination.longitude}(${Uri.encodeComponent(stationName)})',
    );

    try {
      if (await canLaunchUrl(geoUri)) {
        return await launchUrl(
          geoUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {}

    return false;
  }
}

/// Road distance + duration for one destination from a routing table lookup.
class DrivingDistanceResult {
  const DrivingDistanceResult({
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final double distanceMeters;
  final int durationSeconds;
}
