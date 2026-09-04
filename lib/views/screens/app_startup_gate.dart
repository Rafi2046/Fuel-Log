import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_regions.dart';
import '../../core/services/onboarding_prefs.dart';
import '../../viewmodels/region_viewmodel.dart';
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
class AppStartupGate extends ConsumerStatefulWidget {
  const AppStartupGate({super.key});

  @override
  ConsumerState<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends ConsumerState<AppStartupGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep EasyLocalization in sync with persisted language+currency region.
    ref.listen(appRegionProvider, (prev, next) {
      if (context.locale.languageCode != next.locale.languageCode) {
        context.setLocale(next.locale);
      }
    });

    final onboardingSeenAsync = ref.watch(onboardingSeenProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);

    if (onboardingSeenAsync.hasError || vehiclesAsync.hasError) {
      final error = onboardingSeenAsync.error ?? vehiclesAsync.error;
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Startup failed: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    // Wait silently while loading
    if (onboardingSeenAsync.isLoading || vehiclesAsync.isLoading) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: const Color(0xFF121212),
        ),
        child: const Scaffold(
          backgroundColor: Color(0xFF121212),
          body: SizedBox.expand(),
        ),
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
