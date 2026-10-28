import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/change_password.dart';
import '../screens/auth/login_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/faculty/faculty_profile_shell.dart';
import '../screens/faculty/faculty_notifications_screen.dart';
import '../screens/faculty/test_batch_admin_tests_screen.dart';
import '../screens/faculty/test_batch_admin_actions_screen.dart';
import '../screens/faculty/registered_students_screen.dart';
import '../screens/faculty/faculty_post_test_screen.dart';
import '../screens/faculty/faculty_manage_marks_screen.dart';
import '../screens/faculty/faculty_enter_marks_screen.dart';
import '../screens/faculty/faculty_enter_attendance_screen.dart';
import '../screens/faculty/faculty_manage_attendance_screen.dart';
import '../screens/faculty/faculty_enquiries_requests_screen.dart';
import '../screens/faculty/faculty_student_records_screen.dart';
import '../screens/admin/admin_menu_screen.dart';
import '../screens/admin/admin_enquiries_screen.dart';
import '../screens/admin/admin_add_student_screen.dart';

import '../screens/student/dashboard/student_dashboard.dart';
import '../screens/student/attendance/attendance_screen.dart'
    as student_attendance;
import '../screens/student/marks/marks_screen.dart';
import '../screens/student/test_schedule/test_schedule_screen.dart';
import '../screens/student/fees/fee_screen.dart';
import '../screens/student/useful_links/useful_links_screen.dart';
import '../screens/student/request_pdf/request_pdf_screen.dart';
import '../screens/test_batch/test_batch_dashboard.dart';
import '../screens/test_batch/test_batch_registration.dart';
import '../screens/test_batch/academic_overview_screen.dart';
import '../screens/test_batch/test_batch_marks_screen.dart';
import '../screens/test_batch/test_batch_attendance_screen.dart';

