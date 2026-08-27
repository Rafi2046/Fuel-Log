import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/utils/receipt_parser.dart';

void main() {
  group('ReceiptParser Tests', () {
    test('parses standard labeled gas station receipt slip', () {
      const rawText = '''
================================
      PADMA OIL COMPANY LTD.
    AIRPORT ROAD FILLING STATION
================================
DATE: 27/08/2026   TIME: 14:35
NOZZLE: 02          PRODUCT: OCTANE
RATE/L: 130.00 TK
VOLUME: 19.23 LTRS
TOTAL AMOUNT: 2500.00 TK
ODO: 45200 KM
PAYMENT: CASH
THANK YOU! DRIVE SAFELY.
================================
''';

      final receipt = ReceiptParser.parse(rawText);

      expect(receipt.hasEssentialData, isTrue);
      expect(receipt.totalCost, equals(2500.00));
      expect(receipt.amountLiters, equals(19.23));
      expect(receipt.unitPrice, equals(130.00));
      expect(receipt.odometer, equals(45200.0));
      expect(receipt.date, equals(DateTime(2026, 8, 27)));
    });

    test('parses unlabeled LCD gas pump meter output via numerical heuristics', () {
      const rawText = '''
OCTANE
2600.00
20.00
130.00
''';

      final receipt = ReceiptParser.parse(rawText);

      expect(receipt.hasEssentialData, isTrue);
      expect(receipt.totalCost, equals(2600.00));
      expect(receipt.amountLiters, equals(20.00));
      expect(receipt.unitPrice, equals(130.00));
    });

    test('auto-derives unit price when Total and Liters are present', () {
      const rawText = '''
TOTAL: 1500.00 BDT
FUEL QTY: 12.00 LTR
''';

      final receipt = ReceiptParser.parse(rawText);

      expect(receipt.totalCost, equals(1500.00));
      expect(receipt.amountLiters, equals(12.00));
      expect(receipt.unitPrice, equals(125.00)); // 1500 / 12 = 125
    });

    test('auto-derives liters when Total and Rate are present', () {
      const rawText = '''
NET PAYABLE: 1300.00
PRICE/L: 130.00
''';

      final receipt = ReceiptParser.parse(rawText);

      expect(receipt.totalCost, equals(1300.00));
      expect(receipt.unitPrice, equals(130.00));
      expect(receipt.amountLiters, equals(10.00)); // 1300 / 130 = 10
    });

    test('parses Bengali labeled receipt', () {
      const rawText = '''
পদ্মা অয়েল স্টেশন
মোট: 1800.00 টাকা
লিটার: 15.00
''';

      final receipt = ReceiptParser.parse(rawText);

      expect(receipt.totalCost, equals(1800.00));
      expect(receipt.amountLiters, equals(15.00));
      expect(receipt.unitPrice, equals(120.00));
    });

    test('handles empty or noise text gracefully', () {
      const rawText = 'Welcome to Dhaka highway. Drive safe!';

      final receipt = ReceiptParser.parse(rawText);

      expect(receipt.hasEssentialData, isFalse);
      expect(receipt.totalCost, isNull);
      expect(receipt.amountLiters, isNull);
    });
  });
}
