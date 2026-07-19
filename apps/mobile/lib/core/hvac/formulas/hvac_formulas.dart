import 'dart:math';

class HvacFormulas {
  static double velocity({required double cfm, required double areaSqFt}) {
    if (areaSqFt <= 0) return 0.0;
    return cfm / areaSqFt;
  }

  static double equivalentDiameter({required double a, required double b}) {
    if (a <= 0 || b <= 0) return 0.0;
    return 1.30 * pow(a * b, 0.625) / pow(a + b, 0.25);
  }

  static double roundDuctDiameter({
    required double cfm,
    required double frictionRateInWgPer100ft,
  }) {
    if (cfm <= 0 || frictionRateInWgPer100ft <= 0) return 0.0;
    return 2.42 * pow(cfm / frictionRateInWgPer100ft, 0.1875);
  }
}
