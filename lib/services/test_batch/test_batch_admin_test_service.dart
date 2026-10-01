import '../../core/api/api_client.dart';

class TestBatchAdminTestService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> getPostedTests({
    required String adminId,
  }) async {
    try {
      final response = await _api.get(
        '/test-batch/tests',
        queryParameters: {'adminId': adminId.trim().toUpperCase()},
      );

      final data = response.data;
      final raw = data is Map<String, dynamic> ? data['tests'] : data;

      if (raw is! List) return <Map<String, dynamic>>[];

      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      throw Exception(
        message.isEmpty ? 'Failed to load Test Batch posted tests.' : message,
      );
    }
  }
}
