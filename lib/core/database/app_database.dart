import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'app_database.g.dart';

/// Local vehicle registry (car / bike profiles).
class Vehicles extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// e.g. 'Car' or 'Bike'
  TextColumn get type => text()();

  TextColumn get name => text()();

  TextColumn get model => text().nullable()();

  TextColumn get brand => text().nullable()();

  RealColumn get startOdo => real()();

  /// Tank liters or battery kWh (energy-agnostic).
  RealColumn get capacity => real()();

  /// e.g. 'Petrol', 'Octane', 'Electric (EV)'
  TextColumn get fuelType => text()();

  BoolColumn get isElectric =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Fuel / energy fill-up entries per vehicle.
class FuelLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get vehicleId => integer().references(Vehicles, #id)();

  DateTimeColumn get date => dateTime()();

  RealColumn get odometer => real()();

  /// Liters or kWh depending on vehicle energy type.
  RealColumn get amount => real()();

  RealColumn get cost => real()();

  BoolColumn get isFullTank =>
      boolean().withDefault(const Constant(false))();

  TextColumn get note => text().nullable()();
}

/// Maintenance and service reminders per vehicle.
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get vehicleId => integer().references(Vehicles, #id)();

  TextColumn get title => text()();

  DateTimeColumn get targetDate => dateTime().nullable()();

  RealColumn get targetOdometer => real().nullable()();

  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  TextColumn get oilType => text().nullable()();

  RealColumn get intervalKm => real().nullable()();
}

/// Non-fuel service and general expense records per vehicle.
class ServiceLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get vehicleId => integer().references(Vehicles, #id)();

  DateTimeColumn get date => dateTime()();

  TextColumn get category => text()();

  TextColumn get title => text()();

  RealColumn get cost => real()();

  RealColumn get odometer => real().nullable()();

  TextColumn get note => text().nullable()();
}

/// Trip log records per vehicle (GPS or manual).
class TripLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get vehicleId => integer().references(Vehicles, #id)();

  TextColumn get title => text().nullable()();

  TextColumn get origin => text().nullable()();

  TextColumn get destination => text().nullable()();

  DateTimeColumn get startedAt => dateTime()();

  DateTimeColumn get endedAt => dateTime()();

  RealColumn get startOdo => real().nullable()();

  RealColumn get endOdo => real().nullable()();

  RealColumn get distanceKm => real()();

  IntColumn get durationSec => integer()();

  RealColumn get costPerKm => real().nullable()();

  RealColumn get totalCost => real().nullable()();

  TextColumn get source => text()();

  TextColumn get privacy => text()();

  TextColumn get note => text().nullable()();

  TextColumn get routeJson => text().nullable()();
}

@DriftDatabase(tables: [Vehicles, FuelLogs, Reminders, ServiceLogs, TripLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  /// Bumped for Vehicles brand column (v7).
  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 7) {
            await m.addColumn(vehicles, vehicles.brand);
          }
        },
      );

  Future<int> insertVehicle(VehiclesCompanion vehicle) =>
      into(vehicles).insert(vehicle);

  Future<int> vehicleCount() async {
    final rows = await select(vehicles).get();
    return rows.length;
  }

  /// Removes a vehicle and its associated reminders, fuel logs, service logs, and trip logs.
  Future<void> deleteVehicle(int id) async {
    await (delete(tripLogs)..where((t) => t.vehicleId.equals(id))).go();
    await (delete(serviceLogs)..where((t) => t.vehicleId.equals(id))).go();
    await (delete(reminders)..where((t) => t.vehicleId.equals(id))).go();
    await (delete(fuelLogs)..where((t) => t.vehicleId.equals(id))).go();
    await (delete(vehicles)..where((t) => t.id.equals(id))).go();
  }

  Future<int> insertFuelLog(FuelLogsCompanion log) =>
      into(fuelLogs).insert(log);

  Future<int> deleteFuelLog(int id) {
    return (delete(fuelLogs)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<Vehicle>> watchAllVehicles() => select(vehicles).watch();

  /// Fuel logs for one vehicle, newest first.
  Stream<List<FuelLog>> watchLogsForVehicle(int vehicleId) {
    return (select(fuelLogs)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<int> insertReminder(RemindersCompanion reminder) =>
      into(reminders).insert(reminder);

  Future<bool> updateReminder(Reminder reminder) =>
      update(reminders).replace(reminder);

  Future<List<Reminder>> getIncompleteRemindersForVehicle(int vehicleId) {
    return (select(reminders)
          ..where((t) =>
              t.vehicleId.equals(vehicleId) & t.isCompleted.equals(false)))
        .get();
  }

  Future<List<Reminder>> getRemindersForVehicle(int vehicleId) {
    return (select(reminders)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.asc(t.targetDate),
          ]))
        .get();
  }

  Stream<List<Reminder>> watchRemindersForVehicle(int vehicleId) {
    return (select(reminders)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.asc(t.targetDate),
          ]))
        .watch();
  }

  Future<int> markReminderCompleted(int id) {
    return (update(reminders)..where((t) => t.id.equals(id)))
        .write(const RemindersCompanion(isCompleted: Value(true)));
  }

  Future<int> deleteReminder(int id) {
    return (delete(reminders)..where((t) => t.id.equals(id))).go();
  }

  Future<int> insertServiceLog(ServiceLogsCompanion log) =>
      into(serviceLogs).insert(log);

  Future<int> deleteServiceLog(int id) {
    return (delete(serviceLogs)..where((t) => t.id.equals(id))).go();
  }

  Future<List<ServiceLog>> getServiceLogsForVehicle(int vehicleId) {
    return (select(serviceLogs)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Stream<List<ServiceLog>> watchServiceLogsForVehicle(int vehicleId) {
    return (select(serviceLogs)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<int> insertTripLog(TripLogsCompanion log) =>
      into(tripLogs).insert(log);

  Future<int> deleteTripLog(int id) {
    return (delete(tripLogs)..where((t) => t.id.equals(id))).go();
  }

  Future<List<TripLog>> getTripLogsForVehicle(int vehicleId) {
    return (select(tripLogs)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
  }

  Stream<List<TripLog>> watchTripLogsForVehicle(int vehicleId) {
    return (select(tripLogs)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .watch();
  }

  // Backup & Restore queries
  Future<List<Vehicle>> getAllVehicles() => select(vehicles).get();
  Future<List<FuelLog>> getAllFuelLogs() => select(fuelLogs).get();
  Future<List<TripLog>> getAllTripLogs() => select(tripLogs).get();
  Future<List<ServiceLog>> getAllServiceLogs() => select(serviceLogs).get();
  Future<List<Reminder>> getAllReminders() => select(reminders).get();

  Future<void> wipeAllData() async {
    await transaction(() async {
      await delete(tripLogs).go();
      await delete(serviceLogs).go();
      await delete(reminders).go();
      await delete(fuelLogs).go();
      await delete(vehicles).go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'fuel_log.sqlite'));

    // Load bundled libsqlite3 from the Flutter plugin (not Dart FFI assets).
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    return NativeDatabase.createInBackground(file);
  });
}
