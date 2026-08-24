import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/models/reminder_model.dart';
import 'package:fuel_log/core/services/reminder_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ServiceReminder Model Tests', () {
    test('calculates remaining km and health progress correctly', () {
      final now = DateTime.now();
      final reminder = ServiceReminder(
        id: 'test_oil',
        vehicleId: 1,
        title: 'Engine Oil',
        serviceType: ServiceType.engineOil,
        lastServiceOdo: 10000,
        lastServiceDate: now.subtract(const Duration(days: 10)),
        intervalKm: 2000,
        intervalDays: 60,
      );

      // Current odo is 10,500 km (500 km done out of 2000 km -> 1500 km left)
      expect(reminder.remainingKm(10500), 1500);
      expect(reminder.status(10500), ReminderStatus.healthy);

      // Current odo is 11,850 km (150 km left -> within 200km threshold -> due soon)
      expect(reminder.status(11850), ReminderStatus.dueSoon);

      // Current odo is 12,050 km (overdue by 50 km)
      expect(reminder.status(12050), ReminderStatus.overdue);
    });

    test('calculates overdue by days when km is still remaining', () {
      final now = DateTime.now();
      final reminder = ServiceReminder(
        id: 'test_oil',
        vehicleId: 1,
        title: 'Engine Oil',
        serviceType: ServiceType.engineOil,
        lastServiceOdo: 10000,
        lastServiceDate: now.subtract(const Duration(days: 65)), // 65 days passed (interval is 60)
        intervalKm: 2000,
        intervalDays: 60,
      );

      // Even if odo is still 10,200 km, the days exceeded -> overdue
      expect(reminder.status(10200), ReminderStatus.overdue);
    });
  });

  group('ReminderRepository Tests', () {
    test('adds and retrieves reminders per vehicle', () async {
      final repo = ReminderRepository.instance;
      final emptyList = await repo.getReminders(
        vehicleId: 1,
        isBike: true,
        currentOdo: 5000,
      );
      expect(emptyList.isEmpty, true);

      final now = DateTime.now();
      final newReminder = ServiceReminder(
        id: 'user_oil_1',
        vehicleId: 1,
        title: 'Engine Oil Change',
        serviceType: ServiceType.engineOil,
        lastServiceOdo: 5000,
        lastServiceDate: now,
        intervalKm: 2000,
        intervalDays: 60,
      );

      await repo.addReminder(newReminder);
      final list = await repo.getReminders(
        vehicleId: 1,
        isBike: true,
        currentOdo: 5000,
      );
      expect(list.length, 1);
      expect(list.first.title, 'Engine Oil Change');
    });

    test('marks as completed and resets cycle for next interval', () async {
      final repo = ReminderRepository.instance;
      final now = DateTime.now();
      final oilReminder = ServiceReminder(
        id: 'oil_2',
        vehicleId: 1,
        title: 'Engine Oil Change',
        serviceType: ServiceType.engineOil,
        lastServiceOdo: 7000,
        lastServiceDate: now,
        intervalKm: 2000,
        intervalDays: 60,
      );
      await repo.addReminder(oilReminder);

      final updated = await repo.markAsCompleted(
        id: oilReminder.id,
        currentOdometer: 7200,
        cost: 650.0,
      );

      expect(updated, isNotNull);
      expect(updated!.lastServiceOdo, 7200);
      expect(updated.lastCost, 650.0);
      expect(updated.remainingKm(7200), 2000); // Resets to full 2000 km
    });
  });
}
