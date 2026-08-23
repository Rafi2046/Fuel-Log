import 'package:intl/intl.dart';

/// Bangladesh Taka formatting — English digits, BDT symbol.
abstract final class AppCurrency {
  static final NumberFormat bdt = NumberFormat.currency(
    locale: 'en',
    symbol: '৳ ',
    decimalDigits: 0,
  );

  static String format(num amount) => bdt.format(amount);
}

/// Shared date formatting for log lists.
abstract final class AppDateFormats {
  static final DateFormat logDate = DateFormat('dd MMM yyyy');

  static String formatLogDate(DateTime date) => logDate.format(date);
}
