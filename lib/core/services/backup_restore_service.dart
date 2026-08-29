import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';

/// Summary metadata extracted from a backup file.
class BackupSummary {
  const BackupSummary({
    required this.app,
    required this.schemaVersion,
    required this.exportedAt,
    required this.vehicleCount,
    required this.fuelLogCount,
    required this.tripLogCount,
    required this.serviceLogCount,
    required this.reminderCount,
  });

  final String app;
  final int schemaVersion;
  final DateTime exportedAt;
  final int vehicleCount;
  final int fuelLogCount;
  final int tripLogCount;
  final int serviceLogCount;
  final int reminderCount;

  int get totalRecords =>
      vehicleCount + fuelLogCount + tripLogCount + serviceLogCount + reminderCount;
}

/// Service handling JSON serialization, native export/share, file selection, and atomic SQLite restoration.
class BackupRestoreService {
  const BackupRestoreService();

  /// Serializes all 5 Drift database tables into a structured JSON string.
  Future<String> exportBackupToJson({required AppDatabase db}) async {
    final vehicles = await db.getAllVehicles();
    final fuelLogs = await db.getAllFuelLogs();
    final tripLogs = await db.getAllTripLogs();
    final serviceLogs = await db.getAllServiceLogs();
    final reminders = await db.getAllReminders();

    final payload = {
      'app': 'Fuel-Log',
      'schemaVersion': 8,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'data': {
        'vehicles': vehicles.map((v) => {
              'id': v.id,
              'type': v.type,
              'name': v.name,
              'model': v.model,
              'brand': v.brand,
              'startOdo': v.startOdo,
              'capacity': v.capacity,
              'fuelType': v.fuelType,
              'isElectric': v.isElectric,
              'createdAt': v.createdAt.toIso8601String(),
            }).toList(),
        'fuelLogs': fuelLogs.map((f) => {
              'id': f.id,
              'vehicleId': f.vehicleId,
              'date': f.date.toIso8601String(),
              'odometer': f.odometer,
              'amount': f.amount,
              'cost': f.cost,
              'isFullTank': f.isFullTank,
              'note': f.note,
              'stationName': f.stationName,
            }).toList(),
        'tripLogs': tripLogs.map((t) => {
              'id': t.id,
              'vehicleId': t.vehicleId,
              'title': t.title,
              'origin': t.origin,
              'destination': t.destination,
              'startedAt': t.startedAt.toIso8601String(),
              'endedAt': t.endedAt.toIso8601String(),
              'startOdo': t.startOdo,
              'endOdo': t.endOdo,
              'distanceKm': t.distanceKm,
              'durationSec': t.durationSec,
              'costPerKm': t.costPerKm,
              'totalCost': t.totalCost,
              'source': t.source,
              'privacy': t.privacy,
              'note': t.note,
              'routeJson': t.routeJson,
            }).toList(),
        'serviceLogs': serviceLogs.map((s) => {
              'id': s.id,
              'vehicleId': s.vehicleId,
              'date': s.date.toIso8601String(),
              'category': s.category,
              'title': s.title,
              'cost': s.cost,
              'odometer': s.odometer,
              'note': s.note,
            }).toList(),
        'reminders': reminders.map((r) => {
              'id': r.id,
              'vehicleId': r.vehicleId,
              'title': r.title,
              'targetDate': r.targetDate?.toIso8601String(),
              'targetOdometer': r.targetOdometer,
              'isCompleted': r.isCompleted,
              'oilType': r.oilType,
              'intervalKm': r.intervalKm,
            }).toList(),
      },
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Writes the backup JSON to temporary file and returns the File.
  Future<File> createBackupFile({required AppDatabase db}) async {
    final jsonStr = await exportBackupToJson(db: db);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${tempDir.path}/FuelLog_Backup_$timestamp.json');
    return file.writeAsString(jsonStr);
  }

  /// Exports backup and opens native Share Sheet.
  Future<void> shareBackup({required AppDatabase db}) async {
    final file = await createBackupFile(db: db);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Fuel-Log Data Backup',
    );
  }

  /// Picks a JSON backup file using native file picker.
  Future<File?> pickBackupFile() async {
    final result = await FilePickerPlatform.instance.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.isEmpty) {
      return null;
    }

    final path = result.single.path;
    if (path == null) return null;
    return File(path);
  }

