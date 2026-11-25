import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:intellekt_mobile/main.dart';
import 'package:intellekt_mobile/providers/auth_provider.dart';
import 'package:intellekt_mobile/routes/app_router.dart';

class _InitializedAuthProvider extends AuthProvider {
  @override
  bool get isInitialized => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('INTELLEKT app starts', (WidgetTester tester) async {
    final authProvider = _InitializedAuthProvider();
    final router = AppRouter.createRouter(authProvider);

    await tester.pumpWidget(
      IntellektApp(
        authProvider: authProvider,
        router: router,
      ),
    );

    // The splash screen intentionally waits 2 seconds before routing.
    // Advance fake time so its delayed timer completes before the test ends.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(IntellektApp), findsOneWidget);

    router.dispose();
    authProvider.dispose();
  });
}