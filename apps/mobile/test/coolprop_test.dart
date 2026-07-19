// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/coolprop.dart';

void main() {
  test('Antoine Equation Precision Validation', () {
    // Reference R32 saturation pressure at 20°C is ~14.7 bar
    final pR32 = CoolProp.getPressureFromTemp(
      refrigerant: 'R32',
      tempCelsius: 20.0,
      pressureUnit: 'Bar',
      isGauge: false,
    );
    final errorR32 = ((pR32 - 14.7) / 14.7).abs();
    expect(errorR32, lessThan(0.02)); // Margin of error < 2%

    // Reference R22 saturation pressure at 20°C is ~9.1 bar
    final pR22 = CoolProp.getPressureFromTemp(
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
      expect(CoolProp.convertPressure(1.0, 'Bar', 'Bar'), closeTo(1.0, 1e-5));
      expect(
        CoolProp.convertPressure(1.0, 'Bar', 'PSI'),
        closeTo(14.50377, 1e-3),
      );
      expect(CoolProp.convertPressure(100.0, 'kPa', 'Bar'), closeTo(1.0, 1e-5));
      expect(CoolProp.convertPressure(1.0, 'MPa', 'Bar'), closeTo(10.0, 1e-5));
    });

    test('Temperature conversions', () {
      expect(CoolProp.convertTemperature(0.0, '°C', '°F'), closeTo(32.0, 1e-5));
      expect(
        CoolProp.convertTemperature(100.0, '°C', 'K'),
        closeTo(373.15, 1e-5),
      );
      expect(CoolProp.convertTemperature(32.0, '°F', '°C'), closeTo(0.0, 1e-5));
    });

    test('Power conversions', () {
      expect(CoolProp.convertPower(1.0, 'HP', 'BTU/h'), closeTo(9000.0, 1e-5));
      expect(
        CoolProp.convertPower(1.0, 'kW', 'BTU/h'),
        closeTo(3412.142, 1e-3),
      );
    });
  });

  test('Thermodynamics facade matches CoolProp shim', () {
    final t = Thermodynamics();
    expect(
      t.getPressureFromTemp(
        refrigerant: 'R32',
        tempCelsius: 20,
        pressureUnit: 'Bar',
        isGauge: false,
      ),
      closeTo(
        CoolProp.getPressureFromTemp(
          refrigerant: 'R32',
          tempCelsius: 20,
          pressureUnit: 'Bar',
          isGauge: false,
        ),
        1e-9,
      ),
    );
    expect(
      t.getTempFromPressure(
        refrigerant: 'R22',
        pressure: 9.1,
        pressureUnit: 'Bar',
        isGauge: false,
      ),
      closeTo(
        CoolProp.getTempFromPressure(
          refrigerant: 'R22',
          pressure: 9.1,
          pressureUnit: 'Bar',
          isGauge: false,
        ),
        1e-6,
      ),
    );
    expect(t.hasAntoine('R32'), true);
    expect(t.hasAntoine('R410A'), true);
    expect(t.hasAntoine('Unknown'), false);
  });
}
