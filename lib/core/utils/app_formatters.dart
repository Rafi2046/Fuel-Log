import 'package:intl/intl.dart';

import '../constants/app_regions.dart';

/// Currency formatting — English digits, active currency symbol.
abstract final class AppCurrency {
  static AppCurrencyId _currency = AppCurrencyId.bdt;
  static NumberFormat _formatter = _build(AppCurrencyId.bdt);

  static AppCurrencyId get currency => _currency;
  static String get code => _currency.code;
  static String get symbol => _currency.glyph;

  static void setCurrency(AppCurrencyId currency) {
    _currency = currency;
    _formatter = _build(currency);
  }

  static NumberFormat _build(AppCurrencyId currency) => NumberFormat.currency(
        locale: 'en',
        symbol: currency.currencySymbol,
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
