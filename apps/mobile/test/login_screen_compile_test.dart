import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/login/login_screen.dart';

void main() {
  test('LoginScreen imports and compiles successfully', () {
    const Type type = LoginScreen;
    expect(type.toString(), 'LoginScreen');
  });
}
