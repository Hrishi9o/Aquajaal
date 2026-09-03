import 'package:flutter/material.dart';

/// App Color Palette derived from Yashodhar Enterprises & Aquajal Brand Assets
class AppColors {
  AppColors._();

  // Primary: Royal / Cobalt Blue (from outer circular badge)
  static const Color primary = Color(0xFF1E4CB8);
  static const Color primaryDark = Color(0xFF0F318A);
  static const Color primaryLight = Color(0xFF3D6FE8);
  static const Color primaryContainer = Color(0xFFEBF1FF);
  static const Color onPrimary = Colors.white;

  // Accent: Crisp Leaf / Lime Green (from bottle cap, logo ring, and swoosh)
  static const Color accent = Color(0xFF98C528);
  static const Color accentDark = Color(0xFF7CA31C);
  static const Color accentLight = Color(0xFFB5DE4C);
  static const Color accentContainer = Color(0xFFF2F9E5);
  static const Color onAccent = Color(0xFF1B2E05);

  // Clear Water Blue Tints
  static const Color waterBlueTint = Color(0xFFE8F3FD);
  static const Color waterBlueLight = Color(0xFFC7E2FA);
  static const Color waterAqua = Color(0xFF00A3E0);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0284C7);

  // Light Surfaces
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color cardLight = Colors.white;
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Dark Surfaces
  static const Color surfaceDark = Color(0xFF0B132B);
  static const Color cardDark = Color(0xFF131E3D);
  static const Color cardDarkElevated = Color(0xFF1B2952);
  static const Color dividerDark = Color(0xFF223468);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E4CB8), Color(0xFF14378A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF98C528), Color(0xFF7CA31C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient waterCardGradient = LinearGradient(
    colors: [Color(0xFFF4F9FF), Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
