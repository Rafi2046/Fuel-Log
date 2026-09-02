import '../database/app_database.dart';
import '../services/mileage_calculation_service.dart';

/// Shared trip stat helpers for cards and forms.
abstract final class TripStatsHelper {
  static String formatDuration(int seconds) {
    if (seconds <= 0) return '—';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    if (m > 0) return '${m}m';
    return '${seconds}s';
  }

  static String formatAvgSpeed(double distanceKm, int durationSec) {
    if (durationSec <= 0 || distanceKm <= 0) return '—';
    final kmh = distanceKm / (durationSec / 3600);
    if (kmh < 1) return '${kmh.toStringAsFixed(1)} km/h';
    return '${kmh.toStringAsFixed(0)} km/h';
  }

  static int effectiveDurationSec(TripLog trip) {
    if (trip.durationSec > 0) return trip.durationSec;
    final diff = trip.endedAt.difference(trip.startedAt).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Average ৳/km from fuel logs (0 when unknown).
  static double averageCostPerKm(List<FuelLog> logs) {
    if (logs.isEmpty) return 0;
    final entries = MileageCalculationService.instance.computeMileageEntries(logs);
    return MileageCalculationService.instance
        .computeSummary(entries)
        .avgCostPerKm;
  }

  /// Resolved trip cost: saved total → saved rate × km → fuel-log estimate.
  static ({double? amount, bool isEstimate}) resolveCost(
    TripLog trip,
    List<FuelLog> logs,
  ) {
    if (trip.totalCost != null && trip.totalCost! > 0) {
      return (amount: trip.totalCost, isEstimate: false);
    }
    if (trip.costPerKm != null &&
        trip.costPerKm! > 0 &&
        trip.distanceKm > 0) {
      return (
        amount: trip.costPerKm! * trip.distanceKm,
        isEstimate: false,
      );
    }
    final avg = averageCostPerKm(logs);
    if (avg > 0 && trip.distanceKm > 0) {
      return (amount: avg * trip.distanceKm, isEstimate: true);
    }
    return (amount: null, isEstimate: false);
  }
}
