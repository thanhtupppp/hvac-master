import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:ffi/ffi.dart';

class RefrigerantCoefficients {
  final double a1;
  final double a2;
  final double a3;

  const RefrigerantCoefficients(this.a1, this.a2, this.a3);
}

typedef PropsSINative = Double Function(
  Pointer<Utf8> output,
  Pointer<Utf8> name1,
  Double prop1,
  Pointer<Utf8> name2,
  Double prop2,
  Pointer<Utf8> fluid,
);

typedef PropsSIDart = double Function(
  Pointer<Utf8> output,
  Pointer<Utf8> name1,
  double prop1,
  Pointer<Utf8> name2,
  double prop2,
  Pointer<Utf8> fluid,
);

class CoolProp {
  static PropsSIDart? _propsSI;
  static bool _ffiFailed = false;

  // Danfoss Antoine coefficients (T in °C, P_abs in Bar)
  // We define Bubble and Dew coefficients for blends with glide (like R404A, R410A)
  static const Map<String, Map<String, RefrigerantCoefficients>> _antoineData = {
    'R22': {
      'bubble': RefrigerantCoefficients(9.748, -2017.2, 247.8),
      'dew': RefrigerantCoefficients(9.748, -2017.2, 247.8),
    },
    'R32': {
      'bubble': RefrigerantCoefficients(10.271, -2059.6, 252.1),
      'dew': RefrigerantCoefficients(10.271, -2059.6, 252.1),
    },
    'R134a': {
      'bubble': RefrigerantCoefficients(9.936, -2147.9, 242.3),
      'dew': RefrigerantCoefficients(9.936, -2147.9, 242.3),
    },
    'R410A': {
      'bubble': RefrigerantCoefficients(10.052, -1972.1, 247.0),
      'dew': RefrigerantCoefficients(10.048, -1972.1, 247.0), // Near-azeotropic glide
    },
    'R404A': {
      'bubble': RefrigerantCoefficients(10.022, -1880.8, 242.4), // Bubble point
      'dew': RefrigerantCoefficients(9.992, -1880.8, 242.4),    // Dew point
    },
  };

  // Safe initialization of FFI
  static void _initFFI() {
    if (_propsSI != null || _ffiFailed) return;
    try {
      final DynamicLibrary dylib = Platform.isAndroid
          ? DynamicLibrary.open('libCoolProp.so')
          : DynamicLibrary.process();
      
      _propsSI = dylib.lookupFunction<PropsSINative, PropsSIDart>('PropsSI');
    } catch (e) {
      _ffiFailed = true;
    }
  }

  // 1. Core calculation method: get saturation temperature
  static double getTempFromPressure({
    required String refrigerant,
    required double pressure,
    required String pressureUnit,
    required bool isGauge,
    bool isDew = false,
  }) {
    _initFFI();

    // If FFI is available, use it!
    if (_propsSI != null) {
      try {
        final double pAbsPa = toPascalAbs(pressure, pressureUnit, isGauge);
        final String fluidName = _mapFluidToCoolProp(refrigerant);
        final String outputParam = 'T';
        final String inputParam1 = 'P';
        final double inputVal1 = pAbsPa;
        final String inputParam2 = 'Q';
        final double inputVal2 = isDew ? 1.0 : 0.0; // Q=0 for Bubble (liquid), Q=1 for Dew (vapor)

        final pOutput = outputParam.toNativeUtf8();
        final pName1 = inputParam1.toNativeUtf8();
        final pName2 = inputParam2.toNativeUtf8();
        final pFluid = fluidName.toNativeUtf8();
        
        try {
          final tempK = _propsSI!(pOutput, pName1, inputVal1, pName2, inputVal2, pFluid);
          if (tempK > 0) {
            return tempK - 273.15; // convert Kelvin to Celsius
          }
        } finally {
          malloc.free(pOutput);
          malloc.free(pName1);
          malloc.free(pName2);
          malloc.free(pFluid);
        }
      } catch (e) {
        // Fallback on FFI runtime error
      }
    }

    // Fallback: Dart implementation using Antoine equation
    final double barAbs = toBarAbs(pressure, pressureUnit, isGauge);
    if (barAbs <= 0) return -273.15;

    // Normalize refrigerant name for keys
    final key = refrigerant.contains('Ethylene') ? 'R1150' : refrigerant;
    final coefs = _antoineData[key] ?? _antoineData['R32']!;
    final coef = isDew ? coefs['dew']! : coefs['bubble']!;

    final double lnP = log(barAbs);
    final double tempCelsius = coef.a2 / (lnP - coef.a1) - coef.a3;
    return tempCelsius;
  }

