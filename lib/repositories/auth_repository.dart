import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_routes.dart';
import '../models/login.dart';

class AuthRepository {
  final Dio _dio = ApiClient().dio;

  Future<LoginModel> login({
    required String id,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiRoutes.login,
        data: {
          "id": id,
          "password": password,
        },
      );

      return LoginModel.fromJson(response.data);
     } on DioException catch (e) {
  print("STATUS: ${e.response?.statusCode}");
  print("DATA: ${e.response?.data}");
  print("TYPE: ${e.response?.data.runtimeType}");

  throw Exception("Login failed");
  }}

  Future<bool> changePassword({
    required String id,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiRoutes.resetPassword,
        data: {
          "id": id,
          "newPassword": newPassword,
        },
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["error"] ??
            "Unable to change password.",
      );
    }
  }
}