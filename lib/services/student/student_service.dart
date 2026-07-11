import '../../data/mock/mock_student_data.dart';

class StudentService {
  StudentService._();

  static Future<Map<String, dynamic>> getStudent(
      String rollNo,
      ) async {
    // Simulates API loading time.
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    return Map<String, dynamic>.from(mockStudentData);
  }
}