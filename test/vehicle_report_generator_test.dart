import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/database/app_database.dart';
import 'package:fuel_log/core/services/report_generator_service.dart';
import 'package:fuel_log/models/vehicle_report_model.dart';

void main() {
  final testVehicle = Vehicle(
    id: 1,
    type: 'Car',
    name: 'Test Car',
    model: 'Corolla',
    brand: 'Toyota',
    startOdo: 10000.0,
    capacity: 50.0,
    fuelType: 'Octane',
    isElectric: false,
    createdAt: DateTime(2025, 1, 1),
  );

  final testEv = Vehicle(
    id: 2,
    type: 'EV',
    name: 'Test EV',
    model: 'Model 3',
    brand: 'Tesla',
    startOdo: 0.0,
    capacity: 75.0,
    fuelType: 'Electric (EV)',
    isElectric: true,
    createdAt: DateTime(2025, 1, 1),
  );

  final sampleFuelLogs = [
    FuelLog(
      id: 1,
      vehicleId: 1,
      date: DateTime(2026, 1, 1),
      odometer: 10000.0,
      amount: 40.0,
      cost: 4000.0,
      isFullTank: true,
    ),
    FuelLog(
      id: 2,
      vehicleId: 1,
      date: DateTime(2026, 2, 1),
      odometer: 10500.0,
      amount: 45.0,
      cost: 4500.0,
      isFullTank: true,
    ),
    FuelLog(
      id: 3,
      vehicleId: 1,
      date: DateTime(2026, 3, 1),
      odometer: 11000.0,
      amount: 40.0,
      cost: 4200.0,
      isFullTank: true,
    ),
  ];

  final sampleServiceLogs = [
    ServiceLog(
      id: 1,
      vehicleId: 1,
      date: DateTime(2026, 1, 15),
      category: 'Oil Change',
      title: 'Mobil 1 5W-30',
      cost: 3500.0,
      odometer: 10200.0,
    ),
    ServiceLog(
      id: 2,
      vehicleId: 1,
      date: DateTime(2026, 2, 20),
      category: 'Brakes',
      title: 'Brake Pads Replacement',
      cost: 2500.0,
      odometer: 10700.0,
    ),
  ];

  group('ReportGeneratorService Tests', () {
    test('handles empty logs gracefully for all report types', () {
      for (final type in VehicleReportType.values) {
        final report = ReportGeneratorService.generateReport(
          type: type,
          activeVehicle: testVehicle,
          fuelLogs: [],
          serviceLogs: [],
        );

        expect(report.type, equals(type));
        expect(report.totalFuelSpend, equals(0.0));
        expect(report.totalServiceSpend, equals(0.0));
        expect(report.grandTotalSpend, equals(0.0));
        expect(report.totalDistanceKm, equals(0.0));
        expect(report.avgEfficiency, equals(0.0));
        expect(report.rawCsvData, isNotEmpty);
        expect(report.formattedTextReport, isNotEmpty);
      }
    });

    test('calculates accurate metrics with sample logs', () {
      final report = ReportGeneratorService.generateReport(
        type: VehicleReportType.annualSummary,
        activeVehicle: testVehicle,
        fuelLogs: sampleFuelLogs,
        serviceLogs: sampleServiceLogs,
      );

      // Total Fuel Spend: 4000 + 4500 + 4200 = 12700
      expect(report.totalFuelSpend, equals(12700.0));
      // Total Service Spend: 3500 + 2500 = 6000
      expect(report.totalServiceSpend, equals(6000.0));
      // Grand Total: 18700
      expect(report.grandTotalSpend, equals(18700.0));

      // Distance: 11000 - 10000 = 1000 km
      expect(report.totalDistanceKm, equals(1000.0));

      // Total Litres: 40 + 45 + 40 = 125 L
      expect(report.totalLitres, equals(125.0));

      // Avg Efficiency: 1000 km / 125 L = 8.0 km/L
      expect(report.avgEfficiency, equals(8.0));

      // Service categories: Oil Change = 3500, Brakes = 2500
      expect(report.serviceCategoryCosts['Oil Change'], equals(3500.0));
      expect(report.serviceCategoryCosts['Brakes'], equals(2500.0));

      // Units for non-EV
      expect(report.volumeUnit, equals('L'));
      expect(report.efficiencyUnit, equals('km/L'));
    });

    test('applies custom date range filtering accurately', () {
      // Filter for February only
      final febRange = DateTimeRange(
        start: DateTime(2026, 2, 1),
        end: DateTime(2026, 2, 28),
      );

      final report = ReportGeneratorService.generateReport(
        type: VehicleReportType.custom,
        activeVehicle: testVehicle,
        fuelLogs: sampleFuelLogs,
        serviceLogs: sampleServiceLogs,
        dateRange: febRange,
      );

      expect(report.fuelLogCount, equals(1)); // Only Feb 1 fill-up
      expect(report.serviceLogCount, equals(1)); // Only Feb 20 service
      expect(report.totalFuelSpend, equals(4500.0));
      expect(report.totalServiceSpend, equals(2500.0));
    });

    test('adapts units for EV vehicles', () {
      final report = ReportGeneratorService.generateReport(
        type: VehicleReportType.fuelEfficiency,
        activeVehicle: testEv,
        fuelLogs: [],
        serviceLogs: [],
      );

      expect(report.isElectric, isTrue);
      expect(report.volumeUnit, equals('kWh'));
      expect(report.efficiencyUnit, equals('km/kWh'));
      expect(report.rawCsvData, contains('km/kWh'));
    });

    test('calculates single-log distance against startOdo', () {
      final singleLog = [
        FuelLog(
          id: 1,
          vehicleId: 1,
          date: DateTime(2026, 1, 1),
          odometer: 10250.0,
          amount: 20.0,
          cost: 2000.0,
          isFullTank: true,
        ),
      ];

      final report = ReportGeneratorService.generateReport(
        type: VehicleReportType.fuelEfficiency,
        activeVehicle: testVehicle, // startOdo = 10000.0
        fuelLogs: singleLog,
        serviceLogs: [],
      );

      // Distance should be 10250 - 10000 = 250 km, NOT 10250 km
      expect(report.totalDistanceKm, equals(250.0));
    });
  });
}
