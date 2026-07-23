import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_routes.dart';

class StudentService {
  StudentService._();

  static final Dio _dio = ApiClient().dio;

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