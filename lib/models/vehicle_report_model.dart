import 'package:flutter/material.dart';

enum VehicleReportType {
  seller,
  custom,
  ownershipCost,
  annualSummary,
  fuelEfficiency,
  maintenanceHistory,
}

extension VehicleReportTypeExtension on VehicleReportType {
  String get title {
    switch (this) {
      case VehicleReportType.seller:
        return "Seller's History Report";
      case VehicleReportType.custom:
        return 'Custom Date-Range Report';
      case VehicleReportType.ownershipCost:
        return 'Cost of Ownership Report';
      case VehicleReportType.annualSummary:
        return 'Annual Vehicle Summary';
      case VehicleReportType.fuelEfficiency:
        return 'Fuel Efficiency Analysis';
      case VehicleReportType.maintenanceHistory:
        return 'Maintenance & Workshop History';
    }
  }

  String get description {
    switch (this) {
      case VehicleReportType.seller:
        return 'Vehicle history report with fuel consumption, odo counter & cost breakdown for prospective buyers.';
      case VehicleReportType.custom:
        return 'Define date range and custom parameters to export fuel & service records.';
      case VehicleReportType.ownershipCost:
        return 'Total cost of owning your vehicle including purchase price, fuel & maintenance.';
      case VehicleReportType.annualSummary:
        return 'Year in review: total spending, distance driven, best & worst mileage months.';
      case VehicleReportType.fuelEfficiency:
        return 'Detailed consumption trends, best fill-ups, and efficiency metrics.';
      case VehicleReportType.maintenanceHistory:
        return 'Chronological service logs formatted for workshop, warranty claims, or insurance.';
    }
  }

  IconData get icon {
    switch (this) {
      case VehicleReportType.seller:
        return Icons.directions_car_filled_rounded;
      case VehicleReportType.custom:
        return Icons.tune_rounded;
      case VehicleReportType.ownershipCost:
        return Icons.account_balance_wallet_rounded;
      case VehicleReportType.annualSummary:
        return Icons.calendar_today_rounded;
      case VehicleReportType.fuelEfficiency:
        return Icons.local_gas_station_rounded;
      case VehicleReportType.maintenanceHistory:
        return Icons.build_circle_rounded;
    }
  }

  Color get color {
    switch (this) {
      case VehicleReportType.seller:
        return const Color(0xFF38BDF8);
      case VehicleReportType.custom:
        return const Color(0xFFA855F7);
      case VehicleReportType.ownershipCost:
        return const Color(0xFFF59E0B);
      case VehicleReportType.annualSummary:
        return const Color(0xFF10B981);
      case VehicleReportType.fuelEfficiency:
        return const Color(0xFFFF5722);
      case VehicleReportType.maintenanceHistory:
        return const Color(0xFFEC4899);
    }
  }
}

class VehicleReportData {
  const VehicleReportData({
    required this.type,
    required this.vehicleName,
    required this.licensePlate,
    required this.dateGenerated,
    required this.startDate,
    required this.endDate,
    required this.totalFuelSpend,
    required this.totalServiceSpend,
    required this.totalDistanceKm,
    required this.avgEfficiency,
    required this.avgCostPerKm,
    required this.fuelLogCount,
    required this.serviceLogCount,
    required this.rawCsvData,
    required this.formattedTextReport,
  });

  final VehicleReportType type;
  final String vehicleName;
  final String licensePlate;
  final DateTime dateGenerated;
  final DateTime startDate;
  final DateTime endDate;
  final double totalFuelSpend;
  final double totalServiceSpend;
  final double totalDistanceKm;
  final double avgEfficiency;
  final double avgCostPerKm;
  final int fuelLogCount;
  final int serviceLogCount;
  final String rawCsvData;
  final String formattedTextReport;

  double get grandTotalSpend => totalFuelSpend + totalServiceSpend;
}