  /// Inspects a backup file to return its metadata and record counts.
  Future<BackupSummary> inspectBackupFile(File file) async {
    final contents = await file.readAsString();
    return inspectBackupJson(contents);
  }

  /// Inspects raw backup JSON string.
  BackupSummary inspectBackupJson(String jsonStr) {
    final Map<String, dynamic> root = jsonDecode(jsonStr) as Map<String, dynamic>;

    if (root['app'] != 'Fuel-Log' || !root.containsKey('data')) {
      throw const FormatException('Invalid backup file. Not a valid Fuel-Log backup.');
    }

    final data = root['data'] as Map<String, dynamic>;
    final vehicles = (data['vehicles'] as List?) ?? [];
    final fuelLogs = (data['fuelLogs'] as List?) ?? [];
    final tripLogs = (data['tripLogs'] as List?) ?? [];
    final serviceLogs = (data['serviceLogs'] as List?) ?? [];
    final reminders = (data['reminders'] as List?) ?? [];

    return BackupSummary(
      app: root['app'] as String? ?? 'Fuel-Log',
      schemaVersion: (root['schemaVersion'] as num?)?.toInt() ?? 1,
      exportedAt: DateTime.tryParse(root['exportedAt'] as String? ?? '') ?? DateTime.now(),
      vehicleCount: vehicles.length,
      fuelLogCount: fuelLogs.length,
      tripLogCount: tripLogs.length,
      serviceLogCount: serviceLogs.length,
      reminderCount: reminders.length,
    );
  }

  /// Restores all records from a file inside an atomic SQLite transaction.
  Future<BackupSummary> restoreBackupFromFile({
    required File file,
    required AppDatabase db,
  }) async {
    final jsonStr = await file.readAsString();
    return restoreBackupFromJson(jsonStr: jsonStr, db: db);
  }

