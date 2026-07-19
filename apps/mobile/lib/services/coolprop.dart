import '../core/hvac/thermo/thermo.dart';

export '../core/hvac/thermo/thermo.dart';

final _instance = Thermodynamics();

@Deprecated('Use Thermodynamics from core/hvac/thermo/thermo.dart')
class CoolProp {
  static String gaugeType = 'Khô';
  static bool useBarometer = false;
  static double elevation = 100.0;

  static double getAtmosphericPressure() => _instance.getAtmosphericPressure();

  static double getTempFromPressure({
    required String refrigerant,
    required double pressure,
    required String pressureUnit,
    required bool isGauge,
    bool isDew = false,
  }) => _instance.getTempFromPressure(
    refrigerant: refrigerant,
    pressure: pressure,
    pressureUnit: pressureUnit,
    isGauge: isGauge,
    isDew: isDew,
  );

  static double getPressureFromTemp({
    required String refrigerant,
    required double tempCelsius,
    required String pressureUnit,
    required bool isGauge,
    bool isDew = false,
  }) => _instance.getPressureFromTemp(
    refrigerant: refrigerant,
    tempCelsius: tempCelsius,
    pressureUnit: pressureUnit,
    isGauge: isGauge,
    isDew: isDew,
  );

  static double toBarAbs(double val, String unit, bool isGauge) {
    double barAbs = val;
    if (unit == 'PSI') {
      barAbs = val / 14.5037738;
    } else if (unit == 'kPa') {
      barAbs = val / 100.0;
    }
    if (isGauge) {
      barAbs += getAtmosphericPressure();
    }
    return barAbs;
  }

  static double fromBarAbs(double barAbs, String unit, bool isGauge) {
    double target = barAbs;
    if (isGauge) {
      target -= getAtmosphericPressure();
    }
    if (unit == 'PSI') {
      target *= 14.5037738;
    } else if (unit == 'kPa') {
      target *= 100.0;
    }
    return target;
  }

  static double toPascalAbs(double val, String unit, bool isGauge) {
    double paAbs = val;
    if (unit == 'PSI') {
      paAbs = val * 6894.75729;
    } else if (unit == 'Bar') {
      paAbs = val * 100000.0;
    } else if (unit == 'kPa') {
      paAbs = val * 1000.0;
    }
    if (isGauge) {
      paAbs += getAtmosphericPressure() * 100000.0;
    }
    return paAbs;
  }

  static double fromPascalAbs(double paAbs, String unit, bool isGauge) {
    double target = paAbs;
    if (isGauge) {
      target -= getAtmosphericPressure() * 100000.0;
    }
    if (unit == 'PSI') {
      target /= 6894.75729;
    } else if (unit == 'Bar') {
      target /= 100000.0;
    } else if (unit == 'kPa') {
      target /= 1000.0;
    }
    return target;
  }

  static double convertPressure(double val, String from, String to) {
    if (from == to) return val;
    double bar = val;
    if (from == 'PSI') {
      bar = val / 14.5037738;
    } else if (from == 'kPa') {
      bar = val / 100.0;
    } else if (from == 'MPa') {
      bar = val * 10.0;
    }
    if (to == 'Bar') return bar;
    if (to == 'PSI') return bar * 14.5037738;
    if (to == 'kPa') return bar * 100.0;
    if (to == 'MPa') return bar / 10.0;
    return val;
  }

  static double convertTemperature(double val, String from, String to) {
    if (from == to) return val;
    double celsius = val;
    if (from == '°F') {
      celsius = (val - 32) * 5 / 9;
    } else if (from == 'K') {
      celsius = val - 273.15;
    }
    if (to == '°C') return celsius;
    if (to == '°F') return (celsius * 9 / 5) + 32;
    if (to == 'K') return celsius + 273.15;
    return val;
  }

  static double convertPower(double val, String from, String to) {
    if (from == to) return val;
    double btuHr = val;
    if (from == 'HP') {
      btuHr = val * 9000;
    } else if (from == 'kW') {
      btuHr = val * 3412.142;
    } else if (from == 'Tons') {
      btuHr = val * 12000;
    }
    if (to == 'BTU/h') return btuHr;
    if (to == 'HP') return btuHr / 9000;
    if (to == 'kW') return btuHr / 3412.142;
    if (to == 'Tons') return btuHr / 12000;
    return val;
  }

  static double calculateDuctDiameter(double cfm, double frictionRate) {
    if (cfm <= 0 || frictionRate <= 0) return 0.0;
    return 2.42 * _pow(cfm, 0.375) / _pow(frictionRate, 0.1875);
  }

  static double calculateRectangularSideB(double roundDiameter, double sideA) {
    if (roundDiameter <= 0 || sideA <= 0) return 0.0;
    double b = roundDiameter;
    for (int i = 0; i < 20; i++) {
      final double currentD =
          1.30 * _pow(sideA * b, 0.625) / _pow(sideA + b, 0.25);
      final double diff = currentD - roundDiameter;
      if (diff.abs() < 0.01) break;
      b -= diff * 0.5;
      if (b <= 0) b = 0.1;
    }
    return b;
  }
}

double _pow(double base, double exponent) {
  return base <= 0
      ? 0.0
      : base > 0
      ? _exp(exponent * _ln(base))
      : 0.0;
}

double _exp(double x) {
  double sum = 1.0;
  double term = 1.0;
  for (int i = 1; i <= 100; i++) {
    term *= x / i;
    sum += term;
    if (term.abs() < 1e-15) break;
  }
  return sum;
}

double _ln(double x) {
  if (x <= 0) return double.negativeInfinity;
  double y = (x - 1) / (x + 1);
  double sum = 0.0;
  double term = y;
  for (int i = 1; i <= 200; i += 2) {
    sum += term / i;
    term *= y * y;
  }
  return 2 * sum;
}
