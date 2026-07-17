import '../../data/mock/mock_student_data.dart';

class StudentService {
  StudentService._();

  static Future<Map<String, dynamic>> getStudent(
      String rollNo,
      ) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    final student = MockStudentData.students.firstWhere(
          (s) => s.rollNo == rollNo,
      orElse: () => throw Exception("Student not found"),
    );

    return student.toJson();
  }
}