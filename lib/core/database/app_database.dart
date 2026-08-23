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

@DriftDatabase(tables: [Vehicles, FuelLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Bumped to force recreate after capacity / EV column renames.
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Early-dev: wipe and recreate whenever schema moves forward.
          if (from < schemaVersion) {
            await customStatement('DROP TABLE IF EXISTS fuel_logs');
            await customStatement('DROP TABLE IF EXISTS vehicles');
            await m.createAll();
          }
        },
      );

  Future<int> insertVehicle(VehiclesCompanion vehicle) =>
      into(vehicles).insert(vehicle);

  Stream<List<Vehicle>> watchAllVehicles() => select(vehicles).watch();
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
