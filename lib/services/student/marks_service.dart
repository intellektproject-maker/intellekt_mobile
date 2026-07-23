import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_routes.dart';

class MarksService {
  MarksService._();

  static final Dio _dio = ApiClient().dio;

  static Future<List<Map<String, dynamic>>> getMarks(
      String rollNo,
      ) async {
    try {
      final response = await _dio.get(
        ApiRoutes.studentMarks(rollNo),
      );

      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["error"] ?? "Unable to load marks.",
      );
    }
  }
}