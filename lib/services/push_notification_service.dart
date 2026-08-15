import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/api/api_routes.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Dio _dio = ApiClient().dio;
  String? _rollNo;
  GoRouter? _router;
  AuthProvider? _authProvider;
  String? _pendingRoute;

  Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    _messaging.onTokenRefresh.listen((token) async {
      final rollNo = _rollNo;
      if (rollNo != null) await _saveToken(rollNo, token);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleNotificationTap(initialMessage);
  }

  /// Connects push-notification taps to the application's authenticated router.
  ///
  /// A notification can launch the app before GoRouter and the saved login
  /// session are ready. In that case the destination is retained and opened as
  /// soon as session restoration (or a new login) completes.
  void attachNavigation({
    required GoRouter router,
    required AuthProvider authProvider,
  }) {
    _router = router;

    if (!identical(_authProvider, authProvider)) {
      _authProvider?.removeListener(_openPendingRouteIfReady);
      _authProvider = authProvider;
      authProvider.addListener(_openPendingRouteIfReady);
    }

    _openPendingRouteIfReady();
  }

  Future<void> registerForStudent(String rollNo) async {
    _rollNo = rollNo.toUpperCase().trim();
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) await _saveToken(_rollNo!, token);
  }

  Future<void> unregisterCurrentStudent() async {
    final rollNo = _rollNo;
    final token = await _messaging.getToken();
    if (rollNo != null && token != null) {
      await _dio.delete(
        ApiRoutes.deviceToken,
        data: {'roll_no': rollNo, 'token': token},
      );
    }
    _rollNo = null;
  }

  Future<void> _saveToken(String rollNo, String token) async {
    await _dio.post(
      ApiRoutes.deviceToken,
      data: {
        'roll_no': rollNo,
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.android
            ? 'android'
            : defaultTargetPlatform.name,
      },
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final route = _routeForPayload(message.data);
    if (route == null) {
      debugPrint(
        'Notification tap ignored: unsupported module '
        '${message.data['module_name'] ?? message.data['module']}',
      );
      return;
    }

    _pendingRoute = route;
    _openPendingRouteIfReady();
  }

  String? _routeForPayload(Map<String, dynamic> data) {
    final module = (data['module_name'] ?? data['module'] ?? data['type'])
        ?.toString()
        .trim()
        .toLowerCase()
        .replaceAll('_', '-');

    switch (module) {
      case 'attendance':
        return AppRoutes.studentAttendance;
      case 'marks':
      case 'mark':
        return AppRoutes.studentMarks;
      case 'test':
      case 'tests':
      case 'test-schedule':
      case 'posted-test':
        return AppRoutes.studentTestSchedule;
      case 'fee':
      case 'fees':
        return AppRoutes.studentFee;
      case 'useful-link':
      case 'useful-links':
        return AppRoutes.studentUsefulLinks;
      case 'request-pdf':
        return AppRoutes.studentRequestPdf;
      default:
        return null;
    }
  }

  void _openPendingRouteIfReady() {
    final route = _pendingRoute;
    final router = _router;
    final authProvider = _authProvider;

    if (route == null || router == null || authProvider == null) return;
    if (!authProvider.isInitialized || !authProvider.isLoggedIn) return;

    final rollNo = authProvider.user?.id.trim();
    final destination = rollNo == null || rollNo.isEmpty
        ? route
        : Uri(path: route, queryParameters: {'roll': rollNo}).toString();

    _pendingRoute = null;
    router.go(destination);
  }
}
