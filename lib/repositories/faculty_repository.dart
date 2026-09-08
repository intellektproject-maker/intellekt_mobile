import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_routes.dart';
import '../models/faculty_model.dart';

class FacultyRepository {
  final Dio _dio = ApiClient().dio;

  Future<FacultyModel> getFacultyProfile(String facultyId) async {
    final normalizedId = facultyId.trim().toUpperCase();

    try {
      final response = await _dio.get(
        ApiRoutes.facultyDetails(normalizedId),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid faculty profile response.');
      }

      return FacultyModel.fromJson(data);
    } on DioException catch (e) {
      // During mobile UI development, older/development backends may not
      // contain the faculty record yet. Use the repository's existing dummy
      // record for known faculty IDs so the profile screen remains usable.
      if (e.response?.statusCode == 404) {
        final fallback = FacultyModel.dummyFacultyList.where(
          (faculty) => faculty.facultyId.trim().toUpperCase() == normalizedId,
        );

        if (fallback.isNotEmpty) {
          return fallback.first;
        }
      }

      final data = e.response?.data;
      final message = data is Map<String, dynamic>
          ? data['error']?.toString()
          : null;
      throw Exception(message ?? 'Unable to load faculty profile.');
    }
  }
}
