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

  test('Drift database inserts and queries incomplete reminders', () async {
    final vehicleId = await db.insertVehicle(
      VehiclesCompanion.insert(
        type: 'Car',
        name: 'Test Sedan',
        startOdo: 1000,
        capacity: 45,
        fuelType: 'Octane',
      ),
    );

    final reminderId = await db.insertReminder(
      RemindersCompanion.insert(
        vehicleId: vehicleId,
        title: 'Engine Oil Change',
        targetOdometer: const drift.Value(5000.0),
        targetDate: drift.Value(DateTime.now().add(const Duration(days: 30))),
        oilType: const drift.Value('Fully Synthetic'),
        intervalKm: const drift.Value(5000.0),
      ),
    );

    expect(reminderId, greaterThan(0));

    final incomplete = await db.getIncompleteRemindersForVehicle(vehicleId);
    expect(incomplete.length, equals(1));
    expect(incomplete.first.title, equals('Engine Oil Change'));
    expect(incomplete.first.targetOdometer, equals(5000.0));
    expect(incomplete.first.oilType, equals('Fully Synthetic'));
    expect(incomplete.first.intervalKm, equals(5000.0));

    // Test completion
    await db.markReminderCompleted(reminderId);
    final remainingIncomplete =
        await db.getIncompleteRemindersForVehicle(vehicleId);
    expect(remainingIncomplete.isEmpty, isTrue);
  });

  test('deleteVehicle cascades to fuel logs, reminders, service logs, and trip logs', () async {
    final vehicleId = await db.insertVehicle(
      VehiclesCompanion.insert(
        type: 'Car',
        name: 'Cascade Test Car',
        startOdo: 1000,
        capacity: 50,
        fuelType: 'Petrol',
      ),
    );

    await db.insertFuelLog(
      FuelLogsCompanion.insert(
        vehicleId: vehicleId,
        date: DateTime.now(),
        odometer: 1100,
        amount: 20,
        cost: 2500,
      ),
    );

    await db.insertReminder(
      RemindersCompanion.insert(
        vehicleId: vehicleId,
        title: 'Brake Check',
      ),
    );

    await db.insertServiceLog(
      ServiceLogsCompanion.insert(
        vehicleId: vehicleId,
        date: DateTime.now(),
        category: 'Maintenance',
        title: 'Oil Filter Change',
        cost: 500,
      ),
    );

    await db.insertTripLog(
      TripLogsCompanion.insert(
        vehicleId: vehicleId,
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
        endedAt: DateTime.now(),
        distanceKm: 25.5,
        durationSec: 1800,
        source: 'manual',
        privacy: 'business',
      ),
    );

    // Verify all rows exist
    expect(await db.vehicleCount(), equals(1));
    expect(await db.getRemindersForVehicle(vehicleId), isNotEmpty);
    expect(await db.getServiceLogsForVehicle(vehicleId), isNotEmpty);
    expect(await db.getTripLogsForVehicle(vehicleId), isNotEmpty);

    // Delete vehicle
    await db.deleteVehicle(vehicleId);

    // Verify vehicle and all related child records are deleted
    expect(await db.vehicleCount(), equals(0));
    expect(await db.getRemindersForVehicle(vehicleId), isEmpty);
    expect(await db.getServiceLogsForVehicle(vehicleId), isEmpty);
    expect(await db.getTripLogsForVehicle(vehicleId), isEmpty);
  });
}
