import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'core/constants/app_locales.dart';
import 'core/constants/app_themes.dart';
import 'views/screens/app_startup_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

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
