import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_colors.dart';

const _prefsThemeModeKey = 'app_theme_mode';

/// Persisted appearance: system / light / dark.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Platform brightness — updates when the OS theme flips (for ThemeMode.system).
final platformBrightnessProvider =
    StateNotifierProvider<PlatformBrightnessNotifier, Brightness>((ref) {
  return PlatformBrightnessNotifier();
});

class PlatformBrightnessNotifier extends StateNotifier<Brightness>
    with WidgetsBindingObserver {
  PlatformBrightnessNotifier()
      : super(WidgetsBinding.instance.platformDispatcher.platformBrightness) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    state = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsThemeModeKey);
    state = _decode(raw) ?? ThemeMode.dark;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsThemeModeKey, _encode(mode));
  }

  static String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  static ThemeMode? _decode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => null,
      };
}

Brightness resolveAppBrightness(ThemeMode mode, Brightness platform) {
  return switch (mode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system => platform,
  };
}

/// Keep [AppColors] in sync with the resolved theme for non-Theme widgets.
void syncAppColorsPalette(ThemeMode mode, Brightness platform) {
  AppColors.setBrightness(resolveAppBrightness(mode, platform));
}
