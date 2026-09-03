import 'package:flutter/material.dart';

/// Semantic app palette — switches with [setBrightness] when theme changes.
///
/// Brand accents (`primary`, status colors) stay constant so existing
/// `const … AppColors.primary` call sites keep compiling.
abstract final class AppColors {
  static Brightness _brightness = Brightness.dark;

  static Brightness get brightness => _brightness;
  static bool get isDark => _brightness == Brightness.dark;

  /// Call from the root app whenever [ThemeMode] resolves to a new brightness.
  static void setBrightness(Brightness value) {
    _brightness = value;
  }

  // ── Brand / status (same in light & dark) ─────────────────────────────
  static const Color primary = Color(0xFFFF7A50);
  static const Color primaryMuted = Color(0x33FF7A50);
  static const Color secondary = Color(0xFFFF9B73);
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF5A623);
  static const Color error = Color(0xFFE74C3C);

  // ── Surfaces ──────────────────────────────────────────────────────────
  static Color get background =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF4F5F7);
  static Color get surface =>
      isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
  static Color get card =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
  static Color get cardElevated =>
      isDark ? const Color(0xFF252525) : const Color(0xFFF0F1F4);

  static Color get appBar =>
      isDark ? const Color(0xFF161622) : const Color(0xFFFFFFFF);
  static Color get appBarDivider =>
      isDark ? const Color(0xFF262638) : const Color(0xFFE6E8EE);

  /// Back-button / compact control fill.
  static Color get control =>
      isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF0F1F5);
  static Color get controlBorder =>
      isDark ? const Color(0xFF2A2A3E) : const Color(0xFFD8DBE4);

  static Color get inputFill =>
      isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F1F5);
  static Color get scaffoldOverlay =>
      isDark ? const Color(0xCC121212) : const Color(0xCCF4F5F7);

  // ── Text ──────────────────────────────────────────────────────────────
  static Color get textPrimary =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF12131A);
  /// Secondary body / subtitles — tuned for WCAG AA on card surfaces.
  static Color get textSecondary =>
      isDark ? const Color(0xFFB0B0B0) : const Color(0xFF4B5563);
  /// Captions / muted labels — still readable on white cards.
  static Color get textTertiary =>
      isDark ? const Color(0xFF8A8A8A) : const Color(0xFF5B6472);

  // ── Map floating chrome (follows app theme for readable contrast) ─────
  static Color get mapOverlay =>
      isDark ? const Color(0xF018181F) : const Color(0xF5FFFFFF);
  static Color get mapOverlayBorder =>
      isDark ? const Color(0xFF2E2E38) : const Color(0xFFE2E5EC);
  static Color get onMapOverlay => textPrimary;
  static Color get onMapOverlayMuted => textSecondary;

  // ── Borders / glass ───────────────────────────────────────────────────
  static Color get border =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E5EC);
  static Color get borderStrong =>
      isDark ? const Color(0xFFE8E8E8) : const Color(0xFFC5CAD6);
  static Color get divider =>
      isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE6E8EE);
  static Color get glassBorder =>
      isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0x1A12131A);
  static Color get hairline =>
      isDark ? const Color(0xFF262638) : const Color(0xFFE6E8EE);

  /// Soft wash fill (empty-state circles, nested panels) — readable in both themes.
  static Color get wash =>
      isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF0F1F5);
  static Color get washStrong =>
      isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE8EAF0);
  static Color get washBorder =>
      isDark ? Colors.white.withValues(alpha: 0.08) : border;
  static Color get washDivider =>
      isDark ? Colors.white.withValues(alpha: 0.06) : divider;
}
