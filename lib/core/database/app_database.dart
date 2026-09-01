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

  TextColumn get stationName => text().nullable()();
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

/// Vehicle documents & certificates (Tax Token, Insurance, Registration, etc.)
class VehicleDocuments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get vehicleId => integer().references(Vehicles, #id)();

  /// e.g. 'tax_token', 'registration', 'fitness', 'insurance', 'driving_license', 'route_permit', 'nid', 'pollution', 'other'
  TextColumn get category => text()();

  TextColumn get title => text()();

  TextColumn get documentNumber => text().nullable()();

  DateTimeColumn get issueDate => dateTime().nullable()();

  DateTimeColumn get expiryDate => dateTime().nullable()();

  TextColumn get frontImagePath => text().nullable()();

  TextColumn get backImagePath => text().nullable()();

  TextColumn get fileType => text().nullable()();

  RealColumn get cost => real().nullable()();

  TextColumn get issuingAuthority => text().nullable()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// E-Documents table for storing vehicle & driving documents (Driving License, Tax Token, Registration, Fitness).
class EDocuments extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Nullable because personal documents (e.g. Driving License) belong to the user, not a specific vehicle.
  IntColumn get vehicleId => integer().nullable().references(Vehicles, #id)();

  /// Document type: 'driving_license', 'tax_token', 'registration', 'fitness', 'insurance', etc.
  TextColumn get docType => text()();

  /// Local path to saved image or PDF in app's internal documents directory.
  TextColumn get filePath => text()();

  /// Optional expiry date for reminders and validity warnings.
  DateTimeColumn get expiryDate => dateTime().nullable()();

  /// Document upload / creation timestamp.
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
    tables: [Vehicles, FuelLogs, Reminders, ServiceLogs, TripLogs, VehicleDocuments, EDocuments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  /// Bumped for EDocuments table (v10).
  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 7) {
            await m.addColumn(vehicles, vehicles.brand);
          }
          if (from < 8) {
            await m.addColumn(fuelLogs, fuelLogs.stationName);
          }
          if (from < 9) {
            await m.createTable(vehicleDocuments);
          }
          if (from < 10) {
            await m.createTable(eDocuments);
          }
        },
      );

  Future<int> insertVehicle(VehiclesCompanion vehicle) =>
      into(vehicles).insert(vehicle);

  Future<int> vehicleCount() async {
    final rows = await select(vehicles).get();
    return rows.length;
  }

  /// Removes a vehicle and its associated reminders, fuel logs, service logs, trip logs, and documents.
  Future<void> deleteVehicle(int id) async {
    await (delete(eDocuments)..where((t) => t.vehicleId.equals(id))).go();
    await (delete(vehicleDocuments)..where((t) => t.vehicleId.equals(id))).go();
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

  Future<bool> updateFuelLog(FuelLog log) => update(fuelLogs).replace(log);

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

  Future<Reminder?> getReminderById(int id) {
    return (select(reminders)..where((t) => t.id.equals(id))).getSingleOrNull();
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

  // Document Vault queries
  Future<int> insertDocument(VehicleDocumentsCompanion document) =>
      into(vehicleDocuments).insert(document);

  Future<bool> updateDocument(VehicleDocument document) =>
      update(vehicleDocuments).replace(document);

  Future<int> deleteDocument(int id) =>
      (delete(vehicleDocuments)..where((t) => t.id.equals(id))).go();

  Stream<List<VehicleDocument>> watchDocumentsForVehicle(int vehicleId) {
    return (select(vehicleDocuments)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.expiryDate),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  Stream<List<VehicleDocument>> watchAllDocuments() {
    return (select(vehicleDocuments)
          ..orderBy([
            (t) => OrderingTerm.asc(t.expiryDate),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  Future<List<VehicleDocument>> getDocumentsForVehicle(int vehicleId) {
    return (select(vehicleDocuments)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.expiryDate),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .get();
  }

  // ---------------------------------------------------------------------------
  // E-Document queries & operations (EDocuments)
  // ---------------------------------------------------------------------------

  Future<int> insertEDocument(EDocumentsCompanion doc) =>
      into(eDocuments).insert(doc);

  Future<List<EDocument>> getAllEDocuments() => select(eDocuments).get();

  Stream<List<EDocument>> watchAllEDocuments() => (select(eDocuments)
        ..orderBy([
          (t) => OrderingTerm.asc(t.expiryDate),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
      .watch();

  Future<List<EDocument>> getEDocumentsForVehicle(int? vehicleId) {
    if (vehicleId == null) {
      return (select(eDocuments)
            ..where((t) => t.vehicleId.isNull())
            ..orderBy([
              (t) => OrderingTerm.asc(t.expiryDate),
              (t) => OrderingTerm.desc(t.createdAt),
            ]))
          .get();
    }
    return (select(eDocuments)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.expiryDate),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .get();
  }

  Stream<List<EDocument>> watchEDocumentsForVehicle(int? vehicleId) {
    if (vehicleId == null) {
      return (select(eDocuments)
            ..where((t) => t.vehicleId.isNull())
            ..orderBy([
              (t) => OrderingTerm.asc(t.expiryDate),
              (t) => OrderingTerm.desc(t.createdAt),
            ]))
          .watch();
    }
    return (select(eDocuments)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.expiryDate),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  Future<List<EDocument>> getPersonalEDocuments() =>
      (select(eDocuments)..where((t) => t.vehicleId.isNull())).get();

  Stream<List<EDocument>> watchPersonalEDocuments() =>
      (select(eDocuments)..where((t) => t.vehicleId.isNull())).watch();

  Future<List<EDocument>> getExpiringEDocuments({int days = 30}) {
    final now = DateTime.now();
    final threshold = now.add(Duration(days: days));
    return (select(eDocuments)
          ..where((t) =>
              t.expiryDate.isNotNull() &
              t.expiryDate.isBiggerOrEqualValue(now) &
              t.expiryDate.isSmallerOrEqualValue(threshold)))
        .get();
  }

  Future<EDocument?> getEDocumentById(int id) =>
      (select(eDocuments)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<bool> updateEDocument(EDocument doc) =>
      update(eDocuments).replace(doc);

  Future<int> deleteEDocument(int id) =>
      (delete(eDocuments)..where((t) => t.id.equals(id))).go();

  // Backup & Restore queries
  Future<List<Vehicle>> getAllVehicles() => select(vehicles).get();
  Future<List<FuelLog>> getAllFuelLogs() => select(fuelLogs).get();
  Future<List<TripLog>> getAllTripLogs() => select(tripLogs).get();
  Future<List<ServiceLog>> getAllServiceLogs() => select(serviceLogs).get();
  Future<List<Reminder>> getAllReminders() => select(reminders).get();
  Future<List<VehicleDocument>> getAllDocuments() =>
      select(vehicleDocuments).get();

  Future<void> wipeAllData() async {
    await transaction(() async {
      await delete(eDocuments).go();
      await delete(vehicleDocuments).go();
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
