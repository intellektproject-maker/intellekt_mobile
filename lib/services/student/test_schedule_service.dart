import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_routes.dart';
import '../../data/mock/mock_test_slots_data.dart';
import '../../models/test.dart';

class TestScheduleService {
  TestScheduleService._();

  static final Dio _dio = ApiClient().dio;

  // Replace ONLY this method
  static Future<List<Test>> getTests(String rollNo) async {
    try {
      final response = await _dio.get(
        ApiRoutes.studentTests(rollNo),
      );

      return (response.data as List)
          .map((e) => Test.fromJson(e))
          .where(_isActiveTest)
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["error"] ??
            "Unable to load tests.",
      );
    }
  }

  // KEEP this exactly as it was
  static Future<List<Map<String, dynamic>>> getSlots({
    required String rollNo,
    required String testCode,
    required DateTime writingDate,
  }) async {
    try {
      final response = await _dio.get(
        ApiRoutes.studentTestSlots(testCode, rollNo),
        queryParameters: {
          "writing_date":
          writingDate.toIso8601String().split('T').first,
        },
      );

      if (response.data["requires_slot"] == false) {
        return [];
      }

      return List<Map<String, dynamic>>.from(
        response.data["slots"],
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["error"] ??
            "Unable to load slots.",
      );
    }
  }
  static Future<void> registerTest({
    required String rollNo,
    required String testCode,
    required DateTime writingDate,
    String? slotStart,
    String? slotEnd,
  }) async {
    try {
      await _dio.post(
        ApiRoutes.registerTest,
        data: {
          "roll_no": rollNo,
          "test_code": testCode,
          "writing_date":
          writingDate.toIso8601String().split('T').first,
          "slot_start": slotStart,
          "slot_end": slotEnd,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["error"] ??
            "Failed to register test.",
      );
    }
  }
  // KEEP this too
  static bool _isActiveTest(Test test) {
    final writingAllowedTill = test.writingAllowedTill;

    if (writingAllowedTill == null) {
      return false;
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final writingTill = DateTime(
      writingAllowedTill.year,
      writingAllowedTill.month,
      writingAllowedTill.day,
    );

    return !writingTill.isBefore(today);
  }
}