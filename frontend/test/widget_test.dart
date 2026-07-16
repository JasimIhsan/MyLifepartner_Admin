// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:life_partner_again/main.dart';
import 'package:life_partner_again/providers/auth_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(authProvider: AuthProvider()));
    await tester.pump(const Duration(seconds: 5));

    // Verify that the app builds without crashing.
    expect(find.byType(MyApp), findsOneWidget);
  });
}
// Premium Global Corp