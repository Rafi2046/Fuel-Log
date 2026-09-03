import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fuel_log/core/constants/app_colors.dart';
import 'package:fuel_log/core/constants/app_themes.dart';
import 'package:fuel_log/viewmodels/theme_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('light and dark palettes differ for surfaces/text', () {
    AppColors.setBrightness(Brightness.dark);
    final darkBg = AppColors.background;
    final darkText = AppColors.textPrimary;

    AppColors.setBrightness(Brightness.light);
    expect(AppColors.background, isNot(equals(darkBg)));
    expect(AppColors.textPrimary, isNot(equals(darkText)));
    expect(AppColors.primary, const Color(0xFFFF7A50));
  });

  test('theme builders do not leak brightness into AppColors', () {
    AppColors.setBrightness(Brightness.light);
    final _ = AppThemes.dark;
    expect(AppColors.isDark, isFalse);
    final __ = AppThemes.light;
    expect(AppColors.isDark, isFalse);
  });

  test('resolveAppBrightness respects mode', () {
    expect(
      resolveAppBrightness(ThemeMode.light, Brightness.dark),
      Brightness.light,
    );
    expect(
      resolveAppBrightness(ThemeMode.dark, Brightness.light),
      Brightness.dark,
    );
    expect(
      resolveAppBrightness(ThemeMode.system, Brightness.light),
      Brightness.light,
    );
  });

  test('light secondary/tertiary text are darker than slate-400', () {
    AppColors.setBrightness(Brightness.light);
    // #94A3B8 was too faint on white; require stronger greys.
    expect(AppColors.textSecondary.computeLuminance(), lessThan(0.25));
    expect(AppColors.textTertiary.computeLuminance(), lessThan(0.35));
    expect(AppColors.mapOverlay.computeLuminance(), greaterThan(0.8));
    expect(AppColors.onMapOverlay.computeLuminance(), lessThan(0.1));
  });

  test('dark map overlay stays dark with light on-text', () {
    AppColors.setBrightness(Brightness.dark);
    expect(AppColors.mapOverlay.computeLuminance(), lessThan(0.2));
    expect(AppColors.onMapOverlay.computeLuminance(), greaterThan(0.8));
  });

  test('light wash tokens are visible on white cards', () {
    AppColors.setBrightness(Brightness.light);
    expect(AppColors.wash.computeLuminance(), lessThan(0.95));
    expect(AppColors.wash, isNot(equals(AppColors.card)));
  });
}
