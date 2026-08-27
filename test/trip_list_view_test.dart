import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/constants/app_locales.dart';
import 'package:fuel_log/core/database/app_database.dart';
import 'package:fuel_log/viewmodels/vehicle_viewmodel.dart';
import 'package:fuel_log/views/screens/tabs/trip/widgets/trip_list_view.dart';
import 'package:fuel_log/views/screens/tabs/trip/widgets/trip_summary_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('TripListView displays empty state when no trips are recorded',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final vehicleId = await db.insertVehicle(
      VehiclesCompanion.insert(
        type: 'Car',
        name: 'Empty State Car',
        startOdo: 5000,
        capacity: 40,
        fuelType: 'Octane',
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
              body: TripListView(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.text('No trips recorded yet. Start exploring.'),
      findsOneWidget,
    );

    await db.close();
    container.dispose();
  });

  testWidgets('TripListView displays trips and supports swipe to delete',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final vehicleId = await db.insertVehicle(
      VehiclesCompanion.insert(
        type: 'Car',
        name: 'Trip List Car',
        startOdo: 5000,
        capacity: 40,
        fuelType: 'Octane',
      ),
    );

    final startedAt = DateTime(2026, 8, 27, 10, 0);
    final endedAt = DateTime(2026, 8, 27, 11, 0);

    final tripId = await db.insertTripLog(
      TripLogsCompanion.insert(
        vehicleId: vehicleId,
        title: const drift.Value('Airport Drop'),
        origin: const drift.Value('Banani'),
        destination: const drift.Value('Hazrat Shahjalal Airport'),
        startedAt: startedAt,
        endedAt: endedAt,
        distanceKm: 12.8,
        durationSec: 3600,
        source: 'manual',
        privacy: 'business',
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
              body: TripListView(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify TripSummaryCard elements
    expect(find.byType(TripSummaryCard), findsOneWidget);
    expect(find.text('Airport Drop'), findsOneWidget);
    expect(find.text('Banani'), findsOneWidget);
    expect(find.text('Hazrat Shahjalal Airport'), findsOneWidget);
    expect(find.text('12.8 km'), findsOneWidget);
    expect(find.text('BUSINESS'), findsOneWidget);

    // Swipe to delete
    final dismissibleFinder = find.byType(Dismissible);
    expect(dismissibleFinder, findsOneWidget);

    await tester.drag(dismissibleFinder, const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Verify deleted from database
    final remaining = await db.getTripLogsForVehicle(vehicleId);
    expect(remaining.isEmpty, isTrue);

    // Verify empty state is now displayed
    expect(
      find.text('No trips recorded yet. Start exploring.'),
      findsOneWidget,
    );

    await db.close();
    container.dispose();
  });
}
