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

  test('Drift database inserts, queries, and deletes service logs', () async {
    final vehicleId = await db.insertVehicle(
      VehiclesCompanion.insert(
        type: 'Car',
        name: 'Test Sedan',
        startOdo: 1000,
        capacity: 45,
        fuelType: 'Octane',
      ),
    );

    final logId = await db.insertServiceLog(
      ServiceLogsCompanion.insert(
        vehicleId: vehicleId,
        date: DateTime.now(),
        category: 'Parking & Toll',
        title: 'Highway Toll',
        cost: 150.0,
        odometer: const drift.Value(1200.0),
        note: const drift.Value('Padma Bridge Toll'),
      ),
    );

    expect(logId, greaterThan(0));

    final logs = await db.getServiceLogsForVehicle(vehicleId);
    expect(logs.length, equals(1));
    expect(logs.first.title, equals('Highway Toll'));
    expect(logs.first.category, equals('Parking & Toll'));
    expect(logs.first.cost, equals(150.0));
    expect(logs.first.odometer, equals(1200.0));

    // Test delete
    await db.deleteServiceLog(logId);
    final remainingLogs = await db.getServiceLogsForVehicle(vehicleId);
    expect(remainingLogs.isEmpty, isTrue);
  });
}
