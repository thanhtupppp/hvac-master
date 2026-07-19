import 'package:flutter/material.dart';
import '../../../core/hvac/thermo/thermo.dart';
import '../../../models/refrigerant_model.dart';

class PTCalculatorPanelData {
  final String refrigerantName;
  final String safetyGroup;
  final String gwpLabel;
  final String gwpValue;
  final String odpValue;
  final String criticalTempText;
  final String boilingPointText;
  final bool isDew;
  final bool isGauge;
  final Color accentColor;

  const PTCalculatorPanelData({
    required this.refrigerantName,
    required this.safetyGroup,
    required this.gwpLabel,
    required this.gwpValue,
    required this.odpValue,
    required this.criticalTempText,
    required this.boilingPointText,
    required this.isDew,
    required this.isGauge,
    required this.accentColor,
  });
}

class PTCalculatorController extends ChangeNotifier {
  final Thermodynamics _thermo = Thermodynamics();

  // State variables
  RefrigerantModel _refrigerant = defaultRefrigerants.first;
  bool _isDew = false;
  bool _isGauge = false;
  String _pressureUnit = 'Bar';
  String _tempUnit = '°C';
  String _distanceUnit = 'm';
  String _gwpStandard = 'AR4';
  bool _reverseSlider = false;

  RefrigerantModel get refrigerant => _refrigerant;
  bool get isDew => _isDew;
  bool get isGauge => _isGauge;
  String get pressureUnit => _pressureUnit;
  String get tempUnit => _tempUnit;
  String get distanceUnit => _distanceUnit;
  String get gwpStandard => _gwpStandard;
  bool get reverseSlider => _reverseSlider;
  String get tempUnitLabel => _tempUnit;
  String get pressureUnitLabel =>
      '${_pressureUnit.toLowerCase()} (${_isGauge ? 'g' : 'a'})';
  PTCalculatorPanelData get panelData {
    return PTCalculatorPanelData(
      refrigerantName: _refrigerant.name,
      safetyGroup: _refrigerant.safetyGroup,
      gwpLabel: 'GWP-$_gwpStandard',
      gwpValue: getGwpValue().toInt().toString(),
      odpValue: _refrigerant.odp.toString(),
      criticalTempText:
          '${(_tempUnit == '°C' ? _refrigerant.criticalTemp : (_refrigerant.criticalTemp * 9 / 5) + 32).toStringAsFixed(1)} $_tempUnit',
      boilingPointText:
          '${(_tempUnit == '°C' ? _refrigerant.boilingPoint : (_refrigerant.boilingPoint * 9 / 5) + 32).toStringAsFixed(1)} $_tempUnit',
      isDew: _isDew,
      isGauge: _isGauge,
      accentColor: _refrigerant.color,
    );
  }

  // Performance Optimization: Notifiers for scrolling values to avoid rebuilding ruler/screen
  final ValueNotifier<double> tempNotifier = ValueNotifier(-25.46);
  final ValueNotifier<double> pressureNotifier = ValueNotifier(3.29);

  // Performance Optimization: Dynamic Lazy Caching with context-aware keys
  final Map<String, double> _pressureCache = {};

  PTCalculatorController() {
    calculateValues(fromTemp: true);
  }

  @override
  void dispose() {
    tempNotifier.dispose();
    pressureNotifier.dispose();
    super.dispose();
  }

  // Key generator based on full physical state context to avoid stale calculations
  String _pressureCacheKey(double tempCelsius) {
    return [
      _refrigerant.name,
      tempCelsius.toStringAsFixed(2),
      _pressureUnit,
      _isGauge ? 'g' : 'a',
      _isDew ? 'dew' : 'bubble',
      _thermo.settings.gaugeType.name,
      _thermo.settings.elevationMeters.toStringAsFixed(0),
      _thermo.settings.useBarometer ? 'baro' : 'nobaro',
    ].join('|');
  }

  // Fetch pressure with context-aware lazy cache
  double getPressureForTemp(double tempCelsius) {
    final key = _pressureCacheKey(tempCelsius);
    return _pressureCache.putIfAbsent(key, () {
      return _thermo.getPressureFromTemp(
        refrigerant: _refrigerant.name,
        tempCelsius: tempCelsius,
        pressureUnit: _pressureUnit,
        isGauge: _isGauge,
        isDew: _isDew,
      );
    });
  }

  void invalidateCache() {
    _pressureCache.clear();
  }

  // Config update helper to centralize invalidation, recalculation, and notify logic
  void _applyConfigChange({
    required VoidCallback mutate,
    bool invalidate = false,
    bool recalculate = false,
    bool fromTemp = true,
  }) {
    mutate();
    if (invalidate) invalidateCache();
    if (recalculate) calculateValues(fromTemp: fromTemp);
    notifyListeners();
  }

  // Setters that trigger controller notifyListeners for UI rebuild
  void updateRefrigerant(RefrigerantModel value) {
    if (_refrigerant == value) return;
    _applyConfigChange(
      mutate: () => _refrigerant = value,
      invalidate: true,
      recalculate: true,
    );
  }

  void updateIsDew(bool value) {
    if (_isDew == value) return;
    _applyConfigChange(
      mutate: () => _isDew = value,
      invalidate: true,
      recalculate: true,
    );
  }

  void updateIsGauge(bool value) {
    if (_isGauge == value) return;
    _applyConfigChange(
      mutate: () => _isGauge = value,
      invalidate: true,
      recalculate: true,
    );
  }

