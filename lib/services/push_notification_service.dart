import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_client.dart';
import '../core/api/api_routes.dart';
import '../models/fee.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../services/student/fee_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Dio _dio = ApiClient().dio;
  String? _rollNo;
  GoRouter? _router;
  AuthProvider? _authProvider;
  String? _pendingRoute;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'intellekt_high_importance',
        'Intellekt notifications',
        description: 'Test, attendance, marks and student updates',
        importance: Importance.max,
      );

  static const String _lastFeeReminderPrefix = 'last_fee_reminder_';
  static const Duration _feeReminderInterval = Duration(hours: 24);

  Future<void> initialize() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    final permission = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'Notification permission: ${permission.authorizationStatus.name}',
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _messaging.onTokenRefresh.listen((token) async {
      final rollNo = _rollNo;
      if (rollNo != null) await _saveToken(rollNo, token);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleNotificationTap(initialMessage);
  }

  /// Connects push-notification taps to the application's authenticated router.
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

    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveToken(_rollNo!, token);
      }
    } catch (error) {
      debugPrint('Device notification registration failed: $error');
    }

    // Option A: the app checks the current fee reminder setting whenever the
    // authenticated student opens/restores the app. No server worker is needed.
    await check24HourFeeReminder(_rollNo!);
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

    debugPrint('Notification device registered for $rollNo');
  }

  Future<void> check24HourFeeReminder(String rollNo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_lastFeeReminderPrefix$rollNo';
      final lastShownMillis = prefs.getInt(key);
      final now = DateTime.now();

      if (lastShownMillis != null) {
        final lastShown = DateTime.fromMillisecondsSinceEpoch(lastShownMillis);
        if (now.difference(lastShown) < _feeReminderInterval) {
          debugPrint('24-hour fee reminder skipped for $rollNo');
          return;
        }
      }

      final fees = await FeeService.getFees(rollNo);
      if (fees.isEmpty) {
        debugPrint('No fee record available for $rollNo');
        return;
      }

      final reminderFee = fees.cast<Fee?>().firstWhere(
            (fee) => fee?.reminderEnabled == true,
        orElse: () => null,
      );

      if (reminderFee == null) {
        debugPrint('Fee reminder is disabled for $rollNo');
        return;
      }

      final balance = reminderFee.balance;
      final dueDate = reminderFee.nextDue;
      final body = dueDate == null
          ? 'Your fee reminder is enabled. Pending balance: ₹${balance.toStringAsFixed(2)}.'
          : 'Your fee reminder is enabled. Pending balance: ₹${balance.toStringAsFixed(2)}. Due: ${_formatDate(dueDate)}.';

      await _localNotifications.show(
        ('fee-reminder-$rollNo').hashCode,
        'Fee Reminder',
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'intellekt_high_importance',
            'Intellekt notifications',
            channelDescription: 'Test, attendance, marks and student updates',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode({'module_name': 'fee'}),
      );

      await prefs.setInt(key, now.millisecondsSinceEpoch);
      debugPrint('24-hour fee reminder shown for $rollNo');
    } catch (error) {
      debugPrint('24-hour fee reminder check failed for $rollNo: $error');
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      notification.title ?? 'Intellekt',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'intellekt_high_importance',
          'Intellekt notifications',
          channelDescription: 'Test, attendance, marks and student updates',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        final route = _routeForPayload(decoded);
        if (route != null) {
          _pendingRoute = route;
          _openPendingRouteIfReady();
        }
      }
    } catch (error) {
      debugPrint('Could not open foreground notification: $error');
    }
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
