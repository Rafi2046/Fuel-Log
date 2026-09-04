import 'package:flutter/widgets.dart';

/// Supported display languages (independent of currency).
enum AppLanguage {
  english,
  bangla,
  hindi,
}

extension AppLanguageX on AppLanguage {
  String get id => switch (this) {
        AppLanguage.english => 'en',
        AppLanguage.bangla => 'bn',
        AppLanguage.hindi => 'hi',
      };

  Locale get locale => Locale(id);

  String get flagEmoji => switch (this) {
        AppLanguage.english => '🇺🇸',
        AppLanguage.bangla => '🇧🇩',
        AppLanguage.hindi => '🇮🇳',
      };

  String get nameKey => switch (this) {
        AppLanguage.english => 'languageEnglish',
        AppLanguage.bangla => 'languageBangla',
        AppLanguage.hindi => 'languageHindi',
      };

  static AppLanguage? tryParse(String? raw) {
    if (raw == null) return null;
    for (final lang in AppLanguage.values) {
      if (lang.id == raw) return lang;
    }
    return null;
  }

  static AppLanguage fromLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'bn':
        return AppLanguage.bangla;
      case 'hi':
        return AppLanguage.hindi;
      default:
        return AppLanguage.english;
    }
  }

  static AppLanguage detectFromDeviceLocale([Locale? device]) {
    final locale =
        device ?? WidgetsBinding.instance.platformDispatcher.locale;
    final country = (locale.countryCode ?? '').toUpperCase();
    final lang = locale.languageCode.toLowerCase();
    if (country == 'BD' || lang == 'bn') return AppLanguage.bangla;
    if (country == 'IN' || lang == 'hi') return AppLanguage.hindi;
    return AppLanguage.english;
  }
}

/// Supported currencies (independent of language).
enum AppCurrencyId {
  bdt,
  inr,
  usd,
}

extension AppCurrencyIdX on AppCurrencyId {
  String get id => switch (this) {
        AppCurrencyId.bdt => 'bdt',
        AppCurrencyId.inr => 'inr',
        AppCurrencyId.usd => 'usd',
      };

  String get code => switch (this) {
        AppCurrencyId.bdt => 'BDT',
        AppCurrencyId.inr => 'INR',
        AppCurrencyId.usd => 'USD',
      };

  String get currencySymbol => switch (this) {
        AppCurrencyId.bdt => '৳ ',
        AppCurrencyId.inr => '₹ ',
        AppCurrencyId.usd => '\$ ',
      };

  String get glyph => switch (this) {
        AppCurrencyId.bdt => '৳',
        AppCurrencyId.inr => '₹',
        AppCurrencyId.usd => '\$',
      };

  String get flagEmoji => switch (this) {
        AppCurrencyId.bdt => '🇧🇩',
        AppCurrencyId.inr => '🇮🇳',
        AppCurrencyId.usd => '🇺🇸',
      };

  String get nameKey => switch (this) {
        AppCurrencyId.bdt => 'currencyBdt',
        AppCurrencyId.inr => 'currencyInr',
        AppCurrencyId.usd => 'currencyUsd',
      };

  static AppCurrencyId? tryParse(String? raw) {
    if (raw == null) return null;
    for (final c in AppCurrencyId.values) {
      if (c.id == raw || c.code.toLowerCase() == raw.toLowerCase()) {
        return c;
      }
    }
    // Legacy region ids from older builds.
    return switch (raw) {
      'bd' => AppCurrencyId.bdt,
      'in' => AppCurrencyId.inr,
      'us' => AppCurrencyId.usd,
      _ => null,
    };
  }

  static AppCurrencyId detectFromDeviceLocale([Locale? device]) {
    final locale =
        device ?? WidgetsBinding.instance.platformDispatcher.locale;
    final country = (locale.countryCode ?? '').toUpperCase();
    final lang = locale.languageCode.toLowerCase();
    if (country == 'BD' || lang == 'bn') return AppCurrencyId.bdt;
    if (country == 'IN' || lang == 'hi') return AppCurrencyId.inr;
    return AppCurrencyId.usd;
  }
}
