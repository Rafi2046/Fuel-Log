import 'package:easy_localization/easy_localization.dart';
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
        return 'reportTypeSeller'.tr();
      case VehicleReportType.custom:
        return 'reportTypeCustom'.tr();
      case VehicleReportType.ownershipCost:
        return 'reportTypeOwnership'.tr();
      case VehicleReportType.annualSummary:
        return 'reportTypeAnnual'.tr();
      case VehicleReportType.fuelEfficiency:
        return 'reportTypeFuelEfficiency'.tr();
      case VehicleReportType.maintenanceHistory:
        return 'reportTypeMaintenance'.tr();
    }
  }

  String get description {
    switch (this) {
      case VehicleReportType.seller:
        return 'reportDescSeller'.tr();
      case VehicleReportType.custom:
        return 'reportDescCustom'.tr();
      case VehicleReportType.ownershipCost:
        return 'reportDescOwnership'.tr();
      case VehicleReportType.annualSummary:
        return 'reportDescAnnual'.tr();
      case VehicleReportType.fuelEfficiency:
        return 'reportDescFuelEfficiency'.tr();
      case VehicleReportType.maintenanceHistory:
        return 'reportDescMaintenance'.tr();
    }
  }

  /// One-line blurb for compact list tiles.
  String get shortDescription {
    switch (this) {
      case VehicleReportType.seller:
        return 'reportShortSeller'.tr();
      case VehicleReportType.custom:
        return 'reportShortCustom'.tr();
      case VehicleReportType.ownershipCost:
        return 'reportShortOwnership'.tr();
      case VehicleReportType.annualSummary:
        return 'reportShortAnnual'.tr();
      case VehicleReportType.fuelEfficiency:
        return 'reportShortFuelEfficiency'.tr();
      case VehicleReportType.maintenanceHistory:
        return 'reportShortMaintenance'.tr();
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
    this.isElectric = false,
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
  final bool isElectric;

  double get grandTotalSpend => totalFuelSpend + totalServiceSpend;
  String get volumeUnit => isElectric ? 'kWh' : 'L';
  String get efficiencyUnit => isElectric ? 'km/kWh' : 'km/L';
}
