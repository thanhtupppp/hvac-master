import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/hvac/formulas/psychrometric.dart';

void main() {
  group('psychrometric', () {
    test('dewPoint returns NaN for invalid RH', () {
      expect(dewPoint(25, 0).isNaN, isTrue);
      expect(dewPoint(25, -5).isNaN, isTrue);
      expect(dewPoint(25, 101).isNaN, isTrue);
    });

    test('dewPoint at 100% RH equals temperature', () {
      expect(dewPoint(25, 100), closeTo(25, 0.1));
      expect(dewPoint(0, 100), closeTo(0, 0.1));
    });

    test('dewPoint at 50% RH is less than temperature', () {
      final dp = dewPoint(25, 50);
      expect(dp, lessThan(25));
      expect(dp, greaterThan(10));
    });

    test('saturationVaporPressure positive for positive temps', () {
      expect(saturationVaporPressure(20), greaterThan(0));
      expect(saturationVaporPressure(0), greaterThan(0));
      expect(saturationVaporPressure(37.78), closeTo(6.54, 0.1)); // 100°F in hPa
    });

    test('humidityRatio returns NaN for invalid RH', () {
      expect(humidityRatio(25, 0).isNaN, isTrue);
    });

    test('humidityRatio positive for positive temp and RH', () {
      final w = humidityRatio(25, 60);
      expect(w, greaterThan(0));
      expect(w, lessThan(0.1));
    });

    test('wetBulbTemperature returns NaN for invalid RH', () {
      expect(wetBulbTemperature(25, 0).isNaN, isTrue);
    });

    test('wetBulbTemperature <= dry bulb temperature', () {
      final wb = wetBulbTemperature(30, 50);
      expect(wb, lessThanOrEqualTo(30));
    });
  });
}
