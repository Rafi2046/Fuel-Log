import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_locales.dart';
import 'core/constants/app_themes.dart';
import 'core/services/bd_fuel_rate_service.dart';
import 'core/utils/notification_service.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'views/screens/app_startup_gate.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Allow GoogleFonts to download & cache fonts locally.
  GoogleFonts.config.allowRuntimeFetching = true;

  try {
    await EasyLocalization.ensureInitialized();
  } catch (e, stack) {
    debugPrint('EasyLocalization init failed: $e\n$stack');
  }

  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

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

  WidgetsBinding.instance.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
  });

  // iOS: never block the UI isolate on notification setup.
  if (Platform.isIOS) {
    scheduleMicrotask(_bootstrapServices);
  } else {
    unawaited(_bootstrapServices());
  }
}

Future<void> _bootstrapServices() async {
  try {
    await NotificationService().init();
  } catch (e, stack) {
    debugPrint('NotificationService init failed: $e\n$stack');
  }

  // ignore: unawaited_futures
  BdFuelRateService.instance.ensureLoaded(forceRefresh: true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('weather_tips_alerts_enabled') ?? true;
    if (enabled) {
      await NotificationService().scheduleMorningWeatherTip(
        title: 'weatherMorningTitle'.tr(),
        body: 'weatherMorningBody'.tr(),
      );
    }
  } catch (e, stack) {
    debugPrint('Weather tip scheduling failed: $e\n$stack');
  }
}

class FuelLogApp extends ConsumerWidget {
  const FuelLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final platformBrightness = ref.watch(platformBrightnessProvider);
    syncAppColorsPalette(themeMode, platformBrightness);
    final brightness = resolveAppBrightness(themeMode, platformBrightness);

    final overlay = brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: MaterialApp(
        title: 'FuelSync',
        debugShowCheckedModeBanner: false,
        theme: AppThemes.light,
        darkTheme: AppThemes.dark,
        themeMode: themeMode,
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        builder: (context, child) {
          // AppColors is static — keep it on the *active* MaterialApp theme and
          // remount the subtree so glass cards/icons never stay one mode behind.
          final active = Theme.of(context).brightness;
          AppColors.setBrightness(active);
          return KeyedSubtree(
            key: ValueKey(active),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const AppStartupGate(),
      ),
    );
  }
}
