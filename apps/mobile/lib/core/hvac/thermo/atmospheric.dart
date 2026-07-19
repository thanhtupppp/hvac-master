import 'dart:math';

enum GaugeType {
  dry,
  liquidFilled;

  String get label {
    switch (this) {
      case GaugeType.dry:
        return 'Khô';
      case GaugeType.liquidFilled:
        return 'Đầy chất lỏng';
    }
  }

  static GaugeType fromString(String label) {
    if (label == 'Đầy chất lỏng' || label == 'liquidFilled') {
      return GaugeType.liquidFilled;
    }
    return GaugeType.dry;
  }
}

class AtmosphericSettings {
  GaugeType gaugeType;
  bool useBarometer;
  double elevationMeters;

  AtmosphericSettings({
    this.gaugeType = GaugeType.dry,
    this.useBarometer = false,
    this.elevationMeters = 100.0,
  });

  double get pressureBar {
    if (gaugeType == GaugeType.liquidFilled) {
      return 1.01325;
    }
    if (useBarometer) {
      return 1.01325;
    }
    return 1.01325 * pow(1.0 - 2.25577e-5 * elevationMeters, 5.25588);
  }
}
