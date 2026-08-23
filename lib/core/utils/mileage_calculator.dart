import '../database/app_database.dart';

/// One plotted efficiency sample (fill after a prior odometer baseline).
class EfficiencyPoint {
  const EfficiencyPoint({required this.date, required this.efficiency});

  final DateTime date;
  final double efficiency;
}

/// Average distance per unit of fuel/charge from a log series.
///
/// Uses odometer span ÷ sum of amounts after the first fill
/// (first fill establishes the baseline, so its amount is excluded).
double calculateAverageMileage(List<FuelLog> logs) {
  if (logs.length < 2) return 0.0;

  final sorted = List<FuelLog>.from(logs)
    ..sort((a, b) => a.odometer.compareTo(b.odometer));

  final totalDistance = sorted.last.odometer - sorted.first.odometer;
  var totalAmount = 0.0;
  for (var i = 1; i < sorted.length; i++) {
    totalAmount += sorted[i].amount;
  }

  if (totalAmount <= 0 || totalDistance <= 0) return 0.0;
  return totalDistance / totalAmount;
}

/// Per-fill efficiency points (chronological).
///
/// Pass [maxPoints] null to keep the full history (for scrollable charts).
List<EfficiencyPoint> buildEfficiencySeries(
  List<FuelLog> logs, {
  int? maxPoints = 8,
}) {
  if (logs.length < 2) return const [];

  final byOdo = List<FuelLog>.from(logs)
    ..sort((a, b) => a.odometer.compareTo(b.odometer));

  final points = <EfficiencyPoint>[];
  for (var i = 1; i < byOdo.length; i++) {
    final distance = byOdo[i].odometer - byOdo[i - 1].odometer;
    final amount = byOdo[i].amount;
    if (distance <= 0 || amount <= 0) continue;
    points.add(
      EfficiencyPoint(
        date: byOdo[i].date,
        efficiency: distance / amount,
      ),
    );
  }

  points.sort((a, b) => a.date.compareTo(b.date));
  if (maxPoints == null || points.length <= maxPoints) return points;
  return points.sublist(points.length - maxPoints);
}
