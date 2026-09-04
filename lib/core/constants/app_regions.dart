import 'package:flutter/widgets.dart';

/// App market region — language + currency travel together.
enum AppRegion {
  bangladesh,
  india,
  unitedStates,
}

extension AppRegionX on AppRegion {
  String get id => switch (this) {
        AppRegion.bangladesh => 'bd',
        AppRegion.india => 'in',
        AppRegion.unitedStates => 'us',
      };

  /// ISO 4217 code.
  String get currencyCode => switch (this) {
        AppRegion.bangladesh => 'BDT',
        AppRegion.india => 'INR',
        AppRegion.unitedStates => 'USD',
      };

  /// Leading symbol for [AppCurrency.format] (includes trailing space).
  String get currencySymbol => switch (this) {
        AppRegion.bangladesh => '৳ ',
        AppRegion.india => '₹ ',
        AppRegion.unitedStates => '\$ ',
      };

  /// Compact symbol without padding (settings chips).
  String get currencyGlyph => switch (this) {
        AppRegion.bangladesh => '৳',
        AppRegion.india => '₹',
        AppRegion.unitedStates => '\$',
      };

  Locale get locale => switch (this) {
        AppRegion.bangladesh => const Locale('bn'),
        AppRegion.india => const Locale('hi'),
        AppRegion.unitedStates => const Locale('en'),
      };

  String get flagEmoji => switch (this) {
        AppRegion.bangladesh => '🇧🇩',
        AppRegion.india => '🇮🇳',
        AppRegion.unitedStates => '🇺🇸',
      };

  /// Translation keys for country / language labels.
  String get countryNameKey => switch (this) {
        AppRegion.bangladesh => 'regionBangladesh',
        AppRegion.india => 'regionIndia',
        AppRegion.unitedStates => 'regionUnitedStates',
      };

  String get languageNameKey => switch (this) {
        AppRegion.bangladesh => 'languageBangla',
        AppRegion.india => 'languageHindi',
        AppRegion.unitedStates => 'languageEnglish',
      };

  static AppRegion? tryParse(String? raw) {
    if (raw == null) return null;
    for (final region in AppRegion.values) {
      if (region.id == raw) return region;
    }
    return null;
  }

  /// Map device locale / country → region (first install default).
  static AppRegion detectFromDeviceLocale([Locale? device]) {
    final locale =
        device ?? WidgetsBinding.instance.platformDispatcher.locale;
    final country = (locale.countryCode ?? '').toUpperCase();
    final lang = locale.languageCode.toLowerCase();

    if (country == 'BD' || lang == 'bn') return AppRegion.bangladesh;
    if (country == 'IN' || lang == 'hi') return AppRegion.india;
    return AppRegion.unitedStates;
  }

  static AppRegion fromLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'bn':
        return AppRegion.bangladesh;
      case 'hi':
        return AppRegion.india;
      default:
        return AppRegion.unitedStates;
    }
  }
}
