import 'package:flutter/material.dart';

enum PeriodFilter {
  allTime,
  thisYear,
  last6Months,
  last12Months,
  custom,
}

extension PeriodFilterExtension on PeriodFilter {
  String get label {
    switch (this) {
      case PeriodFilter.allTime:
        return 'All Time';
      case PeriodFilter.thisYear:
        return 'This Year';
      case PeriodFilter.last6Months:
        return 'Last 6 Months';
      case PeriodFilter.last12Months:
        return 'Last 12 Months';
      case PeriodFilter.custom:
        return 'Custom 📅';
    }
  }
}

/// Utility for filtering logs by selected time period
class AnalyticsPeriod {
  static List<T> filterItems<T>({
    required List<T> items,
    required DateTime Function(T) getDate,
    required PeriodFilter filter,
    DateTimeRange? customRange,
  }) {
    final now = DateTime.now();

    switch (filter) {
      case PeriodFilter.allTime:
        return items;

      case PeriodFilter.thisYear:
        final startOfYear = DateTime(now.year, 1, 1);
        return items.where((item) {
          final date = getDate(item);
          return date.isAfter(startOfYear) || date.isAtSameMomentAs(startOfYear);
        }).toList();

      case PeriodFilter.last6Months:
        final start = now.subtract(const Duration(days: 180));
        return items.where((item) => getDate(item).isAfter(start)).toList();

      case PeriodFilter.last12Months:
        final start = now.subtract(const Duration(days: 365));
        return items.where((item) => getDate(item).isAfter(start)).toList();

      case PeriodFilter.custom:
        if (customRange == null) return items;
        final start = customRange.start;
        final end = customRange.end.add(const Duration(days: 1));
        return items.where((item) {
          final date = getDate(item);
          return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
              date.isBefore(end);
        }).toList();
    }
  }
}
