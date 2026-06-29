import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/api_routes.dart';
import 'storage_service.dart';

/// ===========================================================
/// INTELLEKT AUTH SERVICE
/// ===========================================================
///
/// Handles:
/// • Login
/// • Logout
/// • Session
/// • Future JWT Support
///
/// ===========================================================

class AuthService {
  AuthService._();

  static final Dio _dio = ApiClient().client;

  /// ==========================================================
  /// LOGIN
  /// ==========================================================

  static Future<ApiResponse<Map<String, dynamic>>> login({
    required String userId,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final response = await _dio.post(
        ApiRoutes.login,
        data: {
          "id": userId,
          "password": password,
        },
      );

      final data = response.data;

      if (data["success"] == true) {
        // Save User Details

        await StorageService.saveUserId(userId);

        if (data["role"] != null) {
          await StorageService.saveUserRole(
            data["role"],
          );
        }

        await StorageService.setRememberMe(
          rememberMe,
        );

        await StorageService.setLoggedIn(true);

        // ---------------------------------------------------
        // Future JWT Upgrade
        // ---------------------------------------------------
        //
        // if(data["accessToken"] != null){
        //   await StorageService.saveAccessToken(
        //       data["accessToken"]);
        // }
        //
        // if(data["refreshToken"] != null){
        //   await StorageService.saveRefreshToken(
        //       data["refreshToken"]);
        // }
        //
        // ---------------------------------------------------

        return ApiResponse.success(
          data: Map<String, dynamic>.from(data),
          message: "Login Successful",
        );
      }

      return ApiResponse.error(
        message: data["message"] ??
            "Invalid User ID or Password",
      );
    } on DioException catch (e) {
      return ApiResponse.error(
        message: _handleDioError(e),
      );
    } catch (e) {
      return ApiResponse.error(
        message: e.toString(),
      );
    }
  }

  /// ==========================================================
  /// LOGOUT
  /// ==========================================================

  static Future<void> logout() async {
    await StorageService.clearSession();
  }

  /// ==========================================================
  /// SESSION
  /// ==========================================================

  static Future<bool> isLoggedIn() async {
    return await StorageService.isLoggedIn();
  }

  static Future<String?> getUserRole() async {
    return await StorageService.getUserRole();
  }

  static Future<String?> getUserId() async {
    return await StorageService.getUserId();
  }

  /// ==========================================================
  /// DIO ERROR HANDLER
  /// ==========================================================

  static String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return "Connection Timeout";

      case DioExceptionType.sendTimeout:
        return "Request Timeout";

      case DioExceptionType.receiveTimeout:
        return "Server Timeout";

      case DioExceptionType.connectionError:
        return "No Internet Connection";

      case DioExceptionType.badResponse:
        return e.response?.data["message"] ??
            "Server Error";

      case DioExceptionType.cancel:
        return "Request Cancelled";

      default:
        return "Something went wrong";
    }
  }
}