  // 2. Core calculation method: get saturation pressure
  static double getPressureFromTemp({
    required String refrigerant,
    required double tempCelsius,
    required String pressureUnit,
    required bool isGauge,
    bool isDew = false,
  }) {
    _initFFI();

    // If FFI is available, use it!
    if (_propsSI != null) {
      try {
        final double tempK = tempCelsius + 273.15;
        final String fluidName = _mapFluidToCoolProp(refrigerant);
        final String outputParam = 'P';
        final String inputParam1 = 'T';
        final double inputVal1 = tempK;
        final String inputParam2 = 'Q';
        final double inputVal2 = isDew ? 1.0 : 0.0;

        final pOutput = outputParam.toNativeUtf8();
        final pName1 = inputParam1.toNativeUtf8();
        final pName2 = inputParam2.toNativeUtf8();
        final pFluid = fluidName.toNativeUtf8();

        try {
          final pressurePa = _propsSI!(pOutput, pName1, inputVal1, pName2, inputVal2, pFluid);
          if (pressurePa > 0) {
            return fromPascalAbs(pressurePa, pressureUnit, isGauge);
          }
        } finally {
          malloc.free(pOutput);
          malloc.free(pName1);
          malloc.free(pName2);
          malloc.free(pFluid);
        }
      } catch (e) {
        // Fallback on FFI runtime error
      }
    }

    // Fallback: Dart implementation
    final key = refrigerant.contains('Ethylene') ? 'R1150' : refrigerant;
    final coefs = _antoineData[key] ?? _antoineData['R32']!;
    final coef = isDew ? coefs['dew']! : coefs['bubble']!;

    final double lnP = coef.a1 + (coef.a2 / (tempCelsius + coef.a3));
    final double barAbs = exp(lnP);

    return fromBarAbs(barAbs, pressureUnit, isGauge);
  }

  // Map user-friendly name to CoolProp fluid name
  static String _mapFluidToCoolProp(String name) {
    if (name.contains('Ethylene')) return 'Ethylene';
    // CoolProp supports standard names like R32, R134a, R410A, R404A, R22
    return name;
  }

  // Convert pressure to Bar absolute
  static double toBarAbs(double val, String unit, bool isGauge) {
    double barAbs = val;
    if (unit == 'PSI') {
      barAbs = val / 14.5037738;
    } else if (unit == 'kPa') {
      barAbs = val / 100.0;
    }
    
    if (isGauge) {
      barAbs += 1.01325; // add 1 atm
    }
    return barAbs;
  }

  // Convert Bar absolute to target pressure unit
  static double fromBarAbs(double barAbs, String unit, bool isGauge) {
    double target = barAbs;
    if (isGauge) {
      target -= 1.01325; // subtract 1 atm
    }

    if (unit == 'PSI') {
      target *= 14.5037738;
    } else if (unit == 'kPa') {
      target *= 100.0;
    }
    return target;
  }

  // Convert pressure to Pascal absolute (for native CoolProp PropsSI)
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
      paAbs += 101325.0; // add 1 atm in Pa
    }
    return paAbs;
  }

  // Convert Pascal absolute to target unit
  static double fromPascalAbs(double paAbs, String unit, bool isGauge) {
    double target = paAbs;
    if (isGauge) {
      target -= 101325.0; // subtract 1 atm
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

  // General Temperature Unit Conversion
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

  // General Power Unit Conversion
  static double convertPower(double val, String from, String to) {
    if (from == to) return val;
    double btuHr = val;
    if (from == 'HP') {
      btuHr = val * 9000; // 1 HP (AC cooling) ≈ 9000 BTU/h
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

  // Duct sizing (Equal Friction Method)
  // Calculates round duct diameter in inches
  static double calculateDuctDiameter(double cfm, double frictionRate) {
    if (cfm <= 0 || frictionRate <= 0) return 0.0;
    return 2.42 * pow(cfm, 0.375) / pow(frictionRate, 0.1875);
  }

  // Calculates rectangular duct equivalent side b (inches) from equivalent round diameter d (inches) and side a (inches)
  static double calculateRectangularSideB(double roundDiameter, double sideA) {
    if (roundDiameter <= 0 || sideA <= 0) return 0.0;
    double b = roundDiameter; // Initial guess
    for (int i = 0; i < 20; i++) {
      final double currentD = 1.30 * pow(sideA * b, 0.625) / pow(sideA + b, 0.25);
      final double diff = currentD - roundDiameter;
      if (diff.abs() < 0.01) break;
      b -= diff * 0.5;
      if (b <= 0) b = 0.1;
    }
    return b;
  }
}
