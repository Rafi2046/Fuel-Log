import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has seen the onboarding splash.
/// Onboarding is shown exactly ONCE per install, never again.
abstract final class OnboardingPrefs {
  static const _key = 'onboarding_completed';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
