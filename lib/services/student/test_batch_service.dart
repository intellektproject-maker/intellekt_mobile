import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';

class TestBatchService {
  static final Dio _dio = ApiClient().dio;

  static Future<Map<String, dynamic>> getStudent(String rollNo) async {
    try {
      final response = await _dio.get(
        '/test-batch/student/${Uri.encodeComponent(rollNo.trim().toUpperCase())}',
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map<String, dynamic>
          ? data['error']?.toString()
          : null;
      throw Exception(message ?? 'Unable to load Test Batch student.');
    }
  }

  static Future<List<Map<String, dynamic>>> getMarks(String rollNo) async {
    try {
      final response = await _dio.get(
        '/test-batch/marks/${Uri.encodeComponent(rollNo.trim().toUpperCase())}',
      );
      return List<Map<String, dynamic>>.from(
        (response.data as List).map((item) => Map<String, dynamic>.from(item)),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map<String, dynamic>
          ? data['error']?.toString()
          : null;
      throw Exception(message ?? 'Unable to load Test Batch marks.');
    }
  }

  static Future<Map<String, dynamic>> getAttendance(String rollNo) async {
    try {
      final response = await _dio.get(
        '/test-batch/attendance/${Uri.encodeComponent(rollNo.trim().toUpperCase())}',
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map<String, dynamic>
          ? data['error']?.toString()
          : null;
      throw Exception(message ?? 'Unable to load Test Batch attendance.');
    }
  }
}
