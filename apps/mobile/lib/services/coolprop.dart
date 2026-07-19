export '../core/hvac/thermo/thermo.dart';
import '../core/hvac/units/power.dart';

@Deprecated('Use Thermodynamics from core/hvac/thermo/thermo.dart')
class CoolProp {
  static String gaugeType = 'Khô';
  static bool useBarometer = false;
  static double elevation = 100.0;

  static double getAtmosphericPressure() => 1.01325;

  static double getTempFromPressure({
    required String refrigerant,
    required double pressure,
    required String pressureUnit,
    required bool isGauge,
    bool isDew = false,
  }) =>
      _delegateToThermo('getTempFromPressure', args: {
        'refrigerant': refrigerant,
        'pressure': pressure,
        'pressureUnit': pressureUnit,
        'isGauge': isGauge,
        'isDew': isDew,
      });

  static double getPressureFromTemp({
    required String refrigerant,
    required double tempCelsius,
    required String pressureUnit,
    required bool isGauge,
    bool isDew = false,
  }) =>
      _delegateToThermo('getPressureFromTemp', args: {
        'refrigerant': refrigerant,
        'tempCelsius': tempCelsius,
        'pressureUnit': pressureUnit,
        'isGauge': isGauge,
        'isDew': isDew,
      });

  static double _delegateToThermo(String method, {required Map<String, dynamic> args}) {
    throw UnimplementedError('CoolProp.$method is deprecated. Use Thermodynamics from core/hvac/thermo/thermo.dart');
  }

  @Deprecated('Use PressureConverter.convert from core/hvac/units/pressure.dart')
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

  @Deprecated('Use PressureConverter.convert from core/hvac/units/pressure.dart')
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

  @Deprecated('Use PressureConverter.convert from core/hvac/units/pressure.dart')
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

  @Deprecated('Use PressureConverter.convert from core/hvac/units/pressure.dart')
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

  @Deprecated('Use PowerConverter.convert from core/hvac/units/power.dart')
  static double convertPower(double val, String from, String to) {
    final fromUnit = _powerUnitFromString(from);
    final toUnit = _powerUnitFromString(to);
    if (fromUnit == null || toUnit == null) return val;
    return PowerConverter.convert(val, fromUnit, toUnit);
  }

  @Deprecated('Use TemperatureConverter.convert from core/hvac/units/temperature.dart')
  static double convertTemperature(double val, String from, String to) {
    final fromUnit = _tempUnitFromString(from);
    final toUnit = _tempUnitFromString(to);
    if (fromUnit == null || toUnit == null) return val;
    return _tempConvert(val, fromUnit, toUnit);
  }

  @Deprecated('Use PressureConverter.convert from core/hvac/units/pressure.dart')
  static double convertPressure(double val, String from, String to) {
    final fromUnit = _pressureUnitFromString(from);
    final toUnit = _pressureUnitFromString(to);
    if (fromUnit == null || toUnit == null) return val;
    return _pressureConvert(val, fromUnit, toUnit);
  }

  static double calculateDuctDiameter(double cfm, double frictionRate) {
    if (cfm <= 0 || frictionRate <= 0) return 0.0;
    return 2.42 * _pow(cfm, 0.375) / _pow(frictionRate, 0.1875);
  }

  static double calculateRectangularSideB(double roundDiameter, double sideA) {
    if (roundDiameter <= 0 || sideA <= 0) return 0.0;
    double b = roundDiameter;
    for (int i = 0; i < 20; i++) {
      final double currentD = 1.30 * _pow(sideA * b, 0.625) / _pow(sideA + b, 0.25);
      final double diff = currentD - roundDiameter;
      if (diff.abs() < 0.01) break;
      b -= diff * 0.5;
      if (b <= 0) b = 0.1;
    }
    return b;
  }
}

