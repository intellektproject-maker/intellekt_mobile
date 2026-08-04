import '../../data/mock/mock_faculty_attendance_data.dart';
import '../../models/attendance_student_model.dart';

class MockAttendanceRepository {
  Future<List<AttendanceStudentModel>> loadStudents({
    required String className,
    required String subject,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    return mockFacultyAttendanceData
        .map(
          (student) => AttendanceStudentModel.fromJson(student),
    )
        .toList();
  }

  Future<bool> submitAttendance({
    required List<AttendanceStudentModel> students,
  }) async {
    await Future.delayed(
      const Duration(seconds: 1),
    );

    return true;
  }
}