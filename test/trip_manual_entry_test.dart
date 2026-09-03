import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/constants/app_locales.dart';
import 'package:fuel_log/core/database/app_database.dart';
import 'package:fuel_log/viewmodels/vehicle_viewmodel.dart';
import 'package:fuel_log/views/widgets/app_primary_button.dart';
import 'package:fuel_log/views/widgets/trip_manual_entry_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('TripManualEntrySheet saves manual trip to database',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    final vehicleId = await db.insertVehicle(
      VehiclesCompanion.insert(
        type: 'Car',
        name: 'Manual Trip Test Car',
        startOdo: 1000,
        capacity: 45,
        fuelType: 'Petrol',
      ),
    );

    final vehicle = (await db.select(db.vehicles).get()).first;

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        activeVehicleProvider.overrideWithValue(AsyncData(vehicle)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: EasyLocalization(
          supportedLocales: supportedAppLocales,
          path: translationsPath,
          fallbackLocale: const Locale('en'),
          child: const MaterialApp(
            home: Scaffold(
              body: TripManualEntrySheet(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Find TextFormFields
    final textFields = find.byType(TextFormField);
    expect(textFields, findsWidgets);

    // Title
    await tester.enterText(textFields.at(0), 'Client Meeting');
    // Origin
    await tester.enterText(textFields.at(1), 'Dhanmondi');
    // Start Odo
    await tester.enterText(textFields.at(2), '1200');
    // Destination
    await tester.enterText(textFields.at(3), 'Gulshan');
    // End Odo
    await tester.enterText(textFields.at(4), '1215');
    await tester.pumpAndSettle();

    // Verify distance auto-calculation (1215 - 1200 = 15)
    final distanceField = textFields.at(7);
    final distanceWidget = tester.widget<TextFormField>(distanceField);
    expect(distanceWidget.controller?.text, equals('15'));

    // Tap Save Trip button
    final saveButton = find.byType(AppPrimaryButton);
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify trip is saved in database
    final trips = await db.getTripLogsForVehicle(vehicleId);
    expect(trips.length, equals(1));
    expect(trips.first.title, equals('Client Meeting'));
    expect(trips.first.origin, equals('Dhanmondi'));
    expect(trips.first.destination, equals('Gulshan'));
    expect(trips.first.startOdo, equals(1200.0));
    expect(trips.first.endOdo, equals(1215.0));
    expect(trips.first.distanceKm, equals(15.0));
    expect(trips.first.source, equals('manual'));

    await db.close();
    container.dispose();
  });

  testWidgets('TripManualEntrySheet prefills GPS distance, duration, and places',
      (tester) async {
    final startedAt = DateTime(2026, 8, 28, 9, 0);
    final endedAt = DateTime(2026, 8, 28, 9, 45);

    await tester.pumpWidget(
      ProviderScope(
        child: EasyLocalization(
          supportedLocales: supportedAppLocales,
          path: translationsPath,
          fallbackLocale: const Locale('en'),
          child: MaterialApp(
            home: Scaffold(
              body: TripManualEntrySheet(
                prefill: TripManualEntryPrefill(
                  initialDistanceKm: 12.5,
                  initialDurationSec: 2700,
                  initialOrigin: 'Dhanmondi',
                  initialDestination: 'Gulshan',
                  startedAt: startedAt,
                  endedAt: endedAt,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final textFields = find.byType(TextFormField);
    expect((tester.widget<TextFormField>(textFields.at(1)).controller?.text),
        equals('Dhanmondi'));
    expect((tester.widget<TextFormField>(textFields.at(3)).controller?.text),
        equals('Gulshan'));
    expect((tester.widget<TextFormField>(textFields.at(7)).controller?.text),
        equals('12.5'));
  });
}
