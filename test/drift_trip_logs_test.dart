import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Drift database inserts, queries, and deletes trip logs', () async {
    final vehicleId = await db.insertVehicle(
      VehiclesCompanion.insert(
        type: 'Car',
        name: 'Trip Test Car',
        startOdo: 15000,
        capacity: 50,
        fuelType: 'Petrol',
      ),
    );

    final startedAt = DateTime(2026, 8, 27, 8, 0);
    final endedAt = DateTime(2026, 8, 27, 9, 30);

    final tripLogId = await db.insertTripLog(
      TripLogsCompanion.insert(
        vehicleId: vehicleId,
        title: const drift.Value('Morning Commute'),
        origin: const drift.Value('Uttara'),
        destination: const drift.Value('Motijheel'),
        startedAt: startedAt,
        endedAt: endedAt,
        startOdo: const drift.Value(15000.0),
        endOdo: const drift.Value(15024.5),
        distanceKm: 24.5,
        durationSec: 5400,
        costPerKm: const drift.Value(12.5),
        totalCost: const drift.Value(306.25),
        source: 'gps',
        privacy: 'business',
        note: const drift.Value('Office commute via Express Elevated Way'),
        routeJson: const drift.Value('{"coordinates":[[90.4,23.8],[90.41,23.72]]}'),
      ),
    );

    expect(tripLogId, greaterThan(0));

    final tripLogs = await db.getTripLogsForVehicle(vehicleId);
    expect(tripLogs.length, equals(1));

    final trip = tripLogs.first;
    expect(trip.title, equals('Morning Commute'));
    expect(trip.origin, equals('Uttara'));
    expect(trip.destination, equals('Motijheel'));
    expect(trip.startedAt, equals(startedAt));
    expect(trip.endedAt, equals(endedAt));
    expect(trip.startOdo, equals(15000.0));
    expect(trip.endOdo, equals(15024.5));
    expect(trip.distanceKm, equals(24.5));
    expect(trip.durationSec, equals(5400));
    expect(trip.costPerKm, equals(12.5));
    expect(trip.totalCost, equals(306.25));
    expect(trip.source, equals('gps'));
    expect(trip.privacy, equals('business'));
    expect(trip.note, equals('Office commute via Express Elevated Way'));
    expect(trip.routeJson, equals('{"coordinates":[[90.4,23.8],[90.41,23.72]]}'));

    // Test delete
    await db.deleteTripLog(tripLogId);
    final remaining = await db.getTripLogsForVehicle(vehicleId);
    expect(remaining.isEmpty, isTrue);
  });
}
