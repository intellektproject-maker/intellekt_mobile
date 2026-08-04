import 'package:flutter/material.dart';

/// ===========================================================
/// INTELLEKT APP SIZES
/// ===========================================================
///
/// Centralized dimensions used across the application.
///
/// Never hardcode:
/// - Padding
/// - Margin
/// - Border Radius
/// - Font Size
/// - Icon Size
/// - Button Height
///
/// ===========================================================

class AppSizes {
  AppSizes._();

  // ==========================================================
  // Padding & Margin
  // ==========================================================

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  // ==========================================================
// Compatibility Aliases
// ==========================================================

  static const double paddingXS = xs;
  static const double paddingSmall = sm;
  static const double paddingMedium = md;
  static const double paddingLarge = lg;
  static const double paddingXLarge = xl;

  static const double marginSmall = sm;
  static const double marginMedium = md;
  static const double marginLarge = lg;

  // ==========================================================
  // Border Radius
  // ==========================================================

  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusCircular = 100.0;

  // ==========================================================
  // Icon Sizes
  // ==========================================================

  static const double iconXS = 14.0;
  static const double iconSM = 18.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 40.0;

  // ==========================================================
  // Font Sizes
  // ==========================================================

  static const double fontXS = 10.0;
  static const double fontSM = 12.0;
  static const double fontMD = 14.0;
  static const double fontLG = 16.0;
  static const double fontXL = 18.0;
  static const double fontXXL = 22.0;
  static const double fontHeading = 28.0;

  // ==========================================================
  // Button Sizes
  // ==========================================================

  static const double buttonHeight = 52.0;
  static const double buttonRadius = 12.0;

  // ==========================================================
  // TextField Sizes
  // ==========================================================

  static const double inputHeight = 56.0;
  static const double inputRadius = 12.0;

  // ==========================================================
  // Avatar Sizes
  // ==========================================================

  static const double avatarSM = 40.0;
  static const double avatarMD = 60.0;
  static const double avatarLG = 90.0;
  static const double avatarXL = 120.0;

  // ==========================================================
  // Card
  // ==========================================================

  static const double cardRadius = 16.0;
  static const double cardElevation = 2.0;

  // ==========================================================
  // AppBar
  // ==========================================================

  static const double appBarHeight = kToolbarHeight;

  // ==========================================================
  // Bottom Navigation
  // ==========================================================

  static const double bottomNavHeight = 70.0;

  // ==========================================================
  // Divider
  // ==========================================================

  static const double dividerThickness = 1.0;

  // ==========================================================
  // Progress Indicators
  // ==========================================================

  static const double progressHeight = 8.0;

  // ==========================================================
  // Image Sizes
  // ==========================================================

  static const double imageThumbnail = 80.0;
  static const double imageMedium = 150.0;
  static const double imageLarge = 250.0;

  // ==========================================================
  // Dashboard
  // ==========================================================

  static const double dashboardCardHeight = 120.0;
  static const double dashboardIconSize = 34.0;

  // ==========================================================
  // Animation
  // ==========================================================

  static const Duration animationDuration =
  Duration(milliseconds: 300);

  static const Duration splashDuration =
  Duration(seconds: 2);
}

/// ===========================================================
/// Common SizedBoxes
/// ===========================================================

class AppSpacing {
  AppSpacing._();

  static const Widget h4 = SizedBox(height: 4);
  static const Widget h8 = SizedBox(height: 8);
  static const Widget h12 = SizedBox(height: 12);
  static const Widget h16 = SizedBox(height: 16);
  static const Widget h20 = SizedBox(height: 20);
  static const Widget h24 = SizedBox(height: 24);
  static const Widget h32 = SizedBox(height: 32);
  static const Widget h40 = SizedBox(height: 40);

  static const Widget w4 = SizedBox(width: 4);
  static const Widget w8 = SizedBox(width: 8);
  static const Widget w12 = SizedBox(width: 12);
  static const Widget w16 = SizedBox(width: 16);
  static const Widget w20 = SizedBox(width: 20);
  static const Widget w24 = SizedBox(width: 24);
}

/// ===========================================================
/// Common EdgeInsets
/// ===========================================================

class AppPadding {
  AppPadding._();

  static const EdgeInsets xs = EdgeInsets.all(4);

  static const EdgeInsets sm = EdgeInsets.all(8);

  static const EdgeInsets md = EdgeInsets.all(16);

  static const EdgeInsets lg = EdgeInsets.all(24);

  static const EdgeInsets xl = EdgeInsets.all(32);

  static const EdgeInsets horizontal =
  EdgeInsets.symmetric(horizontal: 16);

  static const EdgeInsets vertical =
  EdgeInsets.symmetric(vertical: 16);

  static const EdgeInsets screen =
  EdgeInsets.symmetric(horizontal: 20, vertical: 16);
}