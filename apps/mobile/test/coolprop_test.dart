import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/hvac/thermo/thermo.dart';
import 'package:mobile/core/hvac/units/pressure.dart';
import 'package:mobile/core/hvac/units/temperature.dart';
import 'package:mobile/core/hvac/units/power.dart';

void main() {
  test('Antoine Equation Precision Validation', () {
    final t = Thermodynamics();
    // Reference R32 saturation pressure at 20°C is ~14.7 bar
    final pR32 = t.getPressureFromTemp(
      refrigerant: 'R32',
      tempCelsius: 20.0,
      pressureUnit: 'Bar',
      isGauge: false,
    );
    final errorR32 = ((pR32 - 14.7) / 14.7).abs();
    expect(errorR32, lessThan(0.02)); // Margin of error < 2%

    // Reference R22 saturation pressure at 20°C is ~9.1 bar
    final pR22 = t.getPressureFromTemp(
      refrigerant: 'R22',
      tempCelsius: 20.0,
      pressureUnit: 'Bar',
      isGauge: false,
    );
    final errorR22 = ((pR22 - 9.1) / 9.1).abs();
    expect(errorR22, lessThan(0.02)); // Margin of error < 2%
  });

  group('General Unit Conversions', () {
    test('Pressure conversions', () {
      expect(
        PressureConverter.convert(1.0, PressureUnit.bar, PressureUnit.bar),
        closeTo(1.0, 1e-5),
      );
      expect(
        PressureConverter.convert(1.0, PressureUnit.bar, PressureUnit.psi),
        closeTo(14.50377, 1e-3),
      );
      expect(
        PressureConverter.convert(100.0, PressureUnit.kpa, PressureUnit.bar),
        closeTo(1.0, 1e-5),
      );
      expect(
        PressureConverter.convert(1.0, PressureUnit.mpa, PressureUnit.bar),
        closeTo(10.0, 1e-5),
      );
    });

    test('Temperature conversions', () {
      expect(
        TemperatureConverter.convert(
          0.0,
          TemperatureUnit.celsius,
          TemperatureUnit.fahrenheit,
        ),
        closeTo(32.0, 1e-5),
      );
      expect(
        TemperatureConverter.convert(
          100.0,
          TemperatureUnit.celsius,
          TemperatureUnit.kelvin,
        ),
        closeTo(373.15, 1e-5),
      );
      expect(
        TemperatureConverter.convert(
          32.0,
          TemperatureUnit.fahrenheit,
          TemperatureUnit.celsius,
        ),
        closeTo(0.0, 1e-5),
      );
    });

    test('Power conversions', () {
      // PowerConverter uses mechanical HP (1 HP ≈ 745.7 W → 2544 BTU/h)
      expect(
        PowerConverter.convert(1.0, PowerUnit.hp, PowerUnit.btuHr),
        closeTo(2544.43, 0.01),
      );
      expect(
        PowerConverter.convert(1.0, PowerUnit.kw, PowerUnit.btuHr),
        closeTo(3412.142, 1e-3),
      );
    });
  });

  group('Thermodynamics Antoine API', () {
    test('getPressureFromTemp for R32 at 20°C is ~14.7 bar', () {
      final t = Thermodynamics();
      final p = t.getPressureFromTemp(
        refrigerant: 'R32',
        tempCelsius: 20,
        pressureUnit: 'Bar',
        isGauge: false,
      );
      expect(
        p.isNaN,
        false,
        reason: 'Pressure should be valid for R32 at 20°C',
      );
      expect(p.isInfinite, false);
      expect(p, closeTo(14.7, 0.5));
    });

    test('hasAntoine returns true for known refrigerants', () {
      final t = Thermodynamics();
      expect(t.hasAntoine('R32'), true);
      expect(t.hasAntoine('R410A'), true);
      expect(t.hasAntoine('Unknown'), false);
    });

    test('getTempFromPressure for R22 at 9.1 bar is ~20°C', () {
      final t = Thermodynamics();
      final temp = t.getTempFromPressure(
        refrigerant: 'R22',
        pressure: 9.1,
        pressureUnit: 'Bar',
        isGauge: false,
      );
      expect(
        temp.isNaN,
        false,
        reason: 'R22 at 9.1 bar should be in Antoine range',
      );
      expect(temp.isInfinite, false);
      expect(temp, closeTo(20.0, 3.0));
    });
  });
}
