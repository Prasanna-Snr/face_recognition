import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:face/screens/splash_screen.dart';

void main() {
  testWidgets('Splash screen shows loading indicator', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Splash loader should be visible
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