import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      debugLogDiagnostics: true,
      initialLocation: AppRoutes.splash,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final location = state.matchedLocation;

        if (!authProvider.isInitialized) {
          if (location != AppRoutes.splash) return AppRoutes.splash;
          return null;
        }

        final isLoggedIn = authProvider.isLoggedIn;
        final isAuthenticationPage = location == AppRoutes.splash ||
            location == AppRoutes.welcome ||
            location == AppRoutes.login;
        final isAdminPage = location == AppRoutes.adminMenu ||
            location == AppRoutes.adminEnquiries ||
            location == AppRoutes.adminAddStudent;
        final isTestBatchPage = location == AppRoutes.testBatchDashboard ||
            location == AppRoutes.testBatchRegistration ||
            location == AppRoutes.testBatchAcademicOverview ||
            location == AppRoutes.testBatchMarks ||
            location == AppRoutes.testBatchAttendance;
        final isStudentPage = location == AppRoutes.studentDashboard ||
            location == AppRoutes.studentAttendance ||
            location == AppRoutes.studentMarks ||
            location == AppRoutes.studentTestSchedule ||
            location == AppRoutes.studentFee ||
            location == AppRoutes.studentUsefulLinks ||
            location == AppRoutes.studentRequestPdf;
        final isFacultyPage = location == AppRoutes.facultyProfile ||
            location == AppRoutes.facultyNotifications ||
            location == AppRoutes.testBatchAdminTests ||
            location == AppRoutes.testBatchAdminActions ||
            location == AppRoutes.facultyRegisteredStudents ||
            location == AppRoutes.facultyPostTest ||
            location == AppRoutes.facultyManageMarks ||
            location == AppRoutes.facultyEnterMarks ||
            location == AppRoutes.facultyEnterAttendance ||
            location == AppRoutes.facultyManageAttendance ||
            location == AppRoutes.facultyEnquiriesRequests ||
            location == AppRoutes.facultyStudentRecords;

        if (isLoggedIn && isAuthenticationPage) {
          if (authProvider.user!.mustResetPassword) {
            return AppRoutes.changePassword;
          }
          if (authProvider.isFaculty) return AppRoutes.facultyProfile;
          if (authProvider.isTestBatchStudent) return AppRoutes.testBatchDashboard;
          if (authProvider.isStudent) return AppRoutes.studentDashboard;
        }

        if (!isLoggedIn &&
            (isAdminPage || isStudentPage ||
                isTestBatchPage ||
                isFacultyPage ||
                location == AppRoutes.changePassword)) {
          return AppRoutes.login;
        }

        if (isLoggedIn && isAdminPage && !authProvider.user!.isAdmin) {
          return authProvider.isFaculty
              ? AppRoutes.facultyProfile
              : authProvider.isTestBatchStudent
                  ? AppRoutes.testBatchDashboard
                  : AppRoutes.studentDashboard;
        }

        if (isLoggedIn && isTestBatchPage && !authProvider.isTestBatchStudent) {
          return authProvider.isFaculty
              ? AppRoutes.facultyProfile
              : AppRoutes.studentDashboard;
        }

        if (isLoggedIn && isFacultyPage && !authProvider.isFaculty) {
          return authProvider.isStudent
              ? AppRoutes.studentDashboard
              : AppRoutes.login;
        }

        if (isLoggedIn && isStudentPage && !authProvider.isRegularStudent) {
          if (authProvider.isTestBatchStudent) return AppRoutes.testBatchDashboard;
          return authProvider.isFaculty
              ? AppRoutes.facultyProfile
              : AppRoutes.login;
        }

        return null;
      },
      routes: [
        GoRoute(path: AppRoutes.adminMenu, builder: (context, state) => const AdminMenuScreen()),
        GoRoute(path: AppRoutes.adminEnquiries, builder: (context, state) => const AdminEnquiriesScreen()),
        GoRoute(path: AppRoutes.adminAddStudent, builder: (context, state) => AdminAddStudentScreen(args: state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : const {})),
        GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
        GoRoute(path: AppRoutes.welcome, builder: (context, state) => const WelcomeScreen()),
        GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
        GoRoute(path: AppRoutes.changePassword, builder: (context, state) => const ChangePasswordScreen()),
        GoRoute(
          path: AppRoutes.facultyProfile,
          builder: (context, state) => FacultyProfileShell(
            facultyId: authProvider.user?.id.trim().toUpperCase() ?? '',
            authProvider: authProvider,
          ),
        ),
        GoRoute(
          path: AppRoutes.facultyNotifications,
          builder: (context, state) => FacultyNotificationsScreen(
            facultyId: authProvider.user?.id.trim().toUpperCase() ?? '',
          ),
        ),
        GoRoute(
          path: AppRoutes.facultyRegisteredStudents,
          builder: (context, state) => const RegisteredStudentsScreen(),
        ),
        GoRoute(
          path: AppRoutes.facultyStudentRecords,
          builder: (context, state) => const FacultyStudentRecordsScreen(),
        ),
        GoRoute(
          path: AppRoutes.facultyEnquiriesRequests,
          builder: (context, state) => const FacultyEnquiriesRequestsScreen(),
        ),
        GoRoute(
          path: AppRoutes.facultyManageAttendance,
          builder: (context, state) => FacultyManageAttendanceScreen(
            facultyId: authProvider.user?.id.trim().toUpperCase() ?? '',
          ),
        ),
        GoRoute(
          path: AppRoutes.facultyEnterAttendance,
          builder: (context, state) => FacultyEnterAttendanceScreen(
            facultyId: authProvider.user?.id.trim().toUpperCase() ?? '',
          ),
        ),
        GoRoute(
          path: AppRoutes.facultyEnterMarks,
          builder: (context, state) => FacultyEnterMarksScreen(
            facultyId: authProvider.user?.id.trim().toUpperCase() ?? '',
          ),
        ),
        GoRoute(
          path: AppRoutes.facultyManageMarks,
          builder: (context, state) => const FacultyManageMarksScreen(),
        ),
        GoRoute(
          path: AppRoutes.facultyPostTest,
          builder: (context, state) => FacultyPostTestScreen(
            facultyId: authProvider.user?.id.trim().toUpperCase() ?? '',
          ),
        ),
        GoRoute(
          path: AppRoutes.testBatchAdminActions,
          builder: (context, state) => TestBatchAdminActionsScreen(
            adminId: authProvider.user?.id.trim().toUpperCase() ?? '',
          ),
        ),
        GoRoute(
          path: AppRoutes.testBatchAdminTests,
          builder: (context, state) => TestBatchAdminTestsScreen(
            adminId: authProvider.user?.id.trim().toUpperCase() ?? '',
          ),
        ),
        GoRoute(path: AppRoutes.testBatchDashboard, builder: (context, state) => const TestBatchDashboard()),
        GoRoute(
          path: AppRoutes.testBatchRegistration,
          builder: (context, state) => TestBatchRegistrationScreen(
            rollNo: authProvider.user?.id.trim().toUpperCase() ?? '',
          ),
        ),
        GoRoute(
          path: AppRoutes.testBatchAcademicOverview,
          builder: (context, state) => const TestBatchAcademicOverviewScreen(),
        ),
        GoRoute(
          path: AppRoutes.testBatchMarks,
          builder: (context, state) => const TestBatchMarksScreen(),
        ),
        GoRoute(
          path: AppRoutes.testBatchAttendance,
          builder: (context, state) => const TestBatchAttendanceScreen(),
        ),
        GoRoute(path: AppRoutes.studentDashboard, builder: (context, state) => const StudentDashboard()),
        GoRoute(path: AppRoutes.studentAttendance, builder: (context, state) => const student_attendance.AttendanceScreen()),
        GoRoute(
          path: AppRoutes.studentMarks,
          builder: (context, state) => MarksScreen(
            rollNo: state.uri.queryParameters['roll'] ?? authProvider.user?.id ?? 'IA001',
          ),
        ),
        GoRoute(
          path: AppRoutes.studentTestSchedule,
          builder: (context, state) => TestScheduleScreen(
            rollNo: state.uri.queryParameters['roll'] ?? authProvider.user?.id ?? 'IA001',
          ),
        ),
        GoRoute(
          path: AppRoutes.studentFee,
          builder: (context, state) => FeeScreen(
            rollNo: state.uri.queryParameters['roll'] ?? authProvider.user?.id ?? 'IA001',
          ),
        ),
        GoRoute(path: AppRoutes.studentUsefulLinks, builder: (context, state) => const UsefulLinksScreen()),
        GoRoute(
          path: AppRoutes.studentRequestPdf,
          builder: (context, state) => RequestPdfScreen(
            rollNo: state.uri.queryParameters['roll'] ?? authProvider.user?.id ?? 'IA001',
          ),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('404\n' + state.uri.toString(), textAlign: TextAlign.center)),
      ),
    );
  }
}
