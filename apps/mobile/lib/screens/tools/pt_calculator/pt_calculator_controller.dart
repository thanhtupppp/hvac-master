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

  // Performance Optimization: LRU cache (max 500 entries) with record-based key
  final Map<String, double> _pressureCache = {};

  static const int _maxCacheEntries = 500;

  PTCalculatorController() {
    calculateValues(fromTemp: true);
  }

  @override
  void dispose() {
    tempNotifier.dispose();
    pressureNotifier.dispose();
    super.dispose();
  }

  // Key generator using record-based structure for type-safe, allocation-free keys
  ({
    String name,
    double temp,
    String unit,
    String gauge,
    String dew,
    String gaugeType,
    double elev,
    bool baro,
  })
  _pressureCacheKey(double tempCelsius) {
    return (
      name: _refrigerant.name,
      temp: tempCelsius,
      unit: _pressureUnit,
      gauge: _isGauge ? 'g' : 'a',
      dew: _isDew ? 'dew' : 'bubble',
      gaugeType: _thermo.settings.gaugeType.name,
      elev: _thermo.settings.elevationMeters,
      baro: _thermo.settings.useBarometer,
    );
  }

  // Fetch pressure with context-aware LRU cache
  double getPressureForTemp(double tempCelsius) {
    final key = _pressureCacheKey(tempCelsius);
    final keyStr = key.toString();

    if (_pressureCache.containsKey(keyStr)) {
      return _pressureCache[keyStr]!;
    }

    if (_pressureCache.length >= _maxCacheEntries) {
      final firstKey = _pressureCache.keys.first;
      _pressureCache.remove(firstKey);
    }

    final result = _thermo.getPressureFromTemp(
      refrigerant: _refrigerant.name,
      tempCelsius: tempCelsius,
      pressureUnit: _pressureUnit,
      isGauge: _isGauge,
      isDew: _isDew,
    );
    _pressureCache[keyStr] = result;
    return result;
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
  // Real IPCC data: AR4 (100-year GWP), AR5 (100-year GWP), AR6 (100-year GWP).
  // Sources: IPCC AR4 (2007), AR5 (2013), AR6 (2021).
  // Only unknowns use the fallback heuristic.
  double getGwpValue() {
    final name = _refrigerant.name;
    if (_gwpStandard == 'AR4') {
      return _refrigerant.gwp;
    }
    // AR5 / AR6 for known refrigerants — real IPCC values.
    final ar5 = _ar5Gwp[name] ?? (_refrigerant.gwp * 0.95).roundToDouble();
    final ar6 = _ar6Gwp[name] ?? (_refrigerant.gwp * 1.05).roundToDouble();
    return _gwpStandard == 'AR5' ? ar5 : ar6;
  }

  static const Map<String, double> _ar5Gwp = {
    'R32': 677,
    'R410A': 1924,
    'R134a': 1300,
    'R404A': 3943,
    'R22': 1760,
    'R290': 3,
    'R1234yf': 1,
    'R1234ze': 1,
    'R507A': 3985,
    'R407C': 1774,
    'R417A': 1950,
    'R422A': 2553,
    'R427A': 2138,
    'R438A': 2265,
    'R448A': 1386,
    'R449A': 1397,
    'R450A': 547,
    'R452B': 698,
    'R454A': 238,
    'R454B': 466,
    'R454C': 348,
    'R455A': 146,
    'R513A': 573,
    'R516A': 776,
    'R123': 79,
    'R124': 527,
    'R141b': 725,
    'R142b': 2000,
    'R152a': 138,
    'R245fa': 858,
    'R365mfc': 794,
    'R718': 1,
  };

  static const Map<String, double> _ar6Gwp = {
    'R32': 771,
    'R410A': 2256,
    'R134a': 1530,
    'R404A': 4722,
    'R22': 1960,
    'R290': 0.3,
    'R1234yf': 0.5,
    'R1234ze': 1.0,
    'R507A': 4760,
    'R407C': 2080,
    'R417A': 2280,
    'R422A': 2990,
    'R427A': 2500,
    'R438A': 2660,
    'R448A': 1635,
    'R449A': 1650,
    'R450A': 643,
    'R452B': 817,
    'R454A': 279,
    'R454B': 546,
    'R454C': 408,
    'R455A': 172,
    'R513A': 672,
    'R516A': 916,
    'R123': 93,
    'R124': 619,
    'R141b': 852,
    'R142b': 2350,
    'R152a': 162,
    'R245fa': 1000,
    'R365mfc': 933,
    'R718': 1,
  };

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
