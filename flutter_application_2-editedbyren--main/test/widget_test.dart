import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/main.dart';

void main() {
  testWidgets('Login screen loads and accepts input', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp()); // ✅ Use MyApp if that’s your main widget

    // Check that the login screen shows up
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Email & password fields

    // Type into the fields
    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');

    // Tap the login button
    await tester.tap(find.text('Login'));
    await tester.pump();

    // Check that login worked (customize this based on your app)
    expect(find.text('Student Dashboard'), findsOneWidget);
  });
}
