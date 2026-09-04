import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/vehicle_report_model.dart';
import '../database/app_database.dart';
import '../utils/app_formatters.dart';

class ReportGeneratorService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  static VehicleReportData generateReport({
    required VehicleReportType type,
    required Vehicle activeVehicle,
    required List<FuelLog> fuelLogs,
    required List<ServiceLog> serviceLogs,
    DateTimeRange? dateRange,
  }) {
    final now = DateTime.now();
    final isEV = activeVehicle.isElectric;
    final unit = isEV ? 'kWh' : 'L';
    final efficiencyUnit = isEV ? 'km/kWh' : 'km/L';

    final List<FuelLog> filteredFuel;
    final List<ServiceLog> filteredService;
    final DateTime startDate;
    final DateTime endDate;

    if (dateRange != null) {
      startDate = dateRange.start;
      endDate = dateRange.end;
      filteredFuel = fuelLogs.where((log) {
        return (log.date.isAfter(startDate) ||
                log.date.isAtSameMomentAs(startDate)) &&
            (log.date.isBefore(endDate.add(const Duration(days: 1))));
      }).toList();
      filteredService = serviceLogs.where((log) {
        return (log.date.isAfter(startDate) ||
                log.date.isAtSameMomentAs(startDate)) &&
            (log.date.isBefore(endDate.add(const Duration(days: 1))));
      }).toList();
    } else if (type == VehicleReportType.annualSummary) {
      // Annual summary defaults to past 365 days if no custom range is picked
      endDate = now;
      startDate = now.subtract(const Duration(days: 365));
      filteredFuel = fuelLogs.where((log) {
        return (log.date.isAfter(startDate) ||
                log.date.isAtSameMomentAs(startDate)) &&
            (log.date.isBefore(endDate.add(const Duration(days: 1))));
      }).toList();
      filteredService = serviceLogs.where((log) {
        return (log.date.isAfter(startDate) ||
                log.date.isAtSameMomentAs(startDate)) &&
            (log.date.isBefore(endDate.add(const Duration(days: 1))));
      }).toList();
    } else {
      // All dates: include all logs without arbitrary 365-day cutoff
      filteredFuel = List<FuelLog>.from(fuelLogs);
      filteredService = List<ServiceLog>.from(serviceLogs);
      endDate = now;
      DateTime? earliest;
      for (final l in filteredFuel) {
        if (earliest == null || l.date.isBefore(earliest)) earliest = l.date;
      }
      for (final s in filteredService) {
        if (earliest == null || s.date.isBefore(earliest)) earliest = s.date;
      }
      startDate = earliest ?? activeVehicle.createdAt;
    }

    final totalFuelSpend = filteredFuel.fold(0.0, (s, l) => s + l.cost);
    final totalServiceSpend = filteredService.fold(0.0, (s, l) => s + l.cost);
    final grandTotal = totalFuelSpend + totalServiceSpend;

    double totalDistanceKm = 0.0;
    if (filteredFuel.length >= 2) {
      final sorted = List<FuelLog>.from(filteredFuel)
        ..sort((a, b) => a.odometer.compareTo(b.odometer));
      final diff = sorted.last.odometer - sorted.first.odometer;
      totalDistanceKm = diff > 0 ? diff : 0.0;
    } else if (filteredFuel.length == 1 &&
        filteredFuel.first.odometer > activeVehicle.startOdo) {
      totalDistanceKm = (filteredFuel.first.odometer - activeVehicle.startOdo)
          .clamp(0.0, double.infinity);
    }

    final avgCostPerKm =
        totalDistanceKm > 0 ? (grandTotal / totalDistanceKm) : 0.0;

    // Average efficiency & Fuel stats
    final double totalLitres = filteredFuel.fold(0.0, (s, l) => s + l.amount);
    final avgEfficiency =
        (totalLitres > 0 && totalDistanceKm > 0)
            ? (totalDistanceKm / totalLitres)
            : 0.0;

    final avgFuelPrice =
        totalLitres > 0 ? (totalFuelSpend / totalLitres) : 0.0;

    final sortedFuel = List<FuelLog>.from(filteredFuel)
      ..sort((a, b) => a.odometer.compareTo(b.odometer));

    final List<double> efficiencies = [];
    for (int i = 1; i < sortedFuel.length; i++) {
      final prev = sortedFuel[i - 1];
      final curr = sortedFuel[i];
      final dist = curr.odometer - prev.odometer;
      if (curr.amount > 0 && dist > 0) {
        efficiencies.add(dist / curr.amount);
      }
    }

    final double bestEfficiency =
        efficiencies.isNotEmpty ? efficiencies.reduce((a, b) => a > b ? a : b) : avgEfficiency;
    final double worstEfficiency =
        efficiencies.isNotEmpty ? efficiencies.reduce((a, b) => a < b ? a : b) : avgEfficiency;

    final Map<String, double> serviceCategoryCosts = {};
    for (final s in filteredService) {
      serviceCategoryCosts[s.category] =
          (serviceCategoryCosts[s.category] ?? 0.0) + s.cost;
    }

    final vehicleModelText =
        activeVehicle.model != null && activeVehicle.model!.isNotEmpty
            ? activeVehicle.model!
            : activeVehicle.type;

    // CSV Generation
    final StringBuffer csv = StringBuffer();
    csv.writeln('FUEL LOG REPORT - ${type.title.toUpperCase()}');
    csv.writeln('Vehicle,${activeVehicle.name}');
    csv.writeln('Type/Model,$vehicleModelText');
    csv.writeln(
        'Period,${_dateFormat.format(startDate)} to ${_dateFormat.format(endDate)}');
    csv.writeln('Generated Date,${_dateTimeFormat.format(now)}');
    csv.writeln('');
    csv.writeln('--- SUMMARY METRICS ---');
    csv.writeln('Total Fuel Spend,${AppCurrency.format(totalFuelSpend)}');
    csv.writeln('Total Service Spend,${AppCurrency.format(totalServiceSpend)}');
    csv.writeln('Grand Total Spend,${AppCurrency.format(grandTotal)}');
    csv.writeln('Total Distance,${totalDistanceKm.toStringAsFixed(1)} km');
    csv.writeln('Cost Per KM,${AppCurrency.format(avgCostPerKm)} / km');
    csv.writeln('Average Efficiency,${avgEfficiency.toStringAsFixed(2)} $efficiencyUnit');
    if (bestEfficiency > 0) {
      csv.writeln('Best Efficiency,${bestEfficiency.toStringAsFixed(2)} $efficiencyUnit');
    }
    csv.writeln('');
    csv.writeln('--- REFUELING LOGS ---');
    csv.writeln(
        'Date,Odometer (km),Amount ($unit),Cost,Price/Unit,Full Tank,Note');
    for (final l in filteredFuel) {
      final unitPrice = l.amount > 0 ? (l.cost / l.amount) : 0.0;
      csv.writeln(
        '${_dateFormat.format(l.date)},${l.odometer},${l.amount},${l.cost},${unitPrice.toStringAsFixed(2)},${l.isFullTank},"${l.note ?? ''}"',
      );
    }
    csv.writeln('');
    csv.writeln('--- SERVICE & MAINTENANCE LOGS ---');
    csv.writeln('Date,Category,Title,Cost,Odometer (km),Note');
    for (final s in filteredService) {
      csv.writeln(
        '${_dateFormat.format(s.date)},"${s.category}","${s.title}",${s.cost},${s.odometer ?? 0},"${s.note ?? ''}"',
      );
    }

    // Text Summary Report
    final StringBuffer textReport = StringBuffer();
    textReport.writeln('📋 ${type.title.toUpperCase()}');
    textReport.writeln(
        '🚗 Vehicle: ${activeVehicle.name} ($vehicleModelText)');
    textReport.writeln(
        '📅 Period: ${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}');
    textReport.writeln('──────────────────────────────');
    textReport.writeln('💰 Total Spend: ${AppCurrency.format(grandTotal)}');
    textReport.writeln(
        '⛽ Fuel Cost: ${AppCurrency.format(totalFuelSpend)} (${filteredFuel.length} fill-ups, ${totalLitres.toStringAsFixed(1)} $unit)');
    textReport.writeln(
        '🛠️ Service Cost: ${AppCurrency.format(totalServiceSpend)} (${filteredService.length} services)');
    textReport.writeln('📏 Distance: ${totalDistanceKm.toStringAsFixed(0)} km');
    textReport.writeln('📊 Cost/km: ${AppCurrency.format(avgCostPerKm)} / km');
    textReport.writeln(
        '🚀 Avg Mileage: ${avgEfficiency.toStringAsFixed(1)} $efficiencyUnit');
    if (bestEfficiency > 0 && bestEfficiency != avgEfficiency) {
      textReport.writeln(
          '⭐ Best Mileage: ${bestEfficiency.toStringAsFixed(1)} $efficiencyUnit');
    }
    textReport.writeln('──────────────────────────────');
    textReport.writeln('Generated via Fuel-Log App on ${_dateFormat.format(now)}');

    return VehicleReportData(
      type: type,
      vehicleName: activeVehicle.name,
      licensePlate: vehicleModelText,
      dateGenerated: now,
      startDate: startDate,
      endDate: endDate,
      totalFuelSpend: totalFuelSpend,
      totalServiceSpend: totalServiceSpend,
      totalDistanceKm: totalDistanceKm,
      avgEfficiency: avgEfficiency,
      avgCostPerKm: avgCostPerKm,
      fuelLogCount: filteredFuel.length,
      serviceLogCount: filteredService.length,
      totalLitres: totalLitres,
      avgFuelPrice: avgFuelPrice,
      bestEfficiency: bestEfficiency,
      worstEfficiency: worstEfficiency,
      serviceCategoryCosts: serviceCategoryCosts,
      rawCsvData: csv.toString(),
      formattedTextReport: textReport.toString(),
      fuelLogs: filteredFuel,
      serviceLogs: filteredService,
      isElectric: isEV,
    );
  }
}
