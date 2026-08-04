import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

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

import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      debugLogDiagnostics: true,
      initialLocation: AppRoutes.splash,
      refreshListenable: authProvider,

      // ==========================================================
      // SESSION REDIRECTION
      // ==========================================================
      redirect: (context, state) {
        final location = state.matchedLocation;

        // Wait until the saved session has been checked.
        if (!authProvider.isInitialized) {
          if (location != AppRoutes.splash) {
            return AppRoutes.splash;
          }

          return null;
        }

        final isLoggedIn = authProvider.isLoggedIn;

        final isAuthenticationPage =
            location == AppRoutes.splash ||
                location == AppRoutes.welcome ||
                location == AppRoutes.login;

        final isStudentPage =
            location == AppRoutes.studentDashboard ||
                location == AppRoutes.studentAttendance ||
                location == AppRoutes.studentMarks ||
                location == AppRoutes.studentTestSchedule ||
                location == AppRoutes.studentFee ||
                location == AppRoutes.studentUsefulLinks ||
                location == AppRoutes.studentRequestPdf;

        // A saved student session exists.
        if (isLoggedIn && isAuthenticationPage) {
          if (authProvider.user!.mustResetPassword) {
            return AppRoutes.changePassword;
          }

          return AppRoutes.studentDashboard;
        }

        // A logged-out user cannot open protected pages.
        if (!isLoggedIn &&
            (isStudentPage || location == AppRoutes.changePassword)) {
          return AppRoutes.login;
        }

        return null;
      },

      routes: [
        // ==============================
        // SPLASH
        // ==============================
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),

        // ==============================
        // WELCOME
        // ==============================
        GoRoute(
          path: AppRoutes.welcome,
          builder: (context, state) => const WelcomeScreen(),
        ),

        // ==============================
        // LOGIN
        // ==============================
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),

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
            final roll =
                state.uri.queryParameters['roll'] ??
                    authProvider.user?.id ??
                    'IA001';

            return MarksScreen(rollNo: roll);
          },
        ),

        GoRoute(
          path: AppRoutes.studentTestSchedule,
          builder: (context, state) {
            final roll =
                state.uri.queryParameters['roll'] ??
                    authProvider.user?.id ??
                    'IA001';

            return TestScheduleScreen(rollNo: roll);
          },
        ),

        GoRoute(
          path: AppRoutes.studentFee,
          builder: (context, state) {
            final roll =
                state.uri.queryParameters['roll'] ??
                    authProvider.user?.id ??
                    'IA001';

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
            final roll =
                state.uri.queryParameters['roll'] ??
                    authProvider.user?.id ??
                    'IA001';

            return RequestPdfScreen(rollNo: roll);
          },
        ),
      ],

      errorBuilder: (context, state) {
        return Scaffold(
          body: Center(
            child: Text(
              '404\n${state.uri}',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}