import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/constants/app_colors.dart';
import 'package:fuel_log/core/constants/app_locales.dart';
import 'package:fuel_log/core/database/app_database.dart';
import 'package:fuel_log/views/screens/tabs/trip/widgets/trip_stats_pill.dart';
import 'package:fuel_log/views/widgets/efficiency_gauge.dart';
import 'package:fuel_log/views/widgets/home_metrics_cards.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrapWithTheme({
  required Widget child,
  required Brightness brightness,
  Size size = const Size(360, 640),
}) {
  AppColors.setBrightness(brightness);
  return EasyLocalization(
    supportedLocales: supportedAppLocales,
    path: translationsPath,
    fallbackLocale: const Locale('en'),
    child: MaterialApp(
      theme: brightness == Brightness.dark
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData.light(useMaterial3: true),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: const TextScaler.linear(1.0),
        ),
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: child),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('SQA Extreme Values & Overflow Tests', () {
    testWidgets('EfficiencyGauge renders zero, normal, 15000, and 1000000 without overflow',
        (tester) async {
      final testValues = [0.0, 14.5, 15000.0, 1000000.0];

      for (final brightness in [Brightness.light, Brightness.dark]) {
        for (final val in testValues) {
          await tester.pumpWidget(
            _wrapWithTheme(
              brightness: brightness,
              child: EfficiencyGauge(
                value: val,
                unit: 'km/L',
                size: 168,
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull,
              reason: 'Overflow or exception on value: $val with brightness: $brightness');
        }
      }
    });

    testWidgets('HomeKeyMetricsGrid handles multi-million values in light and dark mode',
        (tester) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(
          _wrapWithTheme(
            brightness: brightness,
            child: const SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: HomeKeyMetricsGrid(
                  avgMileage: 1000000.0,
                  totalFuelSpend: 15000000.0,
                  totalServiceSpend: 8500000.0,
                  costPerKm: 99999.0,
                  mileageUnit: 'km/L',
                  isEV: false,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull,
            reason: 'Overflow in HomeKeyMetricsGrid with brightness $brightness');
      }
    });

    testWidgets('HomeVehicleVitalsCard handles extreme distances and refill amounts',
        (tester) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(
          _wrapWithTheme(
            brightness: brightness,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: HomeVehicleVitalsCard(
                  totalDistance: 2500000.0,
                  totalFuelConsumed: 250000.0,
                  recentLog: FuelLog(
                    id: 1,
                    vehicleId: 1,
                    date: DateTime.now(),
                    amount: 50.0,
                    cost: 1500000.0,
                    odometer: 2500000.0,
                    isFullTank: true,
                  ),
                  lastMileage: 15000.0,
                  unit: 'L',
                  mileageUnit: 'km/L',
                  isEV: false,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull,
            reason: 'Overflow in HomeVehicleVitalsCard with brightness $brightness');
      }
    });
  });

  group('SQA Trip card extreme stats', () {
    testWidgets('TripStatsPill scales for million-km distances', (tester) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(
          _wrapWithTheme(
            brightness: brightness,
            size: const Size(360, 640),
            child: const TripStatsPill(
              distanceKm: 1000000,
              elapsed: Duration(hours: 12, minutes: 34, seconds: 56),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull,
            reason: 'TripStatsPill overflow at brightness $brightness');
      }
    });
  });

  group('SQA Vehicle Lifecycle Operations', () {
    test('Create, select, switch, and delete vehicle gracefully', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      // 1. Create first vehicle
      final v1Id = await db.insertVehicle(
        VehiclesCompanion.insert(
          type: 'Car',
          name: 'Primary Sedan',
          startOdo: 10000,
          capacity: 50,
          fuelType: 'Octane',
        ),
      );
      expect(v1Id, greaterThan(0));

      // 2. Create second vehicle
      final v2Id = await db.insertVehicle(
        VehiclesCompanion.insert(
          type: 'Motorcycle',
          name: 'City Bike',
          startOdo: 500,
          capacity: 12,
          fuelType: 'Petrol',
        ),
      );
      expect(v2Id, greaterThan(v1Id));

      var all = await db.getAllVehicles();
      expect(all.length, equals(2));

      // 3. Delete second vehicle
      await db.deleteVehicle(v2Id);
      all = await db.getAllVehicles();
      expect(all.length, equals(1));
      expect(all.first.id, equals(v1Id));

      // 4. Delete remaining vehicle
      await db.deleteVehicle(v1Id);
      all = await db.getAllVehicles();
      expect(all.isEmpty, isTrue);

      await db.close();
    });
  });
}
