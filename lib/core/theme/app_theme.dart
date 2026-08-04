import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/app_sizes.dart';
import 'text_theme.dart';

/// ===========================================================
/// INTELLEKT APPLICATION THEME
/// ===========================================================
///
/// Centralized Material 3 Theme.
///
/// All UI should inherit from this theme.
/// Never style widgets individually unless necessary.
///
/// ===========================================================

class AppTheme {
  AppTheme._();

  // ==========================================================
  // LIGHT THEME
  // ==========================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.light,

      primaryColor: AppColors.primary,

      scaffoldBackgroundColor: AppColors.background,

      fontFamily: 'Roboto',

      textTheme: AppTextTheme.lightTextTheme,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      // ======================================================
      // AppBar
      // ======================================================

      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        toolbarHeight: AppSizes.appBarHeight,
      ),

      // ======================================================
      // Cards
      // ======================================================

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: AppSizes.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(AppSizes.cardRadius),
        ),
      ),

      // ======================================================
      // Elevated Button
      // ======================================================

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(
            double.infinity,
            AppSizes.buttonHeight,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppSizes.buttonRadius,
            ),
          ),
        ),
      ),

      // ======================================================
      // Outlined Button
      // ======================================================

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(
            double.infinity,
            AppSizes.buttonHeight,
          ),
          side: const BorderSide(
            color: AppColors.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppSizes.buttonRadius,
            ),
          ),
        ),
      ),

      // ======================================================
      // Text Button
      // ======================================================

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),

      // ======================================================
      // Input Decoration
      // ======================================================

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),
      ),

      // ======================================================
      // Divider
      // ======================================================

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: AppSizes.dividerThickness,
      ),

      // ======================================================
      // Floating Action Button
      // ======================================================

      floatingActionButtonTheme:
      const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),

      // ======================================================
      // Progress Indicator
      // ======================================================

      progressIndicatorTheme:
      const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      // ======================================================
      // SnackBar
      // ======================================================

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: AppTextTheme.lightTextTheme.bodyMedium!
            .copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(AppSizes.radiusMD),
        ),
      ),

      // ======================================================
      // Checkbox
      // ======================================================

      checkboxTheme: CheckboxThemeData(
        fillColor:
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.white;
        }),
      ),

      // ======================================================
      // Radio
      // ======================================================

      radioTheme: RadioThemeData(
        fillColor:
        WidgetStateProperty.resolveWith((states) {
          return AppColors.primary;
        }),
      ),

      // ======================================================
      // Switch
      // ======================================================

      switchTheme: SwitchThemeData(
        thumbColor:
        WidgetStateProperty.resolveWith((states) {
          return Colors.white;
        }),
        trackColor:
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.grey;
        }),
      ),
    );
  }

  // ==========================================================
  // DARK THEME
  // ==========================================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.dark,

      primaryColor: AppColors.primary,

      scaffoldBackgroundColor: const Color(0xFF121212),

      fontFamily: 'Roboto',

      textTheme: AppTextTheme.darkTextTheme,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
      ),
    );
  }
}