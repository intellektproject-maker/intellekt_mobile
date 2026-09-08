import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_routes.dart';
import '../models/faculty_model.dart';

class FacultyRepository {
  final Dio _dio = ApiClient().dio;

  Future<FacultyModel> getFacultyProfile(String facultyId) async {
    try {
      final response = await _dio.get(
        ApiRoutes.facultyDetails(facultyId.trim().toUpperCase()),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid faculty profile response.');
      }

      return FacultyModel.fromJson(data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map<String, dynamic>
          ? data['error']?.toString()
          : null;
      throw Exception(message ?? 'Unable to load faculty profile.');
    }
  }
}
