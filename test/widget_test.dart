import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/constants/app_locales.dart';
import 'package:fuel_log/core/database/app_database.dart';
import 'package:fuel_log/main.dart';
import 'package:fuel_log/viewmodels/vehicle_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('onboarding leads to vehicle setup', (tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: supportedAppLocales,
        path: translationsPath,
        fallbackLocale: const Locale('en'),
        child: ProviderScope(
          overrides: [
            // Empty DB → first-run onboarding (avoid real SQLite in tests).
            vehiclesProvider.overrideWith(
              (ref) => Stream<List<Vehicle>>.value(const []),
            ),
          ],
          child: const FuelLogApp(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Master', findRichText: true), findsOneWidget);
    expect(find.text('GET STARTED'), findsOneWidget);

    await tester.tap(find.text('GET STARTED'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Vehicle Name'), findsOneWidget);
    expect(find.text('Car'), findsOneWidget);
  });
}
