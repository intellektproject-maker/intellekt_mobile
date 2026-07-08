import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/change_password.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/student/dashboard/student_dashboard.dart';
import '../screens/faculty/dashboard/faculty_dashboard.dart';
import '../screens/admin/dashboard/admin_dashboard.dart';
import 'app_routes.dart';
import '../screens/faculty/profile/faculty_profile_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '${AppRoutes.facultyProfile}?id=IG001&loginId=IG001',

    routes: [

      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),

      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      GoRoute(
        path: AppRoutes.studentDashboard,
        builder: (context, state) => const StudentDashboard(),
      ),

      GoRoute(
        path: AppRoutes.facultyDashboard,
        builder: (context, state) => const FacultyDashboard(),
      ),
      GoRoute(
        path: AppRoutes.facultyProfile,
        builder: (context, state) {
          final facultyId =
              state.uri.queryParameters['id'] ?? '';

          final loginId =
              state.uri.queryParameters['loginId'] ??
                  facultyId;

          return FacultyProfileScreen(
            facultyId: facultyId,
            loginFacultyId: loginId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboard(),
      ),
    ],

    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Text(
            "404\n${state.uri}",
            textAlign: TextAlign.center,
          ),
        ),
      );
    },
  );
}