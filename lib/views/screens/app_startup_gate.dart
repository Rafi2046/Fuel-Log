import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../viewmodels/vehicle_viewmodel.dart';
import 'dashboard_screen.dart';
import 'splash_screen.dart';
import 'vehicle_setup_screen.dart';

/// App startup gate displaying Splash Screen with animated WebM video on launch,
/// then routing to Dashboard or Vehicle Setup based on existing vehicle data.
class AppStartupGate extends ConsumerWidget {
  const AppStartupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return vehiclesAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load app data.\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
      data: (vehicles) {
        final targetScreen = vehicles.isEmpty
            ? const VehicleSetupScreen()
            : const DashboardScreen();

        return SplashScreen(
          next: targetScreen,
          autoNavigate: vehicles.isNotEmpty,
        );
      },
    );
  }
}
