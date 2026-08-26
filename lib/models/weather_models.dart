import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// WMO weather interpretation + drive advice for local weather tips.
enum DriveAdviceLevel { good, caution, avoid }

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.temperatureC,
    required this.weatherCode,
    required this.precipitationMm,
    required this.windSpeedKmh,
    required this.visibilityM,
    required this.fetchedAt,
    required this.latitude,
    required this.longitude,
  });

  final double temperatureC;
  final int weatherCode;
  final double precipitationMm;
  final double windSpeedKmh;
  final double? visibilityM;
  final DateTime fetchedAt;
  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() => {
        'temperatureC': temperatureC,
        'weatherCode': weatherCode,
        'precipitationMm': precipitationMm,
        'windSpeedKmh': windSpeedKmh,
        'visibilityM': visibilityM,
        'fetchedAt': fetchedAt.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
      };

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) {
    return WeatherSnapshot(
      temperatureC: (json['temperatureC'] as num).toDouble(),
      weatherCode: json['weatherCode'] as int,
      precipitationMm: (json['precipitationMm'] as num?)?.toDouble() ?? 0,
      windSpeedKmh: (json['windSpeedKmh'] as num?)?.toDouble() ?? 0,
      visibilityM: (json['visibilityM'] as num?)?.toDouble(),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class DriveAdvice {
  const DriveAdvice({
    required this.level,
    required this.titleKey,
    required this.bodyKey,
    required this.snapshot,
  });

  final DriveAdviceLevel level;
  final String titleKey;
  final String bodyKey;
  final WeatherSnapshot snapshot;

  IconData get lucideIcon {
    switch (level) {
      case DriveAdviceLevel.good:
        return LucideIcons.sun;
      case DriveAdviceLevel.caution:
        return LucideIcons.cloudRain;
      case DriveAdviceLevel.avoid:
        return LucideIcons.cloudLightning;
    }
  }

  Color accentColor(Color primary) {
    switch (level) {
      case DriveAdviceLevel.good:
        return const Color(0xFF2ECC71);
      case DriveAdviceLevel.caution:
        return const Color(0xFFF5A623);
      case DriveAdviceLevel.avoid:
        return const Color(0xFFE74C3C);
    }
  }
}

/// Maps Open-Meteo WMO codes + wind/vis to a soft drive recommendation.
class DriveAdviceEngine {
  const DriveAdviceEngine._();

  static DriveAdvice fromSnapshot(WeatherSnapshot snap) {
    final code = snap.weatherCode;
    final wind = snap.windSpeedKmh;
    final precip = snap.precipitationMm;
    final vis = snap.visibilityM;

    final isThunder = code >= 95 && code <= 99;
    final isHeavyRain = code == 65 ||
        code == 67 ||
        code == 82 ||
        code == 86 ||
        precip >= 4.0;
    final isFog = code == 45 || code == 48;
    final isLowVis = vis != null && vis < 1000;
    final isSnowHeavy = code == 75 || code == 77;

    if (isThunder || isHeavyRain || isFog || isLowVis || isSnowHeavy) {
      return DriveAdvice(
        level: DriveAdviceLevel.avoid,
        titleKey: 'weatherAdviceAvoidTitle',
        bodyKey: 'weatherAdviceAvoidBody',
        snapshot: snap,
      );
    }

    final isLightRain = (code >= 51 && code <= 67) ||
        (code >= 80 && code <= 82) ||
        precip >= 0.2;
    final isStrongWind = wind >= 40;
    final isLightSnow = code >= 71 && code <= 77;

    if (isLightRain || isStrongWind || isLightSnow) {
      return DriveAdvice(
        level: DriveAdviceLevel.caution,
        titleKey: 'weatherAdviceCautionTitle',
        bodyKey: 'weatherAdviceCautionBody',
        snapshot: snap,
      );
    }

    return DriveAdvice(
      level: DriveAdviceLevel.good,
      titleKey: 'weatherAdviceGoodTitle',
      bodyKey: 'weatherAdviceGoodBody',
      snapshot: snap,
    );
  }

  static IconData weatherIconForCode(int code) {
    if (code == 0) return LucideIcons.sun;
    if (code <= 3) return LucideIcons.cloudSun;
    if (code == 45 || code == 48) return LucideIcons.cloudFog;
    if (code >= 51 && code <= 67) return LucideIcons.cloudDrizzle;
    if (code >= 71 && code <= 77) return LucideIcons.snowflake;
    if (code >= 80 && code <= 82) return LucideIcons.cloudRain;
    if (code >= 95) return LucideIcons.cloudLightning;
    return LucideIcons.cloud;
  }
}
