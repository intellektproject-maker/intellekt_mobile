import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_routes.dart';

class AttendanceService {
  AttendanceService._();

  static final Dio _dio = ApiClient().dio;

  static Future<List<Map<String, dynamic>>> getAttendance(
      String rollNo,
      ) async {
    try {
      final response = await _dio.get(
        ApiRoutes.studentAttendance(rollNo),
      );

      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["error"] ??
            "Unable to load attendance.",
      );
    }
  }
}