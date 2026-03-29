import 'package:flutter/material.dart';

/// Centralized color tokens for the Liquid Glass design system.
/// All UI files must reference these tokens — never hardcode colors.
abstract class AppColors {
  // ─── Brand ────────────────────────────────────────────────────────────────
  static const Color seedDark = Color(0xFF6C63FF); // electric violet seed
  static const Color seedLight = Color(0xFF5B53E4);

  // ─── Glass Surfaces ───────────────────────────────────────────────────────
  static const Color glassDarkSurface = Color(0x1AFFFFFF); // 10% white
  static const Color glassDarkBorder = Color(0x33FFFFFF); // 20% white
  static const Color glassDarkOverlay = Color(0x0DFFFFFF); // 5% white

  static const Color glassLightSurface = Color(0x1A000000); // 10% black
  static const Color glassLightBorder = Color(0x25000000); // 15% black
  static const Color glassLightOverlay = Color(0x0A000000); // 4% black

  // ─── Dark Scaffold ────────────────────────────────────────────────────────
  static const Color darkScaffold = Color(0xFF0D0D14);
  static const Color darkSurface = Color(0xFF13131F);
  static const Color darkCard = Color(0xFF1A1A2E);
  static const Color darkElevated = Color(0xFF22223A);

  // ─── Light Scaffold ───────────────────────────────────────────────────────
  static const Color lightScaffold = Color(0xFFF5F5FF);
  static const Color lightSurface = Color(0xFFEEEEFB);
  static const Color lightCard = Color(0xFFE8E8F5);

  // ─── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFF0F0FF);
  static const Color textSecondaryDark = Color(0xFFB0B0D0);
  static const Color textTertiaryDark = Color(0xFF6A6A9A);

  static const Color textPrimaryLight = Color(0xFF0D0D1A);
  static const Color textSecondaryLight = Color(0xFF3A3A5C);

  // ─── Accent / Glow ────────────────────────────────────────────────────────
  static const Color glowViolet = Color(0x556C63FF);
  static const Color glowPink = Color(0x55C850C8);
  static const Color accentGradientStart = Color(0xFF6C63FF);
  static const Color accentGradientEnd = Color(0xFFC850C8);

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradientDark = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFFC850C8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scaffoldGradientDark = LinearGradient(
    colors: [Color(0xFF0D0D14), Color(0xFF13101F), Color(0xFF0A0A1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF84);
  static const Color warning = Color(0xFFFFB347);
  static const Color error = Color(0xFFFF6B6B);
}
