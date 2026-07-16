import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/login/login_screen.dart';

void main() {
  testWidgets('LoginScreen compiles and builds successfully', (WidgetTester tester) async {
    // We mock or wrap it because LoginScreen has easy_localization, but since we are not testing localization here, we just pump it
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
