import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_regions.dart';
import '../core/utils/app_formatters.dart';

const _prefsRegionKey = 'app_region_id';

/// Persisted language+currency region (BD / IN / US).
final appRegionProvider =
    StateNotifierProvider<AppRegionNotifier, AppRegion>((ref) {
  return AppRegionNotifier();
});

class AppRegionNotifier extends StateNotifier<AppRegion> {
  AppRegionNotifier() : super(AppRegion.bangladesh) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = AppRegionX.tryParse(prefs.getString(_prefsRegionKey));
    if (saved != null) {
      state = saved;
      AppCurrency.setRegion(saved);
      return;
    }

    // First launch — detect from phone locale / country.
    final detected = AppRegionX.detectFromDeviceLocale();
    await setRegion(detected);
  }

  Future<void> setRegion(AppRegion region) async {
    state = region;
    AppCurrency.setRegion(region);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsRegionKey, region.id);
  }

  /// Apply region without rewriting prefs (e.g. sync after locale restore).
  void applyLocal(AppRegion region) {
    state = region;
    AppCurrency.setRegion(region);
  }
}
