import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'core/constants/app_locales.dart';
import 'core/constants/app_themes.dart';
import 'core/services/bd_fuel_rate_service.dart';
import 'core/utils/notification_service.dart';
import 'views/screens/app_startup_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await NotificationService().init();

  // Prefetch BD BPC fuel rates (OpenVan) — non-blocking for UI.
  // ignore: unawaited_futures
  BdFuelRateService.instance.ensureLoaded(forceRefresh: true);

  // Schedule daily weather tip if user has tips enabled (default on).
  // ignore: unawaited_futures
  () async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('weather_tips_alerts_enabled') ?? true;
      if (enabled) {
        await NotificationService().scheduleMorningWeatherTip(
          title: 'weatherMorningTitle'.tr(),
          body: 'weatherMorningBody'.tr(),
        );
      }
    } catch (_) {}
  }();

  // Ensure the sqlite3_flutter_libs plugin is registered / linked.
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(
    EasyLocalization(
      supportedLocales: supportedAppLocales,
      path: translationsPath,
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(
        child: FuelLogApp(),
      ),
    ),
  );
}

class FuelLogApp extends StatelessWidget {
  const FuelLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fuel Log',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.dark,
      themeMode: ThemeMode.dark,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: const AppStartupGate(),
    );
  }
}
