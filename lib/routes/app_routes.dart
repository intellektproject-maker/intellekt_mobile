class AppRoutes {
  AppRoutes._();

  // ==============================
  // AUTHENTICATION
  // ==============================
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const changePassword = '/change-password';

  // ==============================
  // STUDENT
  // ==============================
  static const studentDashboard = '/student/dashboard';
  static const studentAttendance = '/student/attendance';
  static const studentMarks = '/student/marks';
  static const studentTestSchedule = '/student/test-schedule';
  static const studentFee = '/student/fee';
  static const studentUsefulLinks = '/student/useful-links';
  static const studentRequestPdf = '/student/request-pdf';

  // ==============================
  // FACULTY
  // ==============================
  static const facultyDashboard = '/faculty/dashboard';
  static const facultyProfile = '/faculty/profile';

  static const facultyAttendance = '/faculty/attendance';
  static const facultyEnterAttendance = '/faculty/attendance/enter';
  static const facultyManageAttendance = '/faculty/attendance/manage';

  static const facultyTest = '/faculty/test';

  // ==============================
  // MANAGEMENT
  // ==============================
  static const facultyManageStudents = '/faculty/manage/students';
  static const facultyManageFaculty = '/faculty/manage/faculty';

  static const facultyStudentRecord = '/faculty/student-record';
  static const facultyEnquiries = '/faculty/enquiries';
  static const facultyRequests = '/faculty/requests';
}