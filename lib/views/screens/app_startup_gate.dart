import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/vehicle_viewmodel.dart';
import 'dashboard_screen.dart';
import 'splash_screen.dart';
import 'vehicle_setup_screen.dart';

/// App startup gate:
/// - Loading        → plain dark screen (no spinner flicker)
/// - No vehicles    → straight to VehicleSetupScreen (first-run onboarding wizard)
/// - Has vehicles   → branded SplashScreen intro → DashboardScreen
class AppStartupGate extends ConsumerWidget {
  const AppStartupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return vehiclesAsync.when(
      // Silent loading — no spinner, just the same dark background
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: SizedBox.expand(),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: const Color(0xFF121212),
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
        if (vehicles.isEmpty) {
          // First-time / no data: skip splash, go directly to setup wizard
          return const VehicleSetupScreen();
        }

        // Returning user: show branded 1.8s splash → Dashboard
        return const SplashScreen(
          next: DashboardScreen(),
          autoNavigate: true,
          splashDuration: Duration(milliseconds: 1800),
        );
      },
    );
  }
}
