// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('Smoke test for HvacApp', (WidgetTester tester) async {
    // Basic test just to ensure the widget can be instantiated.
    // In a real app with localization, we would need to mock or load translations.
    // For now we just test if OnboardingScreen renders.
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(find.text('Chào mừng đến với'), findsOneWidget);
  });
}
