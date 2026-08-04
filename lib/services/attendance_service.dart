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

      final data = response.data;

      if (data is! List) {
        throw Exception('Invalid attendance response');
      }

      return data
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList();
    } on DioException catch (error) {
      final data = error.response?.data;

      final message = data is Map
          ? data['error']?.toString()
          : null;

      throw Exception(
        message ?? 'Unable to load attendance.',
      );
    }
  }
}