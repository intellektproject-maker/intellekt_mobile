import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../models/request_pdf.dart';

class RequestPdfService {
  RequestPdfService._();

  static final Dio _dio = ApiClient().dio;

  static Future<RequestPdfData> getRequestPdfData(
      String rollNo,
      ) async {
    try {
      final response = await _dio.get(
        '/student-answer-sheet-data/$rollNo',
      );

      return RequestPdfData.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["error"] ??
            "Unable to load request PDF data.",
      );
    }
  }

  static Future<bool> submitRequest({
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

      return true;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["error"] ??
            "Unable to submit request.",
      );
    }
  }
}