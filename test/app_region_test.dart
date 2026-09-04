import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/constants/app_regions.dart';
import 'package:fuel_log/core/utils/app_formatters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLanguage detection', () {
    test('BD / bn → Bangla', () {
      expect(
        AppLanguageX.detectFromDeviceLocale(const Locale('bn', 'BD')),
        AppLanguage.bangla,
      );
    });

    test('IN / hi → Hindi', () {
      expect(
        AppLanguageX.detectFromDeviceLocale(const Locale('hi', 'IN')),
        AppLanguage.hindi,
      );
    });

    test('other → English', () {
      expect(
        AppLanguageX.detectFromDeviceLocale(const Locale('en', 'US')),
        AppLanguage.english,
      );
    });
  });

  group('AppCurrencyId detection', () {
    test('BD → BDT', () {
      expect(
        AppCurrencyIdX.detectFromDeviceLocale(const Locale('en', 'BD')),
        AppCurrencyId.bdt,
      );
    });

    test('IN → INR', () {
      expect(
        AppCurrencyIdX.detectFromDeviceLocale(const Locale('en', 'IN')),
        AppCurrencyId.inr,
      );
    });

    test('other → USD', () {
      expect(
        AppCurrencyIdX.detectFromDeviceLocale(const Locale('en', 'US')),
        AppCurrencyId.usd,
      );
    });
  });

  group('AppCurrency independent of language', () {
    test('can mix Bangla language with USD currency', () {
      AppCurrency.setCurrency(AppCurrencyId.usd);
      expect(AppCurrency.format(1500), contains(r'$'));
      AppCurrency.setCurrency(AppCurrencyId.bdt);
      expect(AppCurrency.format(1500), contains('৳'));
      AppCurrency.setCurrency(AppCurrencyId.inr);
      expect(AppCurrency.format(1500), contains('₹'));
    });
  });
}
