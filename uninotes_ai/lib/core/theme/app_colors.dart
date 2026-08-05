import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Brand Colors ─────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF4F46E5);       // Deep Indigo
  static const Color accent = Color(0xFF7C3AED);         // Violet
  static const Color primaryLight = Color(0xFF818CF8);   // Soft indigo
  static const Color accentLight = Color(0xFFA78BFA);    // Soft violet

  // ─── Gradient ─────────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient subtleGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Dark Mode ────────────────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F0F1A);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color cardDark = Color(0xFF1E1E35);
  static const Color navBarDark = Color(0xFF141428);
  static const Color borderDark = Color(0xFF2A2A45);
  static const Color inputFillDark = Color(0xFF1A1A2E);
  static const Color textPrimaryDark = Color(0xFFF1F1F8);
  static const Color textSecondaryDark = Color(0xFF8B8BAD);

  // ─── Light Mode ───────────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8F8FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E2F0);
  static const Color inputFillLight = Color(0xFFF4F4FE);
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // ─── Status Colors ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ─── Note Status Colors ───────────────────────────────────────────────────────
  static const Color statusApproved = Color(0xFF10B981);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusFlagged = Color(0xFFEF4444);

  // ─── Overlays ─────────────────────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFF1E1E35);
  static const Color shimmerHighlight = Color(0xFF2A2A4A);
}
