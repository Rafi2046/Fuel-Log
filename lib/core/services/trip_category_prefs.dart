import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Built-in trip categories plus user-defined names (on-device prefs).
abstract final class TripCategoryPrefs {
  static const builtIn = ['private', 'work', 'other'];
  static const addCustomValue = '__add_custom__';
  static const _key = 'trip_custom_categories';

  static Future<List<String>> loadCustom() async {
    final prefs = await SharedPreferences.getInstance();
    return List<String>.from(prefs.getStringList(_key) ?? const []);
  }

  static Future<List<String>> addCustom(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) return loadCustom();

    final existing = await loadCustom();
    final duplicate = existing.any((c) => c.toLowerCase() == name.toLowerCase()) ||
        builtIn.contains(name.toLowerCase());
    if (duplicate) return existing;

    final next = [...existing, name];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next);
    return next;
  }

  static String labelFor(String value) {
    switch (value) {
      case 'private':
        return 'privacyPrivate'.tr();
      case 'work':
        return 'privacyWork'.tr();
      case 'other':
        return 'privacyOther'.tr();
      default:
        return value;
    }
  }
}
