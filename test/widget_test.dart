import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/constants/app_locales.dart';
import 'package:fuel_log/core/database/app_database.dart';
import 'package:fuel_log/main.dart';
import 'package:fuel_log/viewmodels/vehicle_viewmodel.dart';
import 'package:fuel_log/views/screens/app_startup_gate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('first install → shows onboarding splash', (tester) async {
    // No onboarding flag set → first install
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: supportedAppLocales,
        path: translationsPath,
        fallbackLocale: const Locale('en'),
        child: ProviderScope(
          overrides: [
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

    // Premium onboarding splash should show
    expect(find.textContaining('Master', findRichText: true), findsOneWidget);
    expect(find.text('GET STARTED'), findsOneWidget);
  });

  testWidgets('returning user → skips splash, goes to vehicle setup',
      (tester) async {
    // Onboarding already completed
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: supportedAppLocales,
        path: translationsPath,
        fallbackLocale: const Locale('en'),
        child: ProviderScope(
          overrides: [
            vehiclesProvider.overrideWith(
              (ref) => Stream<List<Vehicle>>.value(const []),
            ),
            onboardingSeenProvider.overrideWith((ref) async => true),
          ],
          child: const FuelLogApp(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Onboarding splash must NOT appear for returning users
    expect(find.text('GET STARTED'), findsNothing);
    expect(find.textContaining('Master', findRichText: true), findsNothing);
  });
}
