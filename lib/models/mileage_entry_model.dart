import '../core/database/app_database.dart';

/// Enumeration of supported fuel efficiency unit types.
enum EfficiencyUnit {
  kmPerLitre,
  l100km,
  mpg;

  String get label {
    switch (this) {
      case EfficiencyUnit.kmPerLitre:
        return 'km/L';
      case EfficiencyUnit.l100km:
        return 'L/100km';
      case EfficiencyUnit.mpg:
        return 'MPG';
    }
  }
}

/// Represents a single fuel log entry enriched with computed mileage statistics.
class MileageEntryModel {
  const MileageEntryModel({
    required this.log,
    this.distanceDriven,
    this.consumptionL100km,
    this.kmPerLitre,
    this.milesPerGallon,
    this.costPerKm,
    this.isPartialAccumulated = false,
  });

  final FuelLog log;

  /// Distance driven in kilometers since the previous full-tank log.
  final double? distanceDriven;

  /// Litres per 100 km (standard metric).
  final double? consumptionL100km;

  /// Kilometers per Litre.
  final double? kmPerLitre;

  /// Miles per US Gallon.
  final double? milesPerGallon;

  /// Cost per kilometer driven.
  final double? costPerKm;

  /// True if this entry represents a full fill-up after one or more partial fills.
  final bool isPartialAccumulated;

  /// Returns formatted efficiency value based on selected [unit].
  String formatEfficiency(EfficiencyUnit unit) {
    String fmt(double? value, String suffix) {
      if (value == null) return '--';
      if (value >= 1000) return '${value.toStringAsFixed(0)} $suffix';
      return '${value.toStringAsFixed(1)} $suffix';
    }

    switch (unit) {
      case EfficiencyUnit.kmPerLitre:
        return fmt(kmPerLitre, 'km/L');
      case EfficiencyUnit.l100km:
        return fmt(consumptionL100km, 'L/100km');
      case EfficiencyUnit.mpg:
        return fmt(milesPerGallon, 'MPG');
    }
  }

  /// Returns double value of efficiency for the given [unit].
  double? getEfficiencyValue(EfficiencyUnit unit) {
    switch (unit) {
      case EfficiencyUnit.kmPerLitre:
        return kmPerLitre;
      case EfficiencyUnit.l100km:
        return consumptionL100km;
      case EfficiencyUnit.mpg:
        return milesPerGallon;
    }
  }
}

/// Overall vehicle mileage summary stats.
class MileageVehicleSummary {
  const MileageVehicleSummary({
    required this.avgKmPerLitre,
    required this.avgL100km,
    required this.avgMpg,
    required this.totalDistanceDriven,
    required this.totalFuelAmount,
    required this.totalCost,
    required this.avgCostPerKm,
    required this.totalLogCount,
  });

  final double avgKmPerLitre;
  final double avgL100km;
  final double avgMpg;
  final double totalDistanceDriven;
  final double totalFuelAmount;
  final double totalCost;
  final double avgCostPerKm;
  final int totalLogCount;

  static const empty = MileageVehicleSummary(
    avgKmPerLitre: 0.0,
    avgL100km: 0.0,
    avgMpg: 0.0,
    totalDistanceDriven: 0.0,
    totalFuelAmount: 0.0,
    totalCost: 0.0,
    avgCostPerKm: 0.0,
    totalLogCount: 0,
  );
}
