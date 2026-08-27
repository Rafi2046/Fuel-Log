/// Structured representation of parsed fuel receipt / pump display data.
class ReceiptData {
  const ReceiptData({
    this.totalCost,
    this.amountLiters,
    this.unitPrice,
    this.odometer,
    this.date,
    required this.rawText,
  });

  final double? totalCost;
  final double? amountLiters;
  final double? unitPrice;
  final double? odometer;
  final DateTime? date;
  final String rawText;

  bool get hasEssentialData =>
      totalCost != null || amountLiters != null || unitPrice != null;

  ReceiptData copyWith({
    double? totalCost,
    double? amountLiters,
    double? unitPrice,
    double? odometer,
    DateTime? date,
    String? rawText,
  }) {
    return ReceiptData(
      totalCost: totalCost ?? this.totalCost,
      amountLiters: amountLiters ?? this.amountLiters,
      unitPrice: unitPrice ?? this.unitPrice,
      odometer: odometer ?? this.odometer,
      date: date ?? this.date,
      rawText: rawText ?? this.rawText,
    );
  }

  @override
  String toString() {
    return 'ReceiptData(total: $totalCost, liters: $amountLiters, rate: $unitPrice, odo: $odometer, date: $date)';
  }
}

/// Pure business logic utility for parsing OCR extracted text into structured [ReceiptData].
class ReceiptParser {
  const ReceiptParser._();

