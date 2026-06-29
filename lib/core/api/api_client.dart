import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// ===========================================================
/// INTELLEKT API CLIENT
/// ===========================================================
///
/// Centralized Dio Client
///
/// Features:
/// • Singleton
/// • HTTPS
/// • Railway Backend
/// • Request Timeout
/// • Response Timeout
/// • Logging (Debug only)
/// • Automatic Headers
/// • Easy JWT Integration
///
/// ===========================================================

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(_baseOptions);

    _initializeInterceptors();
  }

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  late final Dio _dio;

  Dio get client => _dio;

  // ==========================================================
  // Backend URL
  // ==========================================================

  static const String baseUrl =
      'https://intellektdashboard-production.up.railway.app';

  // ==========================================================
  // Base Options
  // ==========================================================

  BaseOptions get _baseOptions => BaseOptions(
    baseUrl: baseUrl,

    connectTimeout: const Duration(seconds: 30),

    receiveTimeout: const Duration(seconds: 30),

    sendTimeout: const Duration(seconds: 30),

    responseType: ResponseType.json,

    contentType: Headers.jsonContentType,

    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );

  // ==========================================================
  // Interceptors
  // ==========================================================

  void _initializeInterceptors() {
    // Authentication Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          /*
          Future Upgrade:

          final token =
              await StorageService.getAccessToken();

          if (token != null) {
            options.headers["Authorization"] =
                "Bearer $token";
          }
          */

          handler.next(options);
        },

        onResponse: (response, handler) {
          handler.next(response);
        },

        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );

    // Pretty Logger
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          compact: true,
          maxWidth: 120,
        ),
      );
    }
  }

  // ==========================================================
  // GET
  // ==========================================================

  Future<Response> get(
      String endpoint, {
        Map<String, dynamic>? queryParameters,
      }) async {
    return await _dio.get(
      endpoint,
      queryParameters: queryParameters,
    );
  }

  // ==========================================================
  // POST
  // ==========================================================

  Future<Response> post(
      String endpoint, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
      }) async {
    return await _dio.post(
      endpoint,
      data: data,
      queryParameters: queryParameters,
    );
  }

  // ==========================================================
  // PUT
  // ==========================================================

  Future<Response> put(
      String endpoint, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
      }) async {
    return await _dio.put(
      endpoint,
      data: data,
      queryParameters: queryParameters,
    );
  }

  // ==========================================================
  // PATCH
  // ==========================================================

  Future<Response> patch(
      String endpoint, {
        dynamic data,
      }) async {
    return await _dio.patch(
      endpoint,
      data: data,
    );
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  Future<Response> delete(
      String endpoint, {
        dynamic data,
      }) async {
    return await _dio.delete(
      endpoint,
      data: data,
    );
  }
}