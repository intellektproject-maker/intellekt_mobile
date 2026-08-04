import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/student/student_provider.dart';
import 'providers/student/test_schedule_provider.dart';
import 'providers/student/attendance_provider.dart';
import 'providers/student/marks_provider.dart';
import 'providers/student/fee_provider.dart';
import 'providers/student/useful_links_provider.dart';
import 'providers/student/request_pdf_provider.dart';
import 'routes/app_router.dart';
import 'services/push_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  await PushNotificationService.instance.initialize();

  GoogleFonts.config.allowRuntimeFetching = false;

  final authProvider = AuthProvider();
  final router = AppRouter.createRouter(authProvider);

  runApp(
    IntellektApp(
      authProvider: authProvider,
      router: router,
    ),
  );
}

class IntellektApp extends StatelessWidget {
  final AuthProvider authProvider;
  final GoRouter router;

  const IntellektApp({
    super.key,
    required this.authProvider,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
        ),
        ChangeNotifierProvider(
          create: (_) => StudentProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => TestScheduleProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AttendanceProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => MarksProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => FeeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => UsefulLinksProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => RequestPdfProvider(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'INTELLEKT',
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }
}