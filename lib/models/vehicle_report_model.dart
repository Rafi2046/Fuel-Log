import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/constants/app_colors.dart';

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

  /// One-line blurb for compact list tiles.
  String get shortDescription {
    switch (this) {
      case VehicleReportType.seller:
        return 'Fuel, odometer & cost for buyers';
      case VehicleReportType.custom:
        return 'Export logs for a custom range';
      case VehicleReportType.ownershipCost:
        return 'Purchase, fuel & maintenance total';
      case VehicleReportType.annualSummary:
        return 'Yearly spend, distance & mileage';
      case VehicleReportType.fuelEfficiency:
        return 'Consumption trends & fill-ups';
      case VehicleReportType.maintenanceHistory:
        return 'Service logs for workshop use';
    }
  }

  IconData get icon {
    switch (this) {
      case VehicleReportType.seller:
        return LucideIcons.car;
      case VehicleReportType.custom:
        return LucideIcons.slidersHorizontal;
      case VehicleReportType.ownershipCost:
        return LucideIcons.wallet;
      case VehicleReportType.annualSummary:
        return LucideIcons.calendar;
      case VehicleReportType.fuelEfficiency:
        return LucideIcons.gauge;
      case VehicleReportType.maintenanceHistory:
        return LucideIcons.wrench;
    }
  }

  Color get color => AppColors.primary;
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
    required this.totalLitres,
    required this.avgFuelPrice,
    required this.bestEfficiency,
    required this.worstEfficiency,
    required this.serviceCategoryCosts,
    required this.rawCsvData,
    required this.formattedTextReport,
    this.fuelLogs = const [],
    this.serviceLogs = const [],
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
  final double totalLitres;
  final double avgFuelPrice;
  final double bestEfficiency;
  final double worstEfficiency;
  final Map<String, double> serviceCategoryCosts;
  final String rawCsvData;
  final String formattedTextReport;
  final List<dynamic> fuelLogs;
  final List<dynamic> serviceLogs;

  double get grandTotalSpend => totalFuelSpend + totalServiceSpend;
}
