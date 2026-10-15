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
  String? _facultyId;
  GoRouter? _router;
  AuthProvider? _authProvider;
  Map<String, dynamic>? _pendingNotificationData;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'intellekt_high_importance',
        'Intellekt notifications',
        description: 'Test, attendance, marks and student updates',
        importance: Importance.max,
      );

  static const String _lastFeeReminderPrefix = 'last_fee_reminder_';
  static const String _inAppNotificationsPrefix = 'in_app_notifications_';
  static const int _maxInAppNotifications = 30;
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
      if (rollNo != null) {
        await _saveStudentToken(rollNo, token);
        return;
      }

      final facultyId = _facultyId;
      if (facultyId != null) {
        await _saveFacultyToken(facultyId, token);
      }
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
    _facultyId = null;

    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveStudentToken(_rollNo!, token);
      }
    } catch (error) {
      debugPrint('Device notification registration failed: $error');
    }

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

  Future<void> registerForFaculty(String facultyId) async {
    _facultyId = facultyId.toUpperCase().trim();
    _rollNo = null;

    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveFacultyToken(_facultyId!, token);
      }
    } catch (error) {
      debugPrint('Faculty device notification registration failed: $error');
      rethrow;
    }
  }

  Future<void> unregisterCurrentFaculty() async {
    final facultyId = _facultyId;
    final token = await _messaging.getToken();

    if (facultyId != null && token != null && token.isNotEmpty) {
      await _dio.delete(
        ApiRoutes.facultyDeviceToken,
        data: {'faculty_id': facultyId, 'token': token},
      );
    }

    _facultyId = null;
  }

  Future<void> _saveStudentToken(String rollNo, String token) async {
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

    debugPrint('Notification device registered for student $rollNo');
  }

  Future<void> _saveFacultyToken(String facultyId, String token) async {
    await _dio.post(
      ApiRoutes.facultyDeviceToken,
      data: {
        'faculty_id': facultyId,
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.android
            ? 'android'
            : defaultTargetPlatform.name,
      },
    );

    debugPrint('Notification device registered for faculty $facultyId');
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

  static Future<void> storeBackgroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString() ?? 'INTELLEKT';
    final body = notification?.body ?? message.data['body']?.toString() ?? '';
    await _storeInAppNotification(
      rollNo: message.data['roll_no']?.toString(),
      title: title,
      body: body,
      data: message.data,
    );
  }

  static Future<void> _storeInAppNotification({
    String? rollNo,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    if (rollNo == null || rollNo.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = _inAppNotificationsPrefix + rollNo.trim().toUpperCase();
    final existing = prefs.getStringList(key) ?? <String>[];
    final item = jsonEncode({
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data.map((key, value) => MapEntry(key, value.toString())),
    });
    existing.insert(0, item);
    if (existing.length > _maxInAppNotifications) {
      existing.removeRange(_maxInAppNotifications, existing.length);
    }
    await prefs.setStringList(key, existing);
  }

  Future<List<Map<String, dynamic>>> getInAppNotifications(String rollNo) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _inAppNotificationsPrefix + rollNo.trim().toUpperCase();
    final values = prefs.getStringList(key) ?? <String>[];
    final notifications = <Map<String, dynamic>>[];
    for (final value in values) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          notifications.add(decoded);
        }
      } catch (_) {}
    }
    return notifications;
  }

  Future<void> clearInAppNotifications(String rollNo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(
      _inAppNotificationsPrefix + rollNo.trim().toUpperCase(),
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final notification = message.notification;
    if (notification == null) return;

    await _storeInAppNotification(
      rollNo: message.data['roll_no']?.toString() ?? _rollNo,
      title: notification.title ?? 'INTELLEKT',
      body: notification.body ?? '',
      data: message.data,
    );

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
      payload: jsonEncode({
        ...message.data,
        'title': notification.title ?? 'INTELLEKT',
        'body': notification.body ?? '',
      }),
    );
  }

  /// Opens a notification payload from an in-app notification list.
  /// Routing is resolved only after the authenticated role is available.
  void openNotificationData(Map<String, dynamic> data) {
    _pendingNotificationData = Map<String, dynamic>.from(data);
    _openPendingRouteIfReady();
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _pendingNotificationData = Map<String, dynamic>.from(decoded);
        _openPendingRouteIfReady();
      }
    } catch (error) {
      debugPrint('Could not open foreground notification: $error');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Preserve the payload until authentication is ready so the same
    // notification can be routed safely for the signed-in role.
    final data = Map<String, dynamic>.from(message.data);
    final notification = message.notification;
    if ((data['title'] == null || data['title'].toString().trim().isEmpty) &&
        notification?.title != null) {
      data['title'] = notification!.title;
    }
    if ((data['body'] == null || data['body'].toString().trim().isEmpty) &&
        notification?.body != null) {
      data['body'] = notification!.body;
    }
    _pendingNotificationData = data;
    _openPendingRouteIfReady();
  }

  String? _routeForPayload(Map<String, dynamic> data) {
    final auth = _authProvider;
    final user = auth?.user;
    if (auth == null || user == null) return null;

    final module = (data['module_name'] ?? data['module'] ?? data['type'])
        ?.toString()
        .trim()
        .toLowerCase()
        .replaceAll('_', '-');
    final title = (data['title'] ?? '').toString().trim().toLowerCase();
    final reminderType = (data['reminder_type'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    // Admins (IG001/IG002 or backend role=admin) use admin destinations.
    // Keep this before the faculty branch because admin accounts also use the
    // existing staff notification-token and route infrastructure.
    if (user.isAdmin) {
      switch (module) {
        case 'test-batch-admin-test':
        case 'test-batch-admin-registration':
        case 'test-batch':
        case 'test-batch-student-test':
        case 'test-batch-registration':
        case 'test-registration':
        case 'test-batch-test':
        case 'test':
        case 'tests':
        case 'test-schedule':
        case 'posted-test':
        case 'test-reminder':
          return AppRoutes.testBatchAdminTests;
        case 'profile':
        case 'dashboard':
        case 'task':
        case 'tasks':
        case 'attendance':
        case 'marks':
        case 'mark':
          return AppRoutes.facultyProfile;
        case 'faculty-notification':
        case 'faculty-notifications':
        case 'notifications':
        default:
          return AppRoutes.facultyNotifications;
      }
    }

    // Faculty notifications must never be routed into student pages.
    if (auth.isFaculty) {
      switch (module) {
        case 'test-batch-admin-test':
        case 'test-batch-admin-registration':
        case 'test-batch':
          return AppRoutes.testBatchAdminTests;
        case 'faculty-notification':
        case 'faculty-notifications':
        case 'notifications':
          return AppRoutes.facultyNotifications;
        case 'tasks':
        case 'task':
        case 'attendance':
        case 'marks':
        case 'mark':
        case 'test':
        case 'tests':
        case 'test-reminder':
        case 'test-schedule':
        case 'profile':
          return AppRoutes.facultyProfile;
        default:
          // Faculty push notifications without a recognized feature should
          // still land in their own notification centre, not a student route.
          return AppRoutes.facultyNotifications;
      }
    }

    if (auth.isTestBatchStudent) {
      switch (module) {
        case 'attendance':
        case 'test-batch-attendance':
          return AppRoutes.testBatchAttendance;
        case 'marks':
        case 'mark':
        case 'test-batch-marks':
          return AppRoutes.testBatchMarks;
        case 'test-batch-student-test':
        case 'test-batch-registration':
        case 'test-registration':
        case 'test-batch-test':
          return AppRoutes.testBatchRegistration;
        case 'test':
        case 'tests':
        case 'test-schedule':
        case 'posted-test':
        case 'test-reminder':
          return AppRoutes.testBatchRegistration;
        case 'profile':
        case 'dashboard':
          return AppRoutes.testBatchDashboard;
        default:
          return null;
      }
    }

    if (auth.isRegularStudent) {
      // A general test reminder is intended to bring the student to their
      // dashboard/profile; explicit schedule updates open the schedule page.
      if (module == 'test-reminder' ||
          title.contains('test reminder') ||
          reminderType == 'student_1_day') {
        return AppRoutes.studentDashboard;
      }

      switch (module) {
        case 'profile':
        case 'dashboard':
          return AppRoutes.studentDashboard;
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
        // Never send a regular student into isolated Test Batch screens.
        case 'test-batch-admin-test':
        case 'test-batch-admin-registration':
        case 'test-batch-student-test':
        case 'test-batch-registration':
          return AppRoutes.studentDashboard;
        default:
          return null;
      }
    }

    return null;
  }

  void _openPendingRouteIfReady() {
    final data = _pendingNotificationData;
    final router = _router;
    final authProvider = _authProvider;

    if (data == null || router == null || authProvider == null) return;
    if (!authProvider.isInitialized || !authProvider.isLoggedIn) return;

    final route = _routeForPayload(data);
    if (route == null) {
      debugPrint(
        'Notification tap ignored for role/module: '
        '${data['module_name'] ?? data['module'] ?? data['type']}',
      );
      _pendingNotificationData = null;
      return;
    }

    final userId = authProvider.user?.id.trim();
    final destination = userId == null || userId.isEmpty
        ? route
        : Uri(path: route, queryParameters: {'roll': userId}).toString();

    _pendingNotificationData = null;
    router.go(destination);
  }
}
