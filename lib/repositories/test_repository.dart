import '../core/api/api_client.dart';
import '../core/api/api_routes.dart';
import '../models/test.dart';

class TestRepository {
  final ApiClient _apiClient;

  TestRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<List<Test>> getStudentTests(String rollNo) async {
    final response = await _apiClient.get(ApiRoutes.studentTests(rollNo));

    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(Test.fromJson)
        .where(_isActiveTest)
        .toList();
  }

  bool _isActiveTest(Test test) {
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
