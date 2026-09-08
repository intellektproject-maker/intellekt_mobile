/// ===========================================================
/// INTELLEKT API ROUTES
/// ===========================================================
///
/// Centralized API endpoint definitions.
///
/// ===========================================================

class ApiRoutes {
  ApiRoutes._();

  // ==========================================================
  // AUTHENTICATION
  // ==========================================================

  // The backend /login endpoint is the canonical authentication
  // endpoint and already supports both students and faculty.
  static const String login = "/login";

  static const String deviceToken = "/mobile/device-token";

  static const String logout = "/logout";
  static const String refreshToken = "/refresh-token";

  // The general reset-password endpoint supports both roles.
  static const String resetPassword = "/reset-password";

  static const String forgotPassword = "/forgot-password";

  // ==========================================================
  // STUDENT
  // ==========================================================

  static String studentDetails(String rollNo) => "/student/$rollNo";
  static String studentAttendance(String rollNo) => "/attendance/$rollNo";
  static String studentMarks(String rollNo) => "/marks/$rollNo";
  static String studentFees(String rollNo) => "/fees/$rollNo";
  static String studentTests(String rollNo) => "/test-schedule/$rollNo";
  static String studentTestSlots(String testCode, String rollNo) =>
      "/test-slots/$testCode/$rollNo";

  static const String registerTest = "/register-test-slot";
  static String requestPdf(String rollNo) => "/request-pdf/$rollNo";

  // ==========================================================
  // FACULTY
  // ==========================================================

  static const String facultyDashboard = "/faculty/dashboard";
  static const String postAttendance = "/attendance";
  static const String enterMarks = "/marks";
  static const String postTest = "/tests";
  static const String registeredStudents = "/registered-students";
  static const String facultyProfile = "/faculty/profile";

  static String facultyDetails(String facultyId) => "/faculty/$facultyId";

  // ==========================================================
  // ADMIN
  // ==========================================================

  static const String adminDashboard = "/admin/dashboard";
  static const String students = "/students";
  static const String faculties = "/faculty";
  static const String enquiries = "/enquiries";
  static const String reports = "/reports";
  static const String analytics = "/analytics";

  // ==========================================================
  // PROFILE
  // ==========================================================

  static const String profile = "/profile";
  static const String updateProfile = "/profile/update";

  // ==========================================================
  // NOTIFICATIONS
  // ==========================================================

  static const String notifications = "/notifications";
  static const String markNotificationRead = "/notifications/read";

  // ==========================================================
  // COMMON
  // ==========================================================

  static const String uploadImage = "/upload";
  static const String downloadPdf = "/download";
  static const String appVersion = "/version";
  static const String health = "/health";

  // ==========================================================
  // SEARCH
  // ==========================================================

  static const String searchStudents = "/students/search";
  static const String searchFaculty = "/faculty/search";

  // ==========================================================
  // SETTINGS
  // ==========================================================

  static const String settings = "/settings";
}
