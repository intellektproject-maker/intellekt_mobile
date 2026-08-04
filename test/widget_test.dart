import 'package:flutter_test/flutter_test.dart';
import 'package:intellekt_mobile/main.dart';
import 'package:intellekt_mobile/providers/auth_provider.dart';
import 'package:intellekt_mobile/routes/app_router.dart';

void main() {
  testWidgets('INTELLEKT app starts', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    final router = AppRouter.createRouter(authProvider);

    await tester.pumpWidget(
      IntellektApp(
        authProvider: authProvider,
        router: router,
      ),
    );

    await tester.pump();

    expect(find.byType(IntellektApp), findsOneWidget);

    router.dispose();
    authProvider.dispose();
  });
}