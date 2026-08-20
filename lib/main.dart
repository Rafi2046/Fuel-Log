import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/constants/app_themes.dart';
import 'views/screens/splash_screen.dart';
import 'views/screens/vehicle_setup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const FuelLogApp());
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
