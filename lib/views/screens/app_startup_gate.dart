import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../viewmodels/vehicle_viewmodel.dart';
import 'dashboard_screen.dart';
import 'splash_screen.dart';
import 'vehicle_setup_screen.dart';

/// Routes to Dashboard when a vehicle exists, otherwise onboarding setup.
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
              'Could not load vehicles.\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
      data: (vehicles) {
        if (vehicles.isEmpty) {
          return const SplashScreen(next: VehicleSetupScreen());
        }
        return const DashboardScreen();
      },
    );
  }
}
