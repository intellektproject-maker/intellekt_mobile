import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/app_sizes.dart';

/// ===========================================================
/// INTELLEKT TEXT THEME
/// ===========================================================
///
/// Centralized typography for the application.
///
/// Roboto is bundled locally in pubspec.yaml, so the app does
/// not depend on runtime Google Fonts network fetching.
///
/// Never create TextStyles directly inside screens.
/// Always use Theme.of(context).textTheme
///
/// ===========================================================

class AppTextTheme {
  AppTextTheme._();

  static const String _fontFamily = 'Roboto';

  static TextStyle _style({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextTheme get lightTextTheme => TextTheme(
        // Display
        displayLarge: _style(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        displayMedium: _style(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        displaySmall: _style(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),

        // Headlines
        headlineLarge: _style(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: _style(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineSmall: _style(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        // Titles
        titleLarge: _style(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: _style(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleSmall: _style(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        // Body
        bodyLarge: _style(
          fontSize: AppSizes.fontLG,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: _style(
          fontSize: AppSizes.fontMD,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodySmall: _style(
          fontSize: AppSizes.fontSM,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),

        // Labels
        labelLarge: _style(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        labelMedium: _style(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        labelSmall: _style(
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
