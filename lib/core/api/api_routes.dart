/// ===========================================================
/// INTELLEKT API ROUTES
/// ===========================================================
///
/// Centralized API endpoint definitions.
///
/// IMPORTANT:
/// Never hardcode endpoints anywhere else in the application.
///
/// Example:
///
/// Dio().get(ApiRoutes.studentDetails(rollNo));
///
/// ===========================================================

class ApiRoutes {
  ApiRoutes._();

  // ==========================================================
  // BASE URL
  // ==========================================================
  //
  // Development
  // Replace with your local backend during development
  //
  // Example:
  // http://192.168.1.100:5000/api
  //
  // Production:
  // Replace with Railway Backend URL
  //
  // Example:
  // https://intellekt-backend.up.railway.app/api
  //
  // NOTE:
  // This will later be moved to environment.dart
  // ==========================================================

  static const String baseUrl =
      "https://YOUR_BACKEND_URL/api";

  // ==========================================================
  // AUTHENTICATION
  // ==========================================================

  static const String login = "/login";

  static const String logout = "/logout";

  static const String refreshToken = "/refresh-token";

  static const String changePassword = "/change-password";

  static const String forgotPassword = "/forgot-password";

  static const String resetPassword = changePassword;
  // ==========================================================
  // STUDENT
  // ==========================================================

  static String studentDetails(String rollNo) =>
      "/student/$rollNo";

  static String studentAttendance(String rollNo) =>
      "/attendance/$rollNo";

  static String studentMarks(String rollNo) =>
      "/marks/$rollNo";

  static String studentFees(String rollNo) =>
      "/fees/$rollNo";

  static String studentTests(String rollNo) =>
      "/test-schedule/$rollNo";

  static String requestPdf(String rollNo) =>
      "/request-pdf/$rollNo";

  // ==========================================================
  // FACULTY
  // ==========================================================

  static const String facultyDashboard =
      "/faculty/dashboard";

  static const String postAttendance =
      "/attendance";

  static const String enterMarks =
      "/marks";

  static const String postTest =
      "/tests";

  static const String registeredStudents =
      "/registered-students";

  static const String facultyProfile =
      "/faculty/profile";

  // ==========================================================
  // ADMIN
  // ==========================================================

  static const String adminDashboard =
      "/admin/dashboard";

  static const String students =
      "/students";

  static const String faculties =
      "/faculty";

  static const String enquiries =
      "/enquiries";

  static const String reports =
      "/reports";

  static const String analytics =
      "/analytics";

  // ==========================================================
  // PROFILE
  // ==========================================================

  static const String profile =
      "/profile";

  static const String updateProfile =
      "/profile/update";

  // ==========================================================
  // NOTIFICATIONS
  // ==========================================================

  static const String notifications =
      "/notifications";

  static const String markNotificationRead =
      "/notifications/read";

  // ==========================================================
  // COMMON
  // ==========================================================

  static const String uploadImage =
      "/upload";

  static const String downloadPdf =
      "/download";

  static const String appVersion =
      "/version";

  static const String health =
      "/health";

  // ==========================================================
  // SEARCH
  // ==========================================================

  static const String searchStudents =
      "/students/search";

  static const String searchFaculty =
      "/faculty/search";

  // ==========================================================
  // SETTINGS
  // ==========================================================

  static const String settings =
      "/settings";
}