  void updatePressureUnit(String value) {
    if (_pressureUnit == value) return;
    _applyConfigChange(
      mutate: () => _pressureUnit = value,
      invalidate: true,
      recalculate: true,
    );
  }

  void updateTempUnit(String value) {
    if (_tempUnit == value) return;
    _applyConfigChange(mutate: () => _tempUnit = value);
  }

  void updateDistanceUnit(String value) {
    if (_distanceUnit == value) return;
    _applyConfigChange(mutate: () => _distanceUnit = value);
  }

  void updateGwpStandard(String value) {
    if (_gwpStandard == value) return;
    _applyConfigChange(mutate: () => _gwpStandard = value);
  }

  void updateReverseSlider(bool value) {
    if (_reverseSlider == value) return;
    _applyConfigChange(mutate: () => _reverseSlider = value);
  }

  // Atmospheric settings getters
  String get gaugeType => _thermo.settings.gaugeType.label;
  bool get useBarometer => _thermo.settings.useBarometer;
  double get elevation => _thermo.settings.elevationMeters;

  // Update and recalculate atmospheric configuration
  void updateAtmosphericSettings({
    required String gaugeType,
    required bool useBarometer,
    required double elevation,
  }) {
    final s = _thermo.settings;
    if (s.gaugeType.label == gaugeType &&
        s.useBarometer == useBarometer &&
        s.elevationMeters == elevation) {
      return;
    }
    _applyConfigChange(
      mutate: () {
        _thermo.settings.gaugeType = GaugeType.fromString(gaugeType);
        _thermo.settings.useBarometer = useBarometer;
        _thermo.settings.elevationMeters = elevation;
      },
      invalidate: true,
      recalculate: true,
    );
  }

  // Calculate matching values
  void calculateValues({required bool fromTemp}) {
    if (fromTemp) {
      pressureNotifier.value = getPressureForTemp(tempNotifier.value);
    } else {
      final tVal = _thermo.getTempFromPressure(
        refrigerant: _refrigerant.name,
        pressure: pressureNotifier.value,
        pressureUnit: _pressureUnit,
        isGauge: _isGauge,
        isDew: _isDew,
      );
      tempNotifier.value = tVal;
    }
  }

  // Dynamic GWP standard resolver
  double getGwpValue() {
    final name = _refrigerant.name;
    if (_gwpStandard == 'AR4') {
      return _refrigerant.gwp;
    }
    if (name == 'R32') {
      return _gwpStandard == 'AR5' ? 677 : 771;
    } else if (name == 'R410A') {
      return _gwpStandard == 'AR5' ? 1924 : 2256;
    } else if (name == 'R134a') {
      return _gwpStandard == 'AR5' ? 1300 : 1530;
    } else if (name == 'R404A') {
      return _gwpStandard == 'AR5' ? 3943 : 4722;
    } else if (name == 'R22') {
      return _gwpStandard == 'AR5' ? 1760 : 1960;
    } else if (name == 'R290') {
      return _gwpStandard == 'AR5' ? 3 : 0.02;
    } else if (name == 'R1234yf') {
      return _gwpStandard == 'AR5' ? 1 : 0.5;
    } else if (name == 'R1234ze' || name.contains('R1234ze')) {
      return _gwpStandard == 'AR5' ? 1 : 1.0;
    }
    return _gwpStandard == 'AR5'
        ? (_refrigerant.gwp * 0.95).roundToDouble()
        : (_refrigerant.gwp * 1.1).roundToDouble();
  }

  String getTempDisplayValue(double celsiusValue) {
    if (celsiusValue.isNaN) return 'N/A';
    final double displayVal = _tempUnit == '°C'
        ? celsiusValue
        : (celsiusValue * 9 / 5) + 32;
    return displayVal.toStringAsFixed(2);
  }

  double? _parseDisplayTempToCelsius(String input) {
    final double? d = double.tryParse(input);
    if (d == null) return null;
    return _tempUnit == '°C' ? d : (d - 32) * 5 / 9;
  }

  double? _parseDisplayPressure(String input) {
    return double.tryParse(input);
  }

  String? validateTempInput(String input) {
    final double? celsius = _parseDisplayTempToCelsius(input);
    if (celsius == null) return 'Định dạng số không hợp lệ';
    if (celsius < -70.0 || celsius > 70.0) {
      return 'Nhiệt độ ngoài phạm vi cho phép (-70°C đến 70°C)';
    }
    return null;
  }

  String? validatePressureInput(String input) {
    final double? d = _parseDisplayPressure(input);
    if (d == null) return 'Định dạng số không hợp lệ';
    if (d <= 0) return 'Áp suất phải lớn hơn 0';
    return null;
  }

  void submitTempInput(String input) {
    final double? celsius = _parseDisplayTempToCelsius(input);
    if (celsius != null) {
      tempNotifier.value = celsius;
      calculateValues(fromTemp: true);
    }
  }

  void submitPressureInput(String input) {
    final double? d = _parseDisplayPressure(input);
    if (d != null && d > 0) {
      pressureNotifier.value = d;
      calculateValues(fromTemp: false);
    }
  }

  String getPressureDisplayValue(double pressureValue) {
    if (pressureValue.isNaN) return 'Siêu tới hạn';
    return pressureValue.toStringAsFixed(2);
  }
}
