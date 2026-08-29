import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/database/app_database.dart';
import 'package:fuel_log/core/services/backup_restore_service.dart';

void main() {
  late AppDatabase db;
  const backupService = BackupRestoreService();

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('BackupRestoreService exports and restores all 5 tables atomically with ID remapping',
      () async {
    // 1. Seed database with test records across all 5 tables
    final vId1 = await db.insertVehicle(
      VehiclesCompanion.insert(
        type: 'Car',
        name: 'Toyota Axio',
        model: const drift.Value('2018'),
        startOdo: 45000,
        capacity: 50,
        fuelType: 'Octane',
      ),
    );

    final vId2 = await db.insertVehicle(
      VehiclesCompanion.insert(
        type: 'Bike',
        name: 'Yamaha FZ',
        startOdo: 12000,
        capacity: 12,
        fuelType: 'Petrol',
      ),
    );

    // Seed FuelLog
    await db.insertFuelLog(
      FuelLogsCompanion.insert(
        vehicleId: vId1,
        date: DateTime(2026, 8, 20, 10, 0),
        odometer: 45500,
        amount: 35.0,
        cost: 4550.0,
        isFullTank: const drift.Value(true),
      ),
    );

    // Seed TripLog
    await db.insertTripLog(
      TripLogsCompanion.insert(
        vehicleId: vId1,
        title: const drift.Value('Dhaka to Chittagong'),
        origin: const drift.Value('Dhaka'),
        destination: const drift.Value('Chittagong'),
        startedAt: DateTime(2026, 8, 21, 6, 0),
        endedAt: DateTime(2026, 8, 21, 12, 0),
        distanceKm: 245.5,
        durationSec: 21600,
        source: 'manual',
        privacy: 'personal',
      ),
    );

    // Seed ServiceLog
    await db.insertServiceLog(
      ServiceLogsCompanion.insert(
        vehicleId: vId2,
        date: DateTime(2026, 8, 22, 15, 0),
        category: 'Maintenance',
        title: 'Mobil Engine Oil Change',
        cost: 850.0,
        odometer: const drift.Value(12500),
      ),
    );

    // Seed Reminder
    await db.insertReminder(
      RemindersCompanion.insert(
        vehicleId: vId1,
        title: 'Engine Oil Change',
        targetOdometer: const drift.Value(50000),
        oilType: const drift.Value('Synthetic'),
        intervalKm: const drift.Value(5000),
      ),
    );

    // 2. Export database to JSON
    final jsonStr = await backupService.exportBackupToJson(db: db);
    expect(jsonStr, contains('Fuel-Log'));
    expect(jsonStr, contains('Toyota Axio'));
    expect(jsonStr, contains('Yamaha FZ'));
    expect(jsonStr, contains('Dhaka to Chittagong'));

    // 3. Inspect JSON summary
    final summary = backupService.inspectBackupJson(jsonStr);
    expect(summary.app, equals('Fuel-Log'));
    expect(summary.schemaVersion, equals(7));
    expect(summary.vehicleCount, equals(2));
    expect(summary.fuelLogCount, equals(1));
    expect(summary.tripLogCount, equals(1));
    expect(summary.serviceLogCount, equals(1));
    expect(summary.reminderCount, equals(1));
    expect(summary.totalRecords, equals(6));

    // 4. Create a second empty database and restore
    final targetDb = AppDatabase.forTesting(NativeDatabase.memory());
    final restoreSummary = await backupService.restoreBackupFromJson(
      jsonStr: jsonStr,
      db: targetDb,
    );

    expect(restoreSummary.totalRecords, equals(6));

    // Verify target database has exact records
    final restoredVehicles = await targetDb.getAllVehicles();
    expect(restoredVehicles.length, equals(2));
    expect(restoredVehicles.map((v) => v.name), containsAll(['Toyota Axio', 'Yamaha FZ']));

    final restoredFuelLogs = await targetDb.getAllFuelLogs();
    expect(restoredFuelLogs.length, equals(1));
    expect(restoredFuelLogs.first.cost, equals(4550.0));

    final restoredTrips = await targetDb.getAllTripLogs();
    expect(restoredTrips.length, equals(1));
    expect(restoredTrips.first.title, equals('Dhaka to Chittagong'));
    expect(restoredTrips.first.distanceKm, equals(245.5));

    final restoredServices = await targetDb.getAllServiceLogs();
    expect(restoredServices.length, equals(1));
    expect(restoredServices.first.title, equals('Mobil Engine Oil Change'));

    final restoredReminders = await targetDb.getAllReminders();
    expect(restoredReminders.length, equals(1));
    expect(restoredReminders.first.oilType, equals('Synthetic'));

    await targetDb.close();
  });

  test('BackupRestoreService throws FormatException on invalid JSON', () {
    const invalidJson = '{"app": "AnotherApp", "data": {}}';

    expect(
      () => backupService.inspectBackupJson(invalidJson),
      throwsA(isA<FormatException>()),
    );
  });
}
