import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../constants/app_sizes.dart';

/// ===========================================================
/// INTELLEKT TEXT THEME
/// ===========================================================
///
/// Centralized typography for the application.
///
/// Never create TextStyles directly inside screens.
/// Always use Theme.of(context).textTheme
///
/// ===========================================================

class AppTextTheme {
  AppTextTheme._();

  static TextTheme get lightTextTheme => TextTheme(

    // Display
    displayLarge: GoogleFonts.roboto(
      fontSize: 48,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),

    displayMedium: GoogleFonts.roboto(
      fontSize: 40,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),

    displaySmall: GoogleFonts.roboto(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),

    // Headlines
    headlineLarge: GoogleFonts.roboto(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),

    headlineMedium: GoogleFonts.roboto(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),

    headlineSmall: GoogleFonts.roboto(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),

    // Titles
    titleLarge: GoogleFonts.roboto(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),

    titleMedium: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),

    titleSmall: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),

    // Body
    bodyLarge: GoogleFonts.roboto(
      fontSize: AppSizes.fontLG,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),

    bodyMedium: GoogleFonts.roboto(
      fontSize: AppSizes.fontMD,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),

    bodySmall: GoogleFonts.roboto(
      fontSize: AppSizes.fontSM,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),

    // Labels
    labelLarge: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),

    labelMedium: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),

    labelSmall: GoogleFonts.roboto(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.textHint,
    ),
  );

  /// Dark Theme Typography
  static TextTheme get darkTextTheme => lightTextTheme.apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  );
}