PowerUnit? _powerUnitFromString(String s) {
  switch (s) {
    case 'HP':      return PowerUnit.hp;
    case 'BTU/h':  return PowerUnit.btuHr;
    case 'kW':     return PowerUnit.kw;
    case 'Tons':   return PowerUnit.ton;
    case 'W':      return PowerUnit.w;
    case 'MW':     return PowerUnit.mw;
    case 'kcal/h': return PowerUnit.kcalHr;
    default:       return null;
  }
}

_AmbTempUnit? _tempUnitFromString(String s) {
  switch (s) {
    case '°C': return _AmbTempUnit.celsius;
    case '°F': return _AmbTempUnit.fahrenheit;
    case 'K':  return _AmbTempUnit.kelvin;
    default:   return null;
  }
}

enum _AmbTempUnit { celsius, fahrenheit, kelvin }

double _tempConvert(double value, _AmbTempUnit from, _AmbTempUnit to) {
  if (from == to) return value;
  double celsius;
  switch (from) {
    case _AmbTempUnit.celsius:    celsius = value;
    case _AmbTempUnit.fahrenheit: celsius = (value - 32) * 5 / 9;
    case _AmbTempUnit.kelvin:    celsius = value - 273.15;
  }
  switch (to) {
    case _AmbTempUnit.celsius:    return celsius;
    case _AmbTempUnit.fahrenheit: return (celsius * 9 / 5) + 32;
    case _AmbTempUnit.kelvin:    return celsius + 273.15;
  }
}

_AmbPressureUnit? _pressureUnitFromString(String s) {
  switch (s) {
    case 'Bar':    return _AmbPressureUnit.bar;
    case 'PSI':    return _AmbPressureUnit.psi;
    case 'kPa':    return _AmbPressureUnit.kpa;
    case 'MPa':    return _AmbPressureUnit.mpa;
    case 'Pa':     return _AmbPressureUnit.pa;
    case 'inHg':   return _AmbPressureUnit.inhg;
    case 'mmHg':   return _AmbPressureUnit.mmhg;
    case 'inH₂O':  return _AmbPressureUnit.inh2o;
    default:       return null;
  }
}

enum _AmbPressureUnit { pa, kpa, mpa, bar, psi, inhg, mmhg, inh2o }

const _paPerKpa = 1e3;
const _paPerMpa = 1e6;
const _paPerBar = 1e5;
const _paPerPsi = 6894.75729;
const _paPerInHg = 3386.39;
const _paPerMmHg = 133.322;
const _paPerInH2o = 249.089;

double _pressureConvert(double value, _AmbPressureUnit from, _AmbPressureUnit to) {
  if (from == to) return value;
  double pa;
  switch (from) {
    case _AmbPressureUnit.pa:   pa = value;
    case _AmbPressureUnit.kpa:   pa = value * _paPerKpa;
    case _AmbPressureUnit.mpa:   pa = value * _paPerMpa;
    case _AmbPressureUnit.bar:   pa = value * _paPerBar;
    case _AmbPressureUnit.psi:   pa = value * _paPerPsi;
    case _AmbPressureUnit.inhg:  pa = value * _paPerInHg;
    case _AmbPressureUnit.mmhg: pa = value * _paPerMmHg;
    case _AmbPressureUnit.inh2o: pa = value * _paPerInH2o;
  }
  switch (to) {
    case _AmbPressureUnit.pa:    return pa;
    case _AmbPressureUnit.kpa:    return pa / _paPerKpa;
    case _AmbPressureUnit.mpa:   return pa / _paPerMpa;
    case _AmbPressureUnit.bar:    return pa / _paPerBar;
    case _AmbPressureUnit.psi:    return pa / _paPerPsi;
    case _AmbPressureUnit.inhg:  return pa / _paPerInHg;
    case _AmbPressureUnit.mmhg:  return pa / _paPerMmHg;
    case _AmbPressureUnit.inh2o: return pa / _paPerInH2o;
  }
}

double _pow(double base, double exponent) {
  if (base <= 0) return 0.0;
  return _exp(exponent * _ln(base));
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
