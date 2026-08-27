import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's last selected active vehicle across app restarts.
abstract final class ActiveVehiclePrefs {
  static const _key = 'last_active_vehicle_id';

  static Future<int?> getLastActiveVehicleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key);
  }

  static Future<void> setLastActiveVehicleId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, id);
  }

  static Future<void> clearLastActiveVehicleId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
