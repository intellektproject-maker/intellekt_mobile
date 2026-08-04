import 'package:dio/dio.dart';

import '../../api/api_client.dart';

class AnswerSheetService {
  static final Dio _dio = ApiClient().dio;

  static Future<Map<String, dynamic>> loadData(String rollNo) async {
    try {
      final response = await _dio.get(
        '/student-answer-sheet-data/$rollNo',
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["error"] ??
            "Unable to load answer sheet data.",
      );
    }
  }

  static Future<void> submitRequest({
    required String rollNo,
    required String testCode,
    required String phone,
  }) async {
    try {
      await _dio.post(
        '/answer-sheet-requests',
        data: {
          "roll_no": rollNo,
          "test_code": testCode,
          "requested_phone": phone,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["error"] ??
            "Unable to submit request.",
      );
    }
  }
}