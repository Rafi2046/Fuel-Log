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
}

@DriftDatabase(tables: [Vehicles, FuelLogs, Reminders])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  /// Bumped to force recreate after capacity / EV column renames & Reminders table.
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Early-dev: wipe and recreate whenever schema moves forward.
          if (from < schemaVersion) {
            await customStatement('DROP TABLE IF EXISTS reminders');
            await customStatement('DROP TABLE IF EXISTS fuel_logs');
            await customStatement('DROP TABLE IF EXISTS vehicles');
            await m.createAll();
          }
        },
      );

  Future<int> insertVehicle(VehiclesCompanion vehicle) =>
      into(vehicles).insert(vehicle);

  Future<int> vehicleCount() async {
    final rows = await select(vehicles).get();
    return rows.length;
  }

  /// Removes a vehicle and its fuel logs.
  Future<void> deleteVehicle(int id) async {
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
