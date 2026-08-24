import '../../models/mileage_entry_model.dart';
import '../database/app_database.dart';

/// Pure computation service for vehicle fuel mileage & efficiency statistics.
class MileageCalculationService {
  MileageCalculationService._();
  static final MileageCalculationService instance = MileageCalculationService._();

  /// Converts raw fuel logs into processed [MileageEntryModel] items sorted newest first.
  List<MileageEntryModel> computeMileageEntries(List<FuelLog> logs) {
    if (logs.isEmpty) return const [];

    // Sort chronologically ascending for accurate delta odometer math
    final sorted = List<FuelLog>.from(logs)
      ..sort((a, b) => a.odometer.compareTo(b.odometer));

    final entries = <MileageEntryModel>[];
    FuelLog? lastFullTankLog;
    var accumulatedPartialFuel = 0.0;
    var hasHadPartial = false;

    for (var i = 0; i < sorted.length; i++) {
      final current = sorted[i];

      if (i == 0) {
        // Initial baseline fill-up
        if (current.isFullTank) {
          lastFullTankLog = current;
        } else {
          accumulatedPartialFuel += current.amount;
          hasHadPartial = true;
        }

        entries.add(MileageEntryModel(log: current));
        continue;
      }

      final prevLog = sorted[i - 1];
      final deltaDistance = current.odometer - prevLog.odometer;

      if (current.isFullTank) {
        final referenceFullLog = lastFullTankLog ?? prevLog;
        final distSinceFull = current.odometer - referenceFullLog.odometer;
        final totalFuelUsed = accumulatedPartialFuel + current.amount;

        double? kmPerLitre;
        double? l100km;
        double? mpg;
        double? costPerKm;

        if (distSinceFull > 0 && totalFuelUsed > 0) {
          kmPerLitre = distSinceFull / totalFuelUsed;
          l100km = (totalFuelUsed / distSinceFull) * 100.0;

          // Convert km & Litres to Miles & US Gallons
          final miles = distSinceFull * 0.621371;
          final gallons = totalFuelUsed * 0.264172;
          mpg = miles / gallons;
        }

        if (deltaDistance > 0 && current.cost > 0) {
          costPerKm = current.cost / deltaDistance;
        }

        entries.add(
          MileageEntryModel(
            log: current,
            distanceDriven: deltaDistance > 0 ? deltaDistance : null,
            consumptionL100km: l100km,
            kmPerLitre: kmPerLitre,
            milesPerGallon: mpg,
            costPerKm: costPerKm,
            isPartialAccumulated: hasHadPartial,
          ),
        );

        // Reset tracking for next full tank interval
        lastFullTankLog = current;
        accumulatedPartialFuel = 0.0;
        hasHadPartial = false;
      } else {
        // Partial tank fill-up
        accumulatedPartialFuel += current.amount;
        hasHadPartial = true;

        double? costPerKm;
        if (deltaDistance > 0 && current.cost > 0) {
          costPerKm = current.cost / deltaDistance;
        }

        entries.add(
          MileageEntryModel(
            log: current,
            distanceDriven: deltaDistance > 0 ? deltaDistance : null,
            costPerKm: costPerKm,
            isPartialAccumulated: true,
          ),
        );
      }
    }

    // Return newest entries first for UI display
    return entries.reversed.toList();
  }

  /// Calculates overall summary stats across all recorded logs.
  MileageVehicleSummary computeSummary(List<MileageEntryModel> entries) {
    if (entries.isEmpty) return MileageVehicleSummary.empty;

    var totalDistance = 0.0;
    var totalFuel = 0.0;
    var totalCost = 0.0;

    final validKmLList = <double>[];
    final validL100List = <double>[];
    final validMpgList = <double>[];
    final validCostPerKmList = <double>[];

    for (final e in entries) {
      if (e.distanceDriven != null && e.distanceDriven! > 0) {
        totalDistance += e.distanceDriven!;
      }
      totalFuel += e.log.amount;
      totalCost += e.log.cost;

      if (e.kmPerLitre != null) validKmLList.add(e.kmPerLitre!);
      if (e.consumptionL100km != null) validL100List.add(e.consumptionL100km!);
      if (e.milesPerGallon != null) validMpgList.add(e.milesPerGallon!);
      if (e.costPerKm != null) validCostPerKmList.add(e.costPerKm!);
    }

    final avgKmL = validKmLList.isNotEmpty
        ? validKmLList.reduce((a, b) => a + b) / validKmLList.length
        : (totalFuel > 0 && totalDistance > 0 ? totalDistance / totalFuel : 0.0);

    final avgL100 = validL100List.isNotEmpty
        ? validL100List.reduce((a, b) => a + b) / validL100List.length
        : (totalDistance > 0 && totalFuel > 0 ? (totalFuel / totalDistance) * 100 : 0.0);

    final avgMpg = validMpgList.isNotEmpty
        ? validMpgList.reduce((a, b) => a + b) / validMpgList.length
        : 0.0;

    final avgCostKm = validCostPerKmList.isNotEmpty
        ? validCostPerKmList.reduce((a, b) => a + b) / validCostPerKmList.length
        : (totalDistance > 0 ? totalCost / totalDistance : 0.0);

    return MileageVehicleSummary(
      avgKmPerLitre: avgKmL,
      avgL100km: avgL100,
      avgMpg: avgMpg,
      totalDistanceDriven: totalDistance,
      totalFuelAmount: totalFuel,
      totalCost: totalCost,
      avgCostPerKm: avgCostKm,
      totalLogCount: entries.length,
    );
  }
}
