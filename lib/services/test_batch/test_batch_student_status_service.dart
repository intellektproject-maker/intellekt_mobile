import '../../core/api/api_client.dart';

class TestBatchStudentStatusService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> fetch({
    required String adminId,
    String? category,
    String? className,
    String? board,
    String? seriesId,
    String? testCode,
  }) async {
    try {
      final params = <String, dynamic>{
        'adminId': adminId.trim().toUpperCase(),
      };
      if (category != null && category.isNotEmpty) params['category'] = category;
      if (className != null && className.isNotEmpty) params['class'] = className;
      if (board != null && board.isNotEmpty) params['board'] = board;
      if (seriesId != null && seriesId.isNotEmpty) params['seriesId'] = seriesId;
      if (testCode != null && testCode.isNotEmpty) params['testCode'] = testCode;

      final response = await _api.get('/test-batch/student-status', queryParameters: params);
      final data = response.data;
      if (data is! Map) return {'filters': {}, 'students': <Map<String, dynamic>>[]};

      final filtersRaw = data['filters'];
      final studentsRaw = data['students'];

      return {
        'filters': filtersRaw is Map
            ? Map<String, dynamic>.from(filtersRaw)
            : <String, dynamic>{},
        'students': studentsRaw is List
            ? studentsRaw
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
            : <Map<String, dynamic>>[],
      };
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      throw Exception(
        message.isEmpty ? 'Failed to load Test Batch student status.' : message,
      );
    }
  }
}
