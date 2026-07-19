import 'dart:math';
import 'antoine_database.dart';
import 'pressure_conversion.dart';

class ThermoService {
  static bool hasAntoine(String refrigerant) {
    final key = _normalizeKey(refrigerant);
    return antoineDatabase.containsKey(key);
  }

  static double? getPressureFromTemp({
    required String refrigerant,
    required double tempCelsius,
    required String pressureUnit,
    required bool isGauge,
    bool isDew = false,
    double atmosphericPressure = 1.01325,
  }) {
    final key = _normalizeKey(refrigerant);
    final coefsMap = antoineDatabase[key];
    if (coefsMap == null) return null;

    final coef = isDew ? coefsMap['dew']! : coefsMap['bubble']!;

    if (tempCelsius < coef.tMin || tempCelsius > coef.tMax) {
      return null;
    }

    final double lnP = coef.a1 + (coef.a2 / (tempCelsius + coef.a3));
    final double barAbs = exp(lnP);

    return fromBarAbs(barAbs, pressureUnit, isGauge, atmosphericPressure);
  }

  static double? getTempFromPressure({
    required String refrigerant,
    required double pressure,
    required String pressureUnit,
    required bool isGauge,
    bool isDew = false,
    double atmosphericPressure = 1.01325,
  }) {
    final key = _normalizeKey(refrigerant);
    final coefsMap = antoineDatabase[key];
    if (coefsMap == null) return null;

    final coef = isDew ? coefsMap['dew']! : coefsMap['bubble']!;
    final double barAbs = toBarAbs(
      pressure,
      pressureUnit,
      isGauge,
      atmosphericPressure,
    );
    if (barAbs <= 0) return null;

    final double lnP = log(barAbs);
    final double tempCelsius = coef.a2 / (lnP - coef.a1) - coef.a3;

    if (tempCelsius < coef.tMin || tempCelsius > coef.tMax) {
      return null;
    }

    return tempCelsius;
  }

  static String _normalizeKey(String name) {
    final key = name.trim().toUpperCase();
    if (key.contains('ETHYLENE')) return 'R1150';
    if (key.contains('R1233ZD')) return 'R1233zd';
    if (key.contains('R1234ZE')) return 'R1234ze';
    if (key.contains('R1234YF')) return 'R1234yf';
    if (key == 'R134A') return 'R134a';
    if (key == 'R410A') return 'R410A';
    if (key == 'R404A') return 'R404A';
    return key;
  }
}