  /// Restores all records from raw JSON string inside an atomic SQLite transaction.
  Future<BackupSummary> restoreBackupFromJson({
    required String jsonStr,
    required AppDatabase db,
  }) async {
    final Map<String, dynamic> root = jsonDecode(jsonStr) as Map<String, dynamic>;

    if (root['app'] != 'Fuel-Log' || !root.containsKey('data')) {
      throw const FormatException('Invalid backup file. Not a valid Fuel-Log backup.');
    }

    final data = root['data'] as Map<String, dynamic>;
    final vehiclesList = (data['vehicles'] as List?) ?? [];
    final fuelLogsList = (data['fuelLogs'] as List?) ?? [];
    final tripLogsList = (data['tripLogs'] as List?) ?? [];
    final serviceLogsList = (data['serviceLogs'] as List?) ?? [];
    final remindersList = (data['reminders'] as List?) ?? [];

    final oldToNewVehicleId = <int, int>{};

    await db.transaction(() async {
      // 1. Wipe existing tables cleanly to avoid primary/foreign key collisions
      await db.wipeAllData();

      // 2. Restore Vehicles and map old IDs to new IDs
      for (final raw in vehiclesList) {
        final map = raw as Map<String, dynamic>;
        final oldId = (map['id'] as num).toInt();

        final newId = await db.insertVehicle(
          VehiclesCompanion.insert(
            type: map['type'] as String? ?? 'Car',
            name: map['name'] as String? ?? 'Vehicle',
            model: map['model'] != null ? drift.Value(map['model'] as String) : const drift.Value.absent(),
            brand: map['brand'] != null ? drift.Value(map['brand'] as String) : const drift.Value.absent(),
            startOdo: (map['startOdo'] as num).toDouble(),
            capacity: (map['capacity'] as num).toDouble(),
            fuelType: map['fuelType'] as String? ?? 'Petrol',
            isElectric: drift.Value(map['isElectric'] as bool? ?? false),
            createdAt: map['createdAt'] != null
                ? drift.Value(DateTime.parse(map['createdAt'] as String))
                : const drift.Value.absent(),
          ),
        );
        oldToNewVehicleId[oldId] = newId;
      }

      // 3. Restore FuelLogs
      for (final raw in fuelLogsList) {
        final map = raw as Map<String, dynamic>;
        final oldVehId = (map['vehicleId'] as num).toInt();
        final targetVehId = oldToNewVehicleId[oldVehId];
        if (targetVehId == null) continue;

        await db.insertFuelLog(
          FuelLogsCompanion.insert(
            vehicleId: targetVehId,
            date: DateTime.parse(map['date'] as String),
            odometer: (map['odometer'] as num).toDouble(),
            amount: (map['amount'] as num).toDouble(),
            cost: (map['cost'] as num).toDouble(),
            isFullTank: drift.Value(map['isFullTank'] as bool? ?? false),
            note: map['note'] != null ? drift.Value(map['note'] as String) : const drift.Value.absent(),
            stationName: map['stationName'] != null
                ? drift.Value(map['stationName'] as String)
                : const drift.Value.absent(),
          ),
        );
      }

      // 4. Restore TripLogs
      for (final raw in tripLogsList) {
        final map = raw as Map<String, dynamic>;
        final oldVehId = (map['vehicleId'] as num).toInt();
        final targetVehId = oldToNewVehicleId[oldVehId];
        if (targetVehId == null) continue;

        await db.insertTripLog(
          TripLogsCompanion.insert(
            vehicleId: targetVehId,
            title: map['title'] != null ? drift.Value(map['title'] as String) : const drift.Value.absent(),
            origin: map['origin'] != null ? drift.Value(map['origin'] as String) : const drift.Value.absent(),
            destination:
                map['destination'] != null ? drift.Value(map['destination'] as String) : const drift.Value.absent(),
            startedAt: DateTime.parse(map['startedAt'] as String),
            endedAt: DateTime.parse(map['endedAt'] as String),
            startOdo: map['startOdo'] != null ? drift.Value((map['startOdo'] as num).toDouble()) : const drift.Value.absent(),
            endOdo: map['endOdo'] != null ? drift.Value((map['endOdo'] as num).toDouble()) : const drift.Value.absent(),
            distanceKm: (map['distanceKm'] as num).toDouble(),
            durationSec: (map['durationSec'] as num).toInt(),
            costPerKm: map['costPerKm'] != null ? drift.Value((map['costPerKm'] as num).toDouble()) : const drift.Value.absent(),
            totalCost: map['totalCost'] != null ? drift.Value((map['totalCost'] as num).toDouble()) : const drift.Value.absent(),
            source: map['source'] as String? ?? 'manual',
            privacy: map['privacy'] as String? ?? 'personal',
            note: map['note'] != null ? drift.Value(map['note'] as String) : const drift.Value.absent(),
            routeJson: map['routeJson'] != null ? drift.Value(map['routeJson'] as String) : const drift.Value.absent(),
          ),
        );
      }

      // 5. Restore ServiceLogs
      for (final raw in serviceLogsList) {
        final map = raw as Map<String, dynamic>;
        final oldVehId = (map['vehicleId'] as num).toInt();
        final targetVehId = oldToNewVehicleId[oldVehId];
        if (targetVehId == null) continue;

        await db.insertServiceLog(
          ServiceLogsCompanion.insert(
            vehicleId: targetVehId,
            date: DateTime.parse(map['date'] as String),
            category: map['category'] as String? ?? 'Maintenance',
            title: map['title'] as String? ?? 'Service',
            cost: (map['cost'] as num).toDouble(),
            odometer: map['odometer'] != null ? drift.Value((map['odometer'] as num).toDouble()) : const drift.Value.absent(),
            note: map['note'] != null ? drift.Value(map['note'] as String) : const drift.Value.absent(),
          ),
        );
      }

      // 6. Restore Reminders
      for (final raw in remindersList) {
        final map = raw as Map<String, dynamic>;
        final oldVehId = (map['vehicleId'] as num).toInt();
        final targetVehId = oldToNewVehicleId[oldVehId];
        if (targetVehId == null) continue;

        await db.insertReminder(
          RemindersCompanion.insert(
            vehicleId: targetVehId,
            title: map['title'] as String? ?? 'Reminder',
            targetDate: map['targetDate'] != null
                ? drift.Value(DateTime.parse(map['targetDate'] as String))
                : const drift.Value.absent(),
            targetOdometer: map['targetOdometer'] != null
                ? drift.Value((map['targetOdometer'] as num).toDouble())
                : const drift.Value.absent(),
            isCompleted: drift.Value(map['isCompleted'] as bool? ?? false),
            oilType: map['oilType'] != null ? drift.Value(map['oilType'] as String) : const drift.Value.absent(),
            intervalKm: map['intervalKm'] != null ? drift.Value((map['intervalKm'] as num).toDouble()) : const drift.Value.absent(),
          ),
        );
      }
    });

    return inspectBackupJson(jsonStr);
  }
}
