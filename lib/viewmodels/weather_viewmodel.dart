import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/weather_service.dart';
import '../core/utils/notification_service.dart';
import '../models/weather_models.dart';

const _prefsEnabledKey = 'weather_tips_alerts_enabled';
const _prefsLastAlertKey = 'weather_last_alert_fingerprint';
const _prefsLastAlertAtKey = 'weather_last_alert_at_ms';

/// User preference: weather tips + alerts (default on).
final weatherTipsEnabledProvider =
    StateNotifierProvider<WeatherTipsEnabledNotifier, bool>((ref) {
  return WeatherTipsEnabledNotifier();
});

class WeatherTipsEnabledNotifier extends StateNotifier<bool> {
  WeatherTipsEnabledNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefsEnabledKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabledKey, value);
    if (value) {
      await NotificationService().scheduleMorningWeatherTip(
        title: 'weatherMorningTitle'.tr(),
        body: 'weatherMorningBody'.tr(),
      );
    } else {
      await NotificationService().cancelWeatherNotifications();
    }
  }
}

/// Current drive advice from Open-Meteo (+ cache).
final weatherAdviceProvider =
    AsyncNotifierProvider<WeatherAdviceNotifier, DriveAdvice>(
  WeatherAdviceNotifier.new,
);

class WeatherAdviceNotifier extends AsyncNotifier<DriveAdvice> {
  @override
  Future<DriveAdvice> build() async {
    final snap = await WeatherService.instance.getCurrent();
    final advice = DriveAdviceEngine.fromSnapshot(snap);
    // ignore: unawaited_futures
    _afterFetch(advice);
    return advice;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final snap =
          await WeatherService.instance.getCurrent(forceRefresh: true);
      final advice = DriveAdviceEngine.fromSnapshot(snap);
      await _afterFetch(advice);
      return advice;
    });
  }

  Future<void> _afterFetch(DriveAdvice advice) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefsEnabledKey) ?? true;
    if (!enabled) return;

    await NotificationService().scheduleMorningWeatherTip(
      title: 'weatherMorningTitle'.tr(),
      body: 'weatherMorningBody'.tr(),
    );
    await _maybeAlertBadWeather(advice, prefs);
  }

  Future<void> _maybeAlertBadWeather(
    DriveAdvice advice,
    SharedPreferences prefs,
  ) async {
    if (advice.level == DriveAdviceLevel.good) return;

    final fingerprint = '${advice.level.name}_${advice.snapshot.weatherCode}';
    final lastFp = prefs.getString(_prefsLastAlertKey);
    final lastAtMs = prefs.getInt(_prefsLastAlertAtKey) ?? 0;
    final lastAt = DateTime.fromMillisecondsSinceEpoch(lastAtMs);
    final cooledDown =
        DateTime.now().difference(lastAt) > const Duration(hours: 3);

    if (lastFp == fingerprint && !cooledDown) return;

    await NotificationService().showWeatherNotification(
      id: NotificationService.weatherAlertId,
      title: advice.titleKey.tr(),
      body: advice.bodyKey.tr(),
    );

    await prefs.setString(_prefsLastAlertKey, fingerprint);
    await prefs.setInt(
      _prefsLastAlertAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
