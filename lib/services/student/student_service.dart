import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_routes.dart';
import '../../models/student_details_model.dart';
import '../../repositories/mock_student_repository.dart';

class StudentService {
  static final Dio _dio = ApiClient().dio;

  final MockStudentRepository _repository = MockStudentRepository();

  // ===========================
  // Faculty - Manage Students
  // ===========================

  Future<List<StudentDetailsModel>> getStudents() async {
    return _repository.getStudents();
  }

  Future<StudentDetailsModel?> getStudentById(String id) async {
    return _repository.getStudentById(id);
  }

  Future<void> addStudent(StudentDetailsModel student) async {
    await _repository.addStudent(student);
  }

  Future<void> updateStudent(StudentDetailsModel student) async {
    await _repository.updateStudent(student);
  }

  Future<void> deleteStudent(String id) async {
    await _repository.deleteStudent(id);
  }

  // ===========================
  // Student Module (Backend)
  // ===========================

  static Future<Map<String, dynamic>> getStudent(
      String rollNo,
      ) async {
    try {
      final response = await _dio.get(
        ApiRoutes.studentDetails(rollNo),
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["error"] ??
            "Unable to load student.",
      );
    }
  }
}