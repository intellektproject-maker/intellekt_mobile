import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/api/api_client.dart';
import '../core/api/api_routes.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Dio _dio = ApiClient().dio;
  String? _rollNo;

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
    // The payload's route/module can be connected to GoRouter after the
    // corresponding notification details screen is finalized.
  }
}
