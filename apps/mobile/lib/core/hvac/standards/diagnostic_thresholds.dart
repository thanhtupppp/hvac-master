/// HVAC diagnostic thresholds for superheat and subcooling analysis.
///
/// Sources:
/// - Superheat: ACCA Manual Q (Section 5), manufacturer datasheets (typically 8–12°F/4–7K total SH for residential TXV).
/// - Subcooling: ACCA Manual Q (typically 8–12°F/4–7K for properly charged systems).
///
/// Thresholds are stored in Kelvin internally and converted when displaying °F.
class DiagnosticThresholds {
  DiagnosticThresholds._();

  // Superheat thresholds (in Kelvin)
  static const double superheatLowK = 2.0;
  static const double superheatHighK = 8.0;
  static const double superheatTargetK = 5.0;

  // Subcooling thresholds (in Kelvin)
  static const double subcoolingLowK = 3.0;
  static const double subcoolingHighK = 15.0;
  static const double subcoolingTargetK = 8.0;

  // Conversion factor
  static const double kToF = 1.8;

  // Superheat in Fahrenheit
  static const double superheatLowF = superheatLowK * kToF;
  static const double superheatHighF = superheatHighK * kToF;
  static const double superheatTargetF = superheatTargetK * kToF;

  // Subcooling in Fahrenheit
  static const double subcoolingLowF = subcoolingLowK * kToF;
  static const double subcoolingHighF = subcoolingHighK * kToF;
  static const double subcoolingTargetF = subcoolingTargetK * kToF;

  // Conversion helpers
  static double kToFVal(double kelvin) => kelvin * kToF;
  static double fToK(double fahrenheit) => fahrenheit / kToF;
}
