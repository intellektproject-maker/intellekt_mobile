import 'package:flutter_test/flutter_test.dart';
import 'package:intellekt_mobile/main.dart';

void main() {
  testWidgets('INTELLEKT app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const IntellektApp());

    expect(find.byType(IntellektApp), findsOneWidget);
  });
}