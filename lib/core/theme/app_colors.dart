import 'package:flutter/material.dart';

/// LANCR colour tokens.
///
/// Tokens are runtime getters that resolve to the light or dark value based on
/// [isDark]. The app root sets [isDark] from the persisted theme preference on
/// every build, so flipping the theme repaints the whole tree.
class AppColors {
  AppColors._();

  /// Set by the app root each build (see LancrApp). Drives every token below.
  static bool isDark = false;

  // ── Light values ─────────────────────────────────────────
  static const _lightPrimary = Color(0xFF00A19B);
  static const _lightPrimaryLight = Color(0xFFE0F5F4);
  static const _lightBackground = Color(0xFFEDE8E1);
  static const _lightSurface = Color(0xFFF5F1EC);
  static const _lightTextPrimary = Color(0xFF1A1A1A);
  static const _lightTextSecondary = Color(0xFF7A7470);
  static const _lightShadow = Color(0xFFD6CFC6);

  // ── Dark values (Palette B — Neutral ink) ────────────────
  static const _darkPrimary = Color(0xFF25C9BC);
  static const _darkPrimaryLight = Color(0xFF0E2E2B);
  static const _darkBackground = Color(0xFF0F1113);
  static const _darkSurface = Color(0xFF1A1D1F);
  static const _darkTextPrimary = Color(0xFFECEEEF);
  static const _darkTextSecondary = Color(0xFF9AA0A3);
  static const _darkShadow = Color(0xFF2A2E31);

  // ── Resolved tokens ──────────────────────────────────────
  static Color get primary => isDark ? _darkPrimary : _lightPrimary;
  static Color get primaryLight =>
      isDark ? _darkPrimaryLight : _lightPrimaryLight;
  static Color get background => isDark ? _darkBackground : _lightBackground;
  static Color get surface => isDark ? _darkSurface : _lightSurface;
  static Color get textPrimary => isDark ? _darkTextPrimary : _lightTextPrimary;
  static Color get textSecondary =>
      isDark ? _darkTextSecondary : _lightTextSecondary;
  static Color get shadow => isDark ? _darkShadow : _lightShadow;

  // Theme-invariant.
  static const white = Color(0xFFFFFFFF);
}
