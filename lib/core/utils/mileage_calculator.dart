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

/// Unit price at a fill (৳ per L / kWh).
class FuelPricePoint {
  const FuelPricePoint({required this.date, required this.price});

  final DateTime date;
  final double price;
}

/// Distance driven in a calendar month.
class MonthlyDistancePoint {
  const MonthlyDistancePoint({
    required this.year,
    required this.month,
    required this.km,
  });

  final int year;
  final int month;
  final double km;

  DateTime get period => DateTime(year, month);
}

/// Per-fill unit price (cost ÷ amount), chronological.
///
/// Pass [maxPoints] null to keep full history (fullscreen).
List<FuelPricePoint> buildFuelPriceSeries(
  List<FuelLog> logs, {
  int? maxPoints = 8,
}) {
  final points = <FuelPricePoint>[];
  for (final log in logs) {
    if (log.amount <= 0 || log.cost < 0) continue;
    points.add(
      FuelPricePoint(
        date: log.date,
        price: log.cost / log.amount,
      ),
    );
  }
  points.sort((a, b) => a.date.compareTo(b.date));
  if (maxPoints == null || points.length <= maxPoints) return points;
  return points.sublist(points.length - maxPoints);
}

/// Monthly distance from consecutive odometer gaps (credited to later fill’s month).
///
/// Pass [maxMonths] null to keep all months; otherwise the most recent N.
List<MonthlyDistancePoint> buildMonthlyDistanceSeries(
  List<FuelLog> logs, {
  int? maxMonths = 6,
}) {
  if (logs.length < 2) return const [];

  final byOdo = List<FuelLog>.from(logs)
    ..sort((a, b) => a.odometer.compareTo(b.odometer));

  final totals = <String, double>{};
  for (var i = 1; i < byOdo.length; i++) {
    final distance = byOdo[i].odometer - byOdo[i - 1].odometer;
    if (distance <= 0) continue;
    final d = byOdo[i].date;
    final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
    totals[key] = (totals[key] ?? 0) + distance;
  }

  final points = totals.entries.map((e) {
    final parts = e.key.split('-');
    return MonthlyDistancePoint(
      year: int.parse(parts[0]),
      month: int.parse(parts[1]),
      km: e.value,
    );
  }).toList()
    ..sort((a, b) => a.period.compareTo(b.period));

  if (maxMonths == null || points.length <= maxMonths) return points;
  return points.sublist(points.length - maxMonths);
}
