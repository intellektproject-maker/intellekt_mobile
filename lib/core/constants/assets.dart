/// ===========================================================
/// INTELLEKT APP ASSETS
/// ===========================================================
///
/// Centralized asset paths.
///
/// Never hardcode asset paths anywhere in the application.
///
/// Example:
///
/// Image.asset(AppAssets.logo)
/// SvgPicture.asset(AppAssets.userIcon)
/// Lottie.asset(AppAssets.loadingAnimation)
///
/// ===========================================================

class AppAssets {
  AppAssets._();

  // ==========================================================
  // Base Paths
  // ==========================================================

  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';
  static const String _logo = 'assets/logo';
  static const String _animations = 'assets/animations';
  static const String _json = 'assets/json';

  // ==========================================================
  // Logos
  // ==========================================================

  static const String logo = '$_logo/logo.png';

  static const String logoWhite = '$_logo/logo_white.png';

  static const String logoTransparent =
      '$_logo/logo_transparent.png';

  // ==========================================================
  // Splash
  // ==========================================================

  static const String splashBackground =
      '$_images/splash_background.png';

  static const String splashIllustration =
      '$_images/splash.png';

  // ==========================================================
  // Authentication
  // ==========================================================

  static const String loginBanner =
      '$_images/login_banner.png';

  static const String forgotPassword =
      '$_images/forgot_password.png';

  // ==========================================================
  // Student Images
  // ==========================================================

  static const String studentPlaceholder =
      '$_images/student_placeholder.png';

  static const String attendanceBanner =
      '$_images/attendance.png';

  static const String marksBanner =
      '$_images/marks.png';

  static const String feesBanner =
      '$_images/fees.png';

  static const String profileBanner =
      '$_images/profile.png';

  // ==========================================================
  // Faculty Images
  // ==========================================================

  static const String facultyPlaceholder =
      '$_images/faculty_placeholder.png';

  static const String postTestBanner =
      '$_images/post_test.png';

  // ==========================================================
  // Admin Images
  // ==========================================================

  static const String adminDashboard =
      '$_images/admin_dashboard.png';

  // ==========================================================
  // Common Icons (PNG)
  // ==========================================================

  static const String homeIcon =
      '$_icons/home.png';

  static const String dashboardIcon =
      '$_icons/dashboard.png';

  static const String profileIcon =
      '$_icons/profile.png';

  static const String settingsIcon =
      '$_icons/settings.png';

  static const String notificationIcon =
      '$_icons/notification.png';

  static const String attendanceIcon =
      '$_icons/attendance.png';

  static const String marksIcon =
      '$_icons/marks.png';

  static const String feesIcon =
      '$_icons/fees.png';

  static const String analyticsIcon =
      '$_icons/analytics.png';

  static const String reportIcon =
      '$_icons/report.png';

  static const String logoutIcon =
      '$_icons/logout.png';

  // ==========================================================
  // SVG Icons
  // ==========================================================

  static const String userSvg =
      '$_icons/user.svg';

  static const String passwordSvg =
      '$_icons/password.svg';

  static const String emailSvg =
      '$_icons/email.svg';

  static const String phoneSvg =
      '$_icons/phone.svg';

  static const String searchSvg =
      '$_icons/search.svg';

  static const String filterSvg =
      '$_icons/filter.svg';

  // ==========================================================
  // Lottie Animations
  // ==========================================================

  static const String loadingAnimation =
      '$_animations/loading.json';

  static const String successAnimation =
      '$_animations/success.json';

  static const String errorAnimation =
      '$_animations/error.json';

  static const String emptyAnimation =
      '$_animations/empty.json';

  static const String noInternetAnimation =
      '$_animations/no_internet.json';

  // ==========================================================
  // JSON Files
  // ==========================================================

  static const String onboarding =
      '$_json/onboarding.json';

  static const String countries =
      '$_json/countries.json';

  // ==========================================================
  // Default Profile
  // ==========================================================

  static const String defaultAvatar =
      '$_images/default_avatar.png';
}