  /// Parses raw OCR text using multi-pass regex patterns and numerical heuristics.
  static ReceiptData parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return const ReceiptData(rawText: '');
    }

    final sanitized = _normalizeText(rawText);

    double? totalCost = _extractTotalCost(sanitized);
    double? amountLiters = _extractLiters(sanitized);
    double? unitPrice = _extractUnitPrice(sanitized);
    final double? odometer = _extractOdometer(sanitized);
    final DateTime? date = _extractDate(sanitized);

    // Fallback: If labeled extraction missed key values (common on pump LCD displays),
    // apply numerical heuristics and geometric cross-validation.
    if (totalCost == null || amountLiters == null || unitPrice == null) {
      final numbers = _extractAllNumbers(sanitized);
      final derived = _deriveFromNumbers(
        numbers: numbers,
        existingTotal: totalCost,
        existingLiters: amountLiters,
        existingPrice: unitPrice,
      );

      totalCost ??= derived.totalCost;
      amountLiters ??= derived.amountLiters;
      unitPrice ??= derived.unitPrice;
    }

    // Mathematical reconciliation: Total = Liters * Unit Price
    if (totalCost != null && amountLiters != null && amountLiters > 0 && unitPrice == null) {
      unitPrice = double.parse((totalCost / amountLiters).toStringAsFixed(2));
    } else if (totalCost != null && unitPrice != null && unitPrice > 0 && amountLiters == null) {
      amountLiters = double.parse((totalCost / unitPrice).toStringAsFixed(2));
    } else if (amountLiters != null && unitPrice != null && totalCost == null) {
      totalCost = double.parse((amountLiters * unitPrice).toStringAsFixed(2));
    }

    return ReceiptData(
      totalCost: totalCost,
      amountLiters: amountLiters,
      unitPrice: unitPrice,
      odometer: odometer,
      date: date,
      rawText: rawText,
    );
  }

  static String _normalizeText(String text) {
    return text
        .replaceAll('৳', ' TK ')
        .replaceAll('\$', ' USD ')
        .replaceAll('€', ' EUR ')
        .replaceAll('£', ' GBP ')
        .replaceAll(RegExp(r'[|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Extracts labeled total cost (e.g. "Total: 1500.00", "Amount: 1,500 TK", "Net Payable 2450.50").
  static double? _extractTotalCost(String text) {
    final patterns = [
      RegExp(
        r'(?:total\s*amount|total\s*payable|net\s*amount|net\s*payable|grand\s*total|total\s*cost|total\s*sale|total|amount|payable|বিল|মোট)[\s:]*(?:tk|bdt|rs|usd|\$|৳)?[\s:]*([0-9]+(?:[.,][0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'([0-9]+(?:[.,][0-9]{1,2})?)\s*(?:tk|bdt|taka|৳)\b',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final rawNum = match.group(1)?.replaceAll(',', '.');
        final val = double.tryParse(rawNum ?? '');
        if (val != null && val > 0) {
          return val;
        }
      }
    }
    return null;
  }

  /// Extracts fuel amount / liters (e.g. "Volume: 12.50 L", "Quantity 15.000 LTRS", "Liters: 10.5").
  static double? _extractLiters(String text) {
    final patterns = [
      RegExp(
        r'(?:volume|liters?|ltrs?|qty|quantity|vol|ltr|fuel\s*qty|লিটার)[\s:]*([0-9]+(?:[.,][0-9]{1,3})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'([0-9]+(?:[.,][0-9]{1,3})?)\s*(?:ltrs?|liters?|l)\b',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final rawNum = match.group(1)?.replaceAll(',', '.');
        final val = double.tryParse(rawNum ?? '');
        if (val != null && val > 0 && val < 500) {
          return val;
        }
      }
    }
    return null;
  }

  /// Extracts fuel unit price rate (e.g. "Rate: 130.00", "Price/L: 125.00", "@ 135.00").
  static double? _extractUnitPrice(String text) {
    final patterns = [
      RegExp(
        r'(?:price\/l(?:tr)?|unit\s*price|rate\/l(?:tr)?|rate|@|দর)[\s:]*(?:tk|bdt|rs|\$)?[\s:]*([0-9]+(?:[.,][0-9]{1,2})?)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final rawNum = match.group(1)?.replaceAll(',', '.');
        final val = double.tryParse(rawNum ?? '');
        if (val != null && val > 0 && val < 1000) {
          return val;
        }
      }
    }
    return null;
  }

  /// Extracts odometer reading if present on receipt (e.g. "Odo: 12450", "Km: 15400").
  static double? _extractOdometer(String text) {
    final pattern = RegExp(
      r'(?:odometer|odo|km\s*reading)[\s:]*([0-9]{3,7}(?:[.,][0-9]{1,2})?)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    if (match != null) {
      final rawNum = match.group(1)?.replaceAll(',', '.');
      return double.tryParse(rawNum ?? '');
    }
    return null;
  }

  /// Extracts date from receipt text (e.g. "27/08/2026", "2026-08-27", "27-Aug-2026").
  static DateTime? _extractDate(String text) {
    // 1. dd/mm/yyyy or dd-mm-yyyy
    final dmyPattern = RegExp(r'\b([0-3]?[0-9])[/\-.]([0-1]?[0-9])[/\-.](20\d{2})\b');
    final matchDmy = dmyPattern.firstMatch(text);
    if (matchDmy != null) {
      final day = int.tryParse(matchDmy.group(1) ?? '');
      final month = int.tryParse(matchDmy.group(2) ?? '');
      final year = int.tryParse(matchDmy.group(3) ?? '');
      if (day != null && month != null && year != null && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day);
      }
    }

    // 2. yyyy-mm-dd
    final ymdPattern = RegExp(r'\b(20\d{2})[/\-.]([0-1]?[0-9])[/\-.]([0-3]?[0-9])\b');
    final matchYmd = ymdPattern.firstMatch(text);
    if (matchYmd != null) {
      final year = int.tryParse(matchYmd.group(1) ?? '');
      final month = int.tryParse(matchYmd.group(2) ?? '');
      final day = int.tryParse(matchYmd.group(3) ?? '');
      if (year != null && month != null && day != null && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  /// Extracts all positive float/decimal numbers from text in appearance order.
  static List<double> _extractAllNumbers(String text) {
    final matches = RegExp(r'\b([0-9]+(?:[\.,][0-9]{1,3})?)\b').allMatches(text);
    final list = <double>[];
    for (final m in matches) {
      final str = m.group(1)?.replaceAll(',', '.');
      final val = double.tryParse(str ?? '');
      if (val != null && val > 0) {
        list.add(val);
      }
    }
    return list;
  }

  /// Heuristic derivation for pump LCD screens without labels.
  static ({double? totalCost, double? amountLiters, double? unitPrice}) _deriveFromNumbers({
    required List<double> numbers,
    double? existingTotal,
    double? existingLiters,
    double? existingPrice,
  }) {
    double? total = existingTotal;
    double? liters = existingLiters;
    double? price = existingPrice;

    if (numbers.length >= 2) {
      // Find candidate pairs where a * b ≈ c
      for (int i = 0; i < numbers.length; i++) {
        for (int j = 0; j < numbers.length; j++) {
          if (i == j) continue;
          final prod = numbers[i] * numbers[j];
          for (int k = 0; k < numbers.length; k++) {
            if (k == i || k == j) continue;
            final target = numbers[k];
            // Check if within 2% margin
            if (target > 0 && (prod - target).abs() / target < 0.03) {
              final valA = numbers[i];
              final valB = numbers[j];

              // Higher is usually price (e.g. 130), lower is liters (e.g. 15.5)
              final candPrice = valA > valB ? valA : valB;
              final candLiters = valA < valB ? valA : valB;

              total ??= target;
              liters ??= candLiters;
              price ??= candPrice;
              return (totalCost: total, amountLiters: liters, unitPrice: price);
            }
          }
        }
      }

      // If no 3-way product matched, sort numbers
      final sorted = List<double>.from(numbers)..sort();
      final largest = sorted.last;

      if (total == null && largest >= 200) {
        total = largest;
      }

      // Find smaller decimal for liters
      if (liters == null) {
        final smallDecimals = sorted.where((n) => n > 1.0 && n < 100.0 && n != total).toList();
        if (smallDecimals.isNotEmpty) {
          liters = smallDecimals.first;
        }
      }
    }

    return (totalCost: total, amountLiters: liters, unitPrice: price);
  }
}
