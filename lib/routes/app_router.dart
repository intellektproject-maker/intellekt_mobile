import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/change_password.dart';
import '../screens/auth/login_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/splash/splash_screen.dart';

// ==============================
// STUDENT
// ==============================
import '../screens/student/dashboard/student_dashboard.dart';
import '../screens/student/attendance/attendance_screen.dart'
as student_attendance;
import '../screens/student/marks/marks_screen.dart';
import '../screens/student/test_schedule/test_schedule_screen.dart';
import '../screens/student/fees/fee_screen.dart';
import '../screens/student/useful_links/useful_links_screen.dart';
import '../screens/student/request_pdf/request_pdf_screen.dart';

// ==============================
// FACULTY
// ==============================
import '../screens/faculty/dashboard/faculty_dashboard.dart';
import '../screens/faculty/profile/faculty_profile_screen.dart';

// Keep the alias here
import '../screens/faculty/attendance/attendance_screen.dart'
as faculty_attendance;

import '../screens/faculty/attendance/enter_attendance_screen.dart';
import '../screens/faculty/attendance/manage_attendance_screen.dart';

// Import Test Management normally
import '../screens/faculty/test_management/test_management_screen.dart';
import '../screens/faculty/test_management/enter_marks_screen.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,

    initialLocation: AppRoutes.splash,

    routes: [
      // SPLASH
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      // WELCOME
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),

      // LOGIN
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.facultyTest,
        builder: (context, state) => const TestManagementScreen(),
      ),
      // CHANGE PASSWORD
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // ==============================
      // STUDENT
      // ==============================
      GoRoute(
        path: AppRoutes.studentDashboard,
        builder: (context, state) => const StudentDashboard(),
      ),

      GoRoute(
        path: AppRoutes.studentAttendance,
        builder: (context, state) =>
            const student_attendance.AttendanceScreen(),
      ),

      GoRoute(
        path: AppRoutes.studentMarks,
        builder: (context, state) {
          final roll = state.uri.queryParameters['roll'] ?? 'IA001';

          return MarksScreen(rollNo: roll);
        },
      ),
      GoRoute(
        path: AppRoutes.studentTestSchedule,
        builder: (context, state) {
          final roll = state.uri.queryParameters['roll'] ?? 'IA001';

          return TestScheduleScreen(rollNo: roll);
        },
      ),
      GoRoute(
        path: AppRoutes.studentFee,
        builder: (context, state) {
          final roll = state.uri.queryParameters['roll'] ?? 'IA001';

          return FeeScreen(rollNo: roll);
        },
      ),
      GoRoute(
        path: AppRoutes.studentUsefulLinks,
        builder: (context, state) => const UsefulLinksScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentRequestPdf,
        builder: (context, state) {
          final roll = state.uri.queryParameters['roll'] ?? 'IA001';

          return RequestPdfScreen(rollNo: roll);
        },
      ),
      // ==============================
      // FACULTY
      // ==============================
      GoRoute(
        path: AppRoutes.facultyDashboard,
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';

          return FacultyDashboard(
            facultyId: id,
          );
        },
      ),

      // FACULTY PROFILE
      GoRoute(
        path: AppRoutes.facultyProfile,
        builder: (context, state) {
          final facultyId = state.uri.queryParameters['id'] ?? '';

          final loginId = state.uri.queryParameters['loginId'] ?? facultyId;

          return FacultyProfileScreen(
            facultyId: facultyId,
            loginFacultyId: loginId,
          );
        },
      ),
      GoRoute(
        path: '/faculty/enter-marks',
        builder: (context, state) => const EnterMarksScreen(),
      ),
      // FACULTY ATTENDANCE
      GoRoute(
        path: AppRoutes.facultyAttendance,
        builder: (context, state) {
          final facultyId = state.uri.queryParameters['id'] ?? '';

          return faculty_attendance.AttendanceScreen(facultyId: facultyId);
        },
      ),

      // ENTER ATTENDANCE
      GoRoute(
        path: AppRoutes.facultyEnterAttendance,
        builder: (context, state) {
          final facultyId = state.uri.queryParameters['id'] ?? '';

          return EnterAttendanceScreen(facultyId: facultyId);
        },
      ),

      // MANAGE ATTENDANCE
      GoRoute(
        path: AppRoutes.facultyManageAttendance,
        builder: (context, state) {
          final facultyId = state.uri.queryParameters['id'] ?? '';

          return ManageAttendanceScreen(facultyId: facultyId);
        },
      ),

      // ==============================
      // ADMIN
      // ==============================
    
    ],

    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Text('404\n${state.uri}', textAlign: TextAlign.center),
        ),
      );
    },
  );
}
