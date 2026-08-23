import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'core/constants/app_themes.dart';
import 'views/screens/splash_screen.dart';
import 'views/screens/vehicle_setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure the sqlite3_flutter_libs plugin is registered / linked.
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(
    const ProviderScope(
      child: FuelLogApp(),
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
      home: const SplashScreen(next: VehicleSetupScreen()),
    );
  }
}
