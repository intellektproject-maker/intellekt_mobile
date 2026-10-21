import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellekt_mobile/main.dart';
import 'package:intellekt_mobile/providers/auth_provider.dart';
import 'package:intellekt_mobile/routes/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      // Simulate an empty secure store for the widget test. This keeps the
      // production authentication and secure-storage implementation unchanged.
      switch (call.method) {
        case 'read':
          return null;
        case 'delete':
        case 'write':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  testWidgets('INTELLEKT app starts', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    await tester.runAsync(() => authProvider.restoreSession());
    final router = AppRouter.createRouter(authProvider);

    await tester.pumpWidget(
      IntellektApp(
        authProvider: authProvider,
        router: router,
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.byType(IntellektApp), findsOneWidget);

    router.dispose();
    authProvider.dispose();
  });
}
