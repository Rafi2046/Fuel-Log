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
      ),
    );

    expect(reminderId, greaterThan(0));

    final incomplete = await db.getIncompleteRemindersForVehicle(vehicleId);
    expect(incomplete.length, equals(1));
    expect(incomplete.first.title, equals('Engine Oil Change'));
    expect(incomplete.first.targetOdometer, equals(5000.0));

    // Test completion
    await db.markReminderCompleted(reminderId);
    final remainingIncomplete =
        await db.getIncompleteRemindersForVehicle(vehicleId);
    expect(remainingIncomplete.isEmpty, isTrue);
  });
}
