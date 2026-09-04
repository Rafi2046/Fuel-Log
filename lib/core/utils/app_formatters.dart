import 'package:intl/intl.dart';

import '../constants/app_regions.dart';

/// Region-aware money formatting — English digits, active currency symbol.
abstract final class AppCurrency {
  static AppRegion _region = AppRegion.bangladesh;
  static NumberFormat _formatter = _build(AppRegion.bangladesh);

  static AppRegion get region => _region;
  static String get code => _region.currencyCode;
  static String get symbol => _region.currencyGlyph;

  static void setRegion(AppRegion region) {
    _region = region;
    _formatter = _build(region);
  }

  static NumberFormat _build(AppRegion region) => NumberFormat.currency(
        locale: 'en',
        symbol: region.currencySymbol,
        decimalDigits: 0,
      );

  /// Back-compat alias — prefer [format].
  static NumberFormat get bdt => _formatter;

  static String format(num amount) => _formatter.format(amount);
}

/// Shared date formatting for log lists.
abstract final class AppDateFormats {
  static final DateFormat logDate = DateFormat('dd MMM yyyy');

  static String formatLogDate(DateTime date) => logDate.format(date);
}
