class FanDutyPoint {
  final double airflowLs;
  final double totalPressurePa;
  final double powerW;
  final double efficiency;
  final String classification;

  const FanDutyPoint({
    required this.airflowLs,
    required this.totalPressurePa,
    required this.powerW,
    required this.efficiency,
    required this.classification,
  });
}

class FanSelection {
  static const Map<String, Map<String, double>> _fanTypes = {
    'centrifugal_forward': {
      'maxEfficiency': 0.75,
      'powerFactor': 1.15,
      'maxSpeed': 25,
    },
    'centrifugal_backward': {
      'maxEfficiency': 0.82,
      'powerFactor': 1.10,
      'maxSpeed': 30,
    },
    'axial': {
      'maxEfficiency': 0.70,
      'powerFactor': 1.20,
      'maxSpeed': 20,
    },
    'vane_axial': {
      'maxEfficiency': 0.78,
      'powerFactor': 1.12,
      'maxSpeed': 25,
    },
  };

  static FanDutyPoint select({
    required double airflowLs,
    required double totalPressurePa,
    required String fanType,
  }) {
    final spec = _fanTypes[fanType] ?? _fanTypes['centrifugal_forward']!;
    final airflow = airflowLs / 1000;
    final fanPower = (airflow * totalPressurePa) / (spec['maxEfficiency']! * spec['powerFactor']!);

    return FanDutyPoint(
      airflowLs: airflowLs,
      totalPressurePa: totalPressurePa,
      powerW: fanPower,
      efficiency: spec['maxEfficiency']!,
      classification: _classify(airflowLs, totalPressurePa),
    );
  }

  static String _classify(double airflowLs, double totalPressurePa) {
    final sp = totalPressurePa / 1000;
    if (sp < 0.5) return 'Low pressure (< 500 Pa)';
    if (sp < 1.5) return 'Medium pressure (500–1500 Pa)';
    if (sp < 3.0) return 'High pressure (1500–3000 Pa)';
    return 'Very high pressure (> 3000 Pa)';
  }

  static List<String> get availableTypes => _fanTypes.keys.toList();
}
