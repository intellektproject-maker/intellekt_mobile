class AppRoutes {
  AppRoutes._();

  // Authentication
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const changePassword = '/change-password';

  // Student
  static const studentDashboard = '/student/dashboard';

  // Faculty
  static const facultyDashboard = '/faculty/dashboard';
  static const facultyProfile = '/faculty/profile';
  static const facultyAttendance = '/faculty/attendance';
  static const facultyTest = '/faculty/test';
  static const facultyManageStudents = '/faculty/manage/students';
  static const facultyManageFaculty = '/faculty/manage/faculty';
  static const facultyStudentRecord = '/faculty/student-record';
  static const facultyEnquiries = '/faculty/enquiries';
  static const facultyRequests = '/faculty/requests';

  // Admin
  static const adminDashboard = '/admin/dashboard';
}