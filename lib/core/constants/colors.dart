import 'package:flutter/material.dart';

/// ===========================================================
/// INTELLEKT APP COLORS
/// ===========================================================
///
/// Centralized color palette.
/// Do NOT hardcode colors anywhere else in the project.
/// Always import this file.
///
/// Primary Brand Color:
/// #000351
///
/// ===========================================================

class AppColors {
  AppColors._();

  // ==========================================================
  // Brand Colors
  // ==========================================================

  static const Color primary = Color(0xFF000351);

  static const Color secondary = Color(0xFF0057FF);

  static const Color accent = Color(0xFFFFC107);

  // ==========================================================
  // Background Colors
  // ==========================================================

  static const Color background = Color(0xFFF7F9FC);

  static const Color surface = Colors.white;

  static const Color scaffold = Colors.white;

  // ==========================================================
  // Text Colors
  // ==========================================================

  static const Color textPrimary = Color(0xFF1A1A1A);

  static const Color textSecondary = Color(0xFF666666);

  static const Color textHint = Color(0xFF9E9E9E);

  static const Color textWhite = Colors.white;

  // ==========================================================
  // Status Colors
  // ==========================================================

  static const Color success = Color(0xFF2E7D32);

  static const Color warning = Color(0xFFFF9800);

  static const Color error = Color(0xFFD32F2F);

  static const Color info = Color(0xFF0288D1);

  // ==========================================================
  // Border Colors
  // ==========================================================

  static const Color border = Color(0xFFE0E0E0);

  static const Color divider = Color(0xFFEEEEEE);

  // ==========================================================
  // Disabled
  // ==========================================================

  static const Color disabled = Color(0xFFBDBDBD);

  // ==========================================================
  // Shadow
  // ==========================================================

  static const Color shadow = Color(0x14000000);

  // ==========================================================
  // Attendance
  // ==========================================================

  static const Color present = Color(0xFF4CAF50);

  static const Color absent = Color(0xFFE53935);

  static const Color late = Color(0xFFFFA726);

  // ==========================================================
  // Marks
  // ==========================================================

  static const Color excellent = Color(0xFF2E7D32);

  static const Color average = Color(0xFFFFB300);

  static const Color poor = Color(0xFFC62828);
}