import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/hvac/units/power.dart';
import 'package:mobile/core/hvac/units/temperature.dart';
import 'package:mobile/core/hvac/units/pressure.dart';

void main() {
  group('PowerConverter', () {
    test('identity conversions', () {
      for (final u in PowerUnit.values) {
        expect(PowerConverter.convert(1.0, u, u), closeTo(1.0, 1e-9));
      }
    });

    test('BTU/h <-> W reference points', () {
      expect(
        PowerConverter.convert(1.0, PowerUnit.btuHr, PowerUnit.w),
        closeTo(0.29307107, 1e-7),
      );
      expect(
        PowerConverter.convert(1.0, PowerUnit.w, PowerUnit.btuHr),
        closeTo(3.412142, 1e-5),
      );
    });

    test('ton (refrigeration ton) <-> W', () {
      // 1 RT = 12000 BTU/h = 3516.85 W
      expect(
        PowerConverter.convert(1.0, PowerUnit.ton, PowerUnit.btuHr),
        closeTo(12000.0, 1e-6),
      );
      expect(
        PowerConverter.convert(1.0, PowerUnit.ton, PowerUnit.w),
        closeTo(3516.8525, 1e-3),
      );
    });

    test('hp (mechanical) <-> W', () {
      // 1 hp = 745.7 W
      expect(
        PowerConverter.convert(1.0, PowerUnit.hp, PowerUnit.w),
        closeTo(745.7, 1e-1),
      );
    });

    test('kW <-> W round-trip', () {
      expect(
        PowerConverter.convert(5.0, PowerUnit.kw, PowerUnit.w),
        closeTo(5000.0, 1e-6),
      );
      expect(
        PowerConverter.convert(5000.0, PowerUnit.w, PowerUnit.kw),
        closeTo(5.0, 1e-9),
      );
    });

    test('negative and zero', () {
      expect(
        PowerConverter.convert(-100.0, PowerUnit.kw, PowerUnit.w),
        closeTo(-100000.0, 1e-3),
      );
      expect(PowerConverter.convert(0.0, PowerUnit.hp, PowerUnit.btuHr), 0.0);
    });

    test('all units present in all label', () {
      for (final u in PowerUnit.values) {
        expect(PowerConverter.label(u).isNotEmpty, true);
      }
    });
  });

  group('TemperatureConverter', () {
    test('identity', () {
      for (final u in TemperatureUnit.values) {
        expect(TemperatureConverter.convert(25.0, u, u), closeTo(25.0, 1e-9));
      }
    });

    test('Celsius <-> Fahrenheit reference points', () {
      expect(
        TemperatureConverter.convert(
          0.0,
          TemperatureUnit.celsius,
          TemperatureUnit.fahrenheit,
        ),
        closeTo(32.0, 1e-9),
      );
      expect(
        TemperatureConverter.convert(
          100.0,
          TemperatureUnit.celsius,
          TemperatureUnit.fahrenheit,
        ),
        closeTo(212.0, 1e-9),
      );
      expect(
        TemperatureConverter.convert(
          32.0,
          TemperatureUnit.fahrenheit,
          TemperatureUnit.celsius,
        ),
        closeTo(0.0, 1e-9),
      );
      expect(
        TemperatureConverter.convert(
          -40.0,
          TemperatureUnit.fahrenheit,
          TemperatureUnit.celsius,
        ),
        closeTo(-40.0, 1e-9),
      );
    });

    test('Celsius <-> Kelvin reference points', () {
      expect(
        TemperatureConverter.convert(
          0.0,
          TemperatureUnit.celsius,
          TemperatureUnit.kelvin,
        ),
        closeTo(273.15, 1e-9),
      );
      expect(
        TemperatureConverter.convert(
          100.0,
          TemperatureUnit.celsius,
          TemperatureUnit.kelvin,
        ),
        closeTo(373.15, 1e-9),
      );
      expect(
        TemperatureConverter.convert(
          273.15,
          TemperatureUnit.kelvin,
          TemperatureUnit.celsius,
        ),
        closeTo(0.0, 1e-9),
      );
    });

    test('Fahrenheit <-> Kelvin', () {
      expect(
        TemperatureConverter.convert(
          32.0,
          TemperatureUnit.fahrenheit,
          TemperatureUnit.kelvin,
        ),
        closeTo(273.15, 1e-6),
      );
      expect(
        TemperatureConverter.convert(
          0.0,
          TemperatureUnit.kelvin,
          TemperatureUnit.fahrenheit,
        ),
        closeTo(-459.67, 1e-2),
      );
    });
  });

  group('TemperatureDeltaConverter', () {
    test('identity', () {
      for (final u in TemperatureDeltaUnit.values) {
        expect(
          TemperatureDeltaConverter.convert(10.0, u, u),
          closeTo(10.0, 1e-9),
        );
      }
    });

    test('delta F -> delta C', () {
      expect(
        TemperatureDeltaConverter.convert(
          9.0,
          TemperatureDeltaUnit.fahrenheit,
          TemperatureDeltaUnit.celsius,
        ),
        closeTo(5.0, 1e-9),
      );
    });

    test('delta C -> delta K (same magnitude)', () {
      expect(
        TemperatureDeltaConverter.convert(
          5.0,
          TemperatureDeltaUnit.celsius,
          TemperatureDeltaUnit.kelvin,
        ),
        closeTo(5.0, 1e-9),
      );
    });
  });

  group('PressureConverter', () {
    test('identity', () {
      for (final u in PressureUnit.values) {
        expect(PressureConverter.convert(1.0, u, u), closeTo(1.0, 1e-9));
      }
    });

    test('PSI <-> Bar', () {
      expect(
        PressureConverter.convert(
          14.5037738,
          PressureUnit.psi,
          PressureUnit.bar,
        ),
        closeTo(1.0, 1e-4),
      );
      expect(
        PressureConverter.convert(1.0, PressureUnit.bar, PressureUnit.psi),
        closeTo(14.5037738, 1e-4),
      );
    });

    test('kPa <-> Bar', () {
      expect(
        PressureConverter.convert(100.0, PressureUnit.kpa, PressureUnit.bar),
        closeTo(1.0, 1e-6),
      );
      expect(
        PressureConverter.convert(1.0, PressureUnit.bar, PressureUnit.kpa),
        closeTo(100.0, 1e-6),
      );
    });

    test('MPa <-> Bar', () {
      expect(
        PressureConverter.convert(0.1, PressureUnit.mpa, PressureUnit.bar),
        closeTo(1.0, 1e-6),
      );
      expect(
        PressureConverter.convert(1.0, PressureUnit.bar, PressureUnit.mpa),
        closeTo(0.1, 1e-6),
      );
    });

    test('inHg (inches mercury)', () {
      // 1 inHg ≈ 3386.39 Pa
      expect(
        PressureConverter.convert(1.0, PressureUnit.inhg, PressureUnit.pa),
        closeTo(3386.39, 1e-2),
      );
      expect(
        PressureConverter.convert(1.0, PressureUnit.pa, PressureUnit.inhg),
        closeTo(1 / 3386.39, 1e-7),
      );
    });

    test('mmHg (torr)', () {
      // 1 mmHg = 133.322 Pa
      expect(
        PressureConverter.convert(1.0, PressureUnit.mmhg, PressureUnit.pa),
        closeTo(133.322, 1e-3),
      );
      expect(
        PressureConverter.convert(1.0, PressureUnit.pa, PressureUnit.mmhg),
        closeTo(1 / 133.322, 1e-7),
      );
    });

    test('inH2O (inches water)', () {
      // 1 inH2O ≈ 249.089 Pa
      expect(
        PressureConverter.convert(1.0, PressureUnit.inh2o, PressureUnit.pa),
        closeTo(249.089, 1e-3),
      );
    });

    test('negative and zero', () {
      expect(
        PressureConverter.convert(-101.325, PressureUnit.kpa, PressureUnit.bar),
        closeTo(-1.01325, 1e-6),
      );
      expect(
        PressureConverter.convert(0.0, PressureUnit.psi, PressureUnit.bar),
        0.0,
      );
    });

    test('common list non-empty', () {
      expect(PressureConverter.common.isNotEmpty, true);
      for (final u in PressureConverter.common) {
        expect(PressureConverter.label(u).isNotEmpty, true);
      }
    });

    test('all units have descriptions', () {
      for (final u in PressureUnit.values) {
        expect(PressureConverter.description(u).isNotEmpty, true);
      }
    });
  });
}
