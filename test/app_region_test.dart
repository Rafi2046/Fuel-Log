import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/constants/app_regions.dart';
import 'package:fuel_log/core/utils/app_formatters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppRegion detection', () {
    test('BD / bn → Bangladesh + BDT', () {
      expect(
        AppRegionX.detectFromDeviceLocale(const Locale('bn', 'BD')),
        AppRegion.bangladesh,
      );
      expect(
        AppRegionX.detectFromDeviceLocale(const Locale('en', 'BD')),
        AppRegion.bangladesh,
      );
    });

    test('IN / hi → India + INR', () {
      expect(
        AppRegionX.detectFromDeviceLocale(const Locale('hi', 'IN')),
        AppRegion.india,
      );
      expect(
        AppRegionX.detectFromDeviceLocale(const Locale('en', 'IN')),
        AppRegion.india,
      );
    });

    test('other → United States + USD', () {
      expect(
        AppRegionX.detectFromDeviceLocale(const Locale('en', 'US')),
        AppRegion.unitedStates,
      );
      expect(
        AppRegionX.detectFromDeviceLocale(const Locale('en', 'GB')),
        AppRegion.unitedStates,
      );
    });
  });

  group('AppCurrency region symbols', () {
    test('formats with region glyph', () {
      AppCurrency.setRegion(AppRegion.bangladesh);
      expect(AppCurrency.format(1500), contains('৳'));

      AppCurrency.setRegion(AppRegion.india);
      expect(AppCurrency.format(1500), contains('₹'));

      AppCurrency.setRegion(AppRegion.unitedStates);
      expect(AppCurrency.format(1500), contains(r'$'));
    });
  });
}
