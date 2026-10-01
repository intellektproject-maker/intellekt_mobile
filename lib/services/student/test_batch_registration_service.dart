import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';

class TestBatchRegistrationService {
  static final Dio _dio = ApiClient().dio;

  static Future<List<Map<String, dynamic>>> getTests(String rollNo) async {
    try {
      final response = await _dio.get(
        '/test-batch/student-tests/${Uri.encodeComponent(rollNo.trim().toUpperCase())}',
      );

      final data = response.data;
      if (data is! Map) {
        throw Exception('Invalid Test Batch test schedule response.');
      }

      final rawTests = data['tests'];
      if (rawTests is! List) return [];

      return rawTests
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on DioException catch (e) {
      throw Exception(_message(e, 'Unable to load available Test Batch tests.'));
    }
  }

  static Future<Map<String, dynamic>> register({
    required String rollNo,
    required String testCode,
    required String writingDate,
    required String slotStart,
    required String slotEnd,
  }) async {
    try {
      final response = await _dio.post(
        '/test-batch/tests/${Uri.encodeComponent(testCode.trim().toUpperCase())}/register',
        data: {
          'roll_no': rollNo.trim().toUpperCase(),
          'writing_date': writingDate,
          'slot_start': slotStart,
          'slot_end': slotEnd,
        },
      );

      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }

      throw Exception('Invalid registration response.');
    } on DioException catch (e) {
      throw Exception(_message(e, 'Unable to register for this test.'));
    }
  }

  static String _message(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return fallback;
  }
}
