import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
  static const int _testReminderHour = 9;
  static const String _scheduledTestReminderIdsKey =
      'scheduled_test_reminder_ids';

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
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
    if (_rollNo!.startsWith('IAT')) {
      await scheduleTestBatchStudentReminders(_rollNo!);
    }
  }

  Future<void> unregisterCurrentStudent() async {
    await _cancelScheduledTestReminders();
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

    if (_facultyId == 'IG001' || _facultyId == 'IG002') {
      await scheduleTestBatchAdminReminders(_facultyId!);
    } else {
      await _cancelScheduledTestReminders();
    }

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
    await _cancelScheduledTestReminders();
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

  Future<void> scheduleTestBatchAdminReminders(String adminId) async {
    try {
      await _cancelScheduledTestReminders();

      final response = await _dio.get(
        '/test-batch/tests',
        queryParameters: {'adminId': adminId.trim().toUpperCase()},
      );
      final data = response.data;
      final rawTests = data is Map ? data['tests'] : data;
      if (rawTests is! List) return;

      for (final raw in rawTests.whereType<Map>()) {
        final test = Map<String, dynamic>.from(raw);
        final testCode = (test['test_code'] ?? '').toString().trim();
        final testDate = _parseDate(test['writing_date'] ?? test['test_date']);
        if (testCode.isEmpty || testDate == null) continue;

        await _scheduleTestReminder(
          idKey: 'admin:' + adminId + ':' + testCode,
          title: 'Test Reminder',
          body: testCode + ' is scheduled in 3 days.',
          testDate: testDate,
          daysBefore: 3,
          payload: {
            'module_name': 'test-batch-admin-test',
            'test_code': testCode,
          },
        );
      }
    } catch (error) {
      debugPrint('Test Batch admin reminder scheduling failed: $error');
    }
  }

  Future<void> scheduleTestBatchStudentReminders(String rollNo) async {
    try {
      await _cancelScheduledTestReminders();

      final response = await _dio.get(
        '/test-batch/student-tests/' +
            Uri.encodeComponent(rollNo.trim().toUpperCase()),
      );
      final data = response.data;
      final rawTests = data is Map ? data['tests'] : data;
      if (rawTests is! List) return;

      for (final raw in rawTests.whereType<Map>()) {
        final test = Map<String, dynamic>.from(raw);
        final testCode = (test['test_code'] ?? '').toString().trim();
        final isRegistered = test['is_registered'] == true;
        final writingDate = _parseDate(test['writing_date']);
        if (testCode.isEmpty || !isRegistered || writingDate == null) continue;

        await _scheduleTestReminder(
          idKey: 'student:' + rollNo + ':' + testCode,
          title: 'Test Reminder',
          body: testCode + ' is scheduled tomorrow.',
          testDate: writingDate,
          daysBefore: 1,
          payload: {
            'module_name': 'test-batch-student-test',
            'test_code': testCode,
          },
        );
      }
    } catch (error) {
      debugPrint('Test Batch student reminder scheduling failed: $error');
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    return parsed?.toLocal();
  }

  Future<void> _scheduleTestReminder({
    required String idKey,
    required String title,
    required String body,
    required DateTime testDate,
    required int daysBefore,
    required Map<String, dynamic> payload,
  }) async {
    final reminderDate = DateTime(
      testDate.year,
      testDate.month,
      testDate.day - daysBefore,
      _testReminderHour,
    );
    final scheduledAt = tz.TZDateTime.from(reminderDate, tz.local);

    if (!scheduledAt.isAfter(tz.TZDateTime.now(tz.local))) return;

    final id = idKey.hashCode & 0x7fffffff;
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      scheduledAt,
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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: jsonEncode(payload),
    );

    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_scheduledTestReminderIdsKey) ?? <String>[];
    if (!ids.contains(id.toString())) {
      ids.add(id.toString());
      await prefs.setStringList(_scheduledTestReminderIdsKey, ids);
    }

    debugPrint('Scheduled test reminder ' + idKey + ' for ' + scheduledAt.toString());
  }

  Future<void> _cancelScheduledTestReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_scheduledTestReminderIdsKey) ?? <String>[];
    for (final value in ids) {
      final id = int.tryParse(value);
      if (id != null) await _localNotifications.cancel(id);
    }
    await prefs.remove(_scheduledTestReminderIdsKey);
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
      case 'test-batch-admin-test':
        return AppRoutes.testBatchAdminTests;
      case 'test-batch-student-test':
        return AppRoutes.testBatchRegistration;
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
