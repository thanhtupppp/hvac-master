import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'atmospheric.dart';
import 'thermo_service.dart';

typedef PropsSINative =
    Double Function(
      Pointer<Utf8> output,
      Pointer<Utf8> name1,
      Double prop1,
      Pointer<Utf8> name2,
      Double prop2,
      Pointer<Utf8> fluid,
    );

typedef PropsSIDart =
    double Function(
      Pointer<Utf8> output,
      Pointer<Utf8> name1,
      double prop1,
      Pointer<Utf8> name2,
      double prop2,
      Pointer<Utf8> fluid,
    );

class Thermodynamics {
  Thermodynamics({AtmosphericSettings? settings})
    : _settings = settings ?? AtmosphericSettings();

  final AtmosphericSettings _settings;
  PropsSIDart? _propsSI;
  bool _ffiFailed = false;

  AtmosphericSettings get settings => _settings;

  double getAtmosphericPressure() => _settings.pressureBar;

  double getTempFromPressure({
    required String refrigerant,
    required double pressure,
    required String pressureUnit,
    required bool isGauge,
    bool isDew = false,
  }) {
    final atm = getAtmosphericPressure();

    final double? antoineVal = ThermoService.getTempFromPressure(
      refrigerant: refrigerant,
      pressure: pressure,
      pressureUnit: pressureUnit,
      isGauge: isGauge,
      isDew: isDew,
      atmosphericPressure: atm,
    );
    if (antoineVal != null) {
      return antoineVal;
    }

    _initFFI();
    if (_propsSI != null) {
      try {
        final double pAbsPa = _toPascalAbs(
          pressure,
          pressureUnit,
          isGauge,
          atm,
        );
        final String fluidName = _mapFluidToCoolProp(refrigerant);

        final pOutput = 'T'.toNativeUtf8();
        final pName1 = 'P'.toNativeUtf8();
        final pName2 = 'Q'.toNativeUtf8();
        final pFluid = fluidName.toNativeUtf8();

        try {
          final tempK = _propsSI!(
            pOutput,
            pName1,
            pAbsPa,
            pName2,
            isDew ? 1.0 : 0.0,
            pFluid,
          );
          if (tempK > 0) {
            return tempK - 273.15;
          }
        } finally {
          malloc.free(pOutput);
          malloc.free(pName1);
          malloc.free(pName2);
          malloc.free(pFluid);
        }
      } catch (e) {
        // FFI runtime error — fall through to NaN
      }
    }

    return double.nan;
  }

  double getPressureFromTemp({
    required String refrigerant,
    required double tempCelsius,
    required String pressureUnit,
    required bool isGauge,
    bool isDew = false,
  }) {
    final atm = getAtmosphericPressure();

    final double? antoineVal = ThermoService.getPressureFromTemp(
      refrigerant: refrigerant,
      tempCelsius: tempCelsius,
      pressureUnit: pressureUnit,
      isGauge: isGauge,
      isDew: isDew,
      atmosphericPressure: atm,
    );
    if (antoineVal != null) {
      return antoineVal;
    }

    _initFFI();
    if (_propsSI != null) {
      try {
        final double tempK = tempCelsius + 273.15;
        final String fluidName = _mapFluidToCoolProp(refrigerant);

        final pOutput = 'P'.toNativeUtf8();
        final pName1 = 'T'.toNativeUtf8();
        final pName2 = 'Q'.toNativeUtf8();
        final pFluid = fluidName.toNativeUtf8();

        try {
          final pressurePa = _propsSI!(
            pOutput,
            pName1,
            tempK,
            pName2,
            isDew ? 1.0 : 0.0,
            pFluid,
          );
          if (pressurePa > 0) {
            return _fromPascalAbs(pressurePa, pressureUnit, isGauge, atm);
          }
        } finally {
          malloc.free(pOutput);
          malloc.free(pName1);
          malloc.free(pName2);
          malloc.free(pFluid);
        }
      } catch (e) {
        // FFI runtime error — fall through to NaN
      }
    }

    return double.nan;
  }

  bool hasAntoine(String refrigerant) => ThermoService.hasAntoine(refrigerant);

  void _initFFI() {
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

  String _mapFluidToCoolProp(String name) {
    if (name.contains('Ethylene')) return 'Ethylene';
    return name;
  }

  double _toPascalAbs(double val, String unit, bool isGauge, double atm) {
    double paAbs = val;
    if (unit == 'PSI') {
      paAbs = val * 6894.75729;
    } else if (unit == 'Bar') {
      paAbs = val * 100000.0;
    } else if (unit == 'kPa') {
      paAbs = val * 1000.0;
    }
    if (isGauge) {
      paAbs += atm * 100000.0;
    }
    return paAbs;
  }

  double _fromPascalAbs(double paAbs, String unit, bool isGauge, double atm) {
    double target = paAbs;
    if (isGauge) {
      target -= atm * 100000.0;
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
}
