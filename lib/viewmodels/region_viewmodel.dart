import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_regions.dart';
import '../core/utils/app_formatters.dart';

const _prefsLanguageKey = 'app_language_id';
const _prefsCurrencyKey = 'app_currency_id';
const _prefsLegacyRegionKey = 'app_region_id';

/// Persisted app language (en / bn / hi) — independent of currency.
final appLanguageProvider =
    StateNotifierProvider<AppLanguageNotifier, AppLanguage>((ref) {
  return AppLanguageNotifier();
});

/// Persisted currency (BDT / INR / USD) — independent of language.
final appCurrencyProvider =
    StateNotifierProvider<AppCurrencyNotifier, AppCurrencyId>((ref) {
  return AppCurrencyNotifier();
});

class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  AppLanguageNotifier() : super(AppLanguage.bangla) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = AppLanguageX.tryParse(prefs.getString(_prefsLanguageKey));
    if (saved != null) {
      state = saved;
      return;
    }

    // Migrate legacy combined region → language once.
    final legacy = prefs.getString(_prefsLegacyRegionKey);
    final fromLegacy = switch (legacy) {
      'bd' => AppLanguage.bangla,
      'in' => AppLanguage.hindi,
      'us' => AppLanguage.english,
      _ => null,
    };
    if (fromLegacy != null) {
      await setLanguage(fromLegacy);
      return;
    }

    await setLanguage(AppLanguageX.detectFromDeviceLocale());
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsLanguageKey, language.id);
  }
}

class AppCurrencyNotifier extends StateNotifier<AppCurrencyId> {
  AppCurrencyNotifier() : super(AppCurrencyId.bdt) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = AppCurrencyIdX.tryParse(prefs.getString(_prefsCurrencyKey));
    if (saved != null) {
      state = saved;
      AppCurrency.setCurrency(saved);
      return;
    }

    final legacy = AppCurrencyIdX.tryParse(prefs.getString(_prefsLegacyRegionKey));
    if (legacy != null) {
      await setCurrency(legacy);
      return;
    }

    await setCurrency(AppCurrencyIdX.detectFromDeviceLocale());
  }

  Future<void> setCurrency(AppCurrencyId currency) async {
    state = currency;
    AppCurrency.setCurrency(currency);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsCurrencyKey, currency.id);
  }
}
