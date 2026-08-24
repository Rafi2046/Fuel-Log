import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/onboarding_prefs.dart';
import '../../viewmodels/vehicle_viewmodel.dart';
import 'dashboard_screen.dart';
import 'splash_screen.dart';
import 'vehicle_setup_screen.dart';

/// Tracks if user has seen the onboarding splash (persisted via SharedPreferences).
final onboardingSeenProvider = FutureProvider<bool>((ref) {
  return OnboardingPrefs.hasSeenOnboarding();
});

/// Professional startup routing:
///
/// FIRST INSTALL (never seen onboarding):
///   → Beautiful "Master Your Mileage" splash (shown ONCE, ever)
///   → GET STARTED → Vehicle Setup Wizard
///
/// EVERY SUBSEQUENT LAUNCH (onboarding already seen):
///   → Has vehicles  → Dashboard (directly, no splash)
///   → No vehicles   → Vehicle Setup (directly, no splash)
class AppStartupGate extends ConsumerWidget {
  const AppStartupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingSeenAsync = ref.watch(onboardingSeenProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);

    // Wait silently while loading
    if (onboardingSeenAsync.isLoading || vehiclesAsync.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: SizedBox.expand(),
      );
    }

    final hasSeenOnboarding = onboardingSeenAsync.asData?.value ?? false;
    final vehicles = vehiclesAsync.asData?.value ?? [];

    // ── FIRST-TIME USER: show premium onboarding splash exactly once ──────────
    if (!hasSeenOnboarding) {
      return SplashScreen(
        next: const VehicleSetupScreen(),
        autoNavigate: false,
        onGetStarted: () => OnboardingPrefs.markOnboardingComplete(),
      );
    }

    // ── RETURNING USER: jump straight to destination, no splash ──────────────
    return vehicles.isNotEmpty
        ? const DashboardScreen()
        : const VehicleSetupScreen();
  }
}
