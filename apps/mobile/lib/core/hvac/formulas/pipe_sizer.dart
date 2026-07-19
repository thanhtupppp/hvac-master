import 'dart:math';

class PipeSizerResult {
  final double recommendedDiameterMm;
  final double velocityMs;
  final double frictionLossPaPerM;
  final String pipeSchedule;

  const PipeSizerResult({
    required this.recommendedDiameterMm,
    required this.velocityMs,
    required this.frictionLossPaPerM,
    required this.pipeSchedule,
  });
}

class PipeSizer {
  static const double _rho = 998;
  static const double _mu = 0.001002;

  static List<double> get standardSizes => [
    15, 20, 25, 32, 40, 50, 65, 80, 100, 125, 150, 200, 250, 300
  ];

  static List<double> get copperSizes => [
    15, 22, 28, 35, 42, 54, 67, 76, 108, 133, 159
  ];

  static PipeSizerResult size({
    required double flowRateLs,
    required double maxVelocityMs,
    List<double>? availableSizes,
    bool useCopper = false,
  }) {
    final sizes = availableSizes ?? (useCopper ? copperSizes : standardSizes);

    double bestSize = sizes.first;
    double bestVelocity = 0;
    double bestFriction = double.infinity;

    for (final dMm in sizes) {
      final area = pi * pow(dMm / 1000, 2) / 4;
      if (area <= 0) continue;
      final vel = flowRateLs / 1000 / area;
      if (vel > maxVelocityMs) continue;
      final re = _reynolds(vel, dMm);
      final f = _frictionFactor(re, 0.0015, dMm);
      final friction = f * _rho * vel * vel / (2 * dMm / 1000);
      if (friction < bestFriction) {
        bestFriction = friction;
        bestSize = dMm;
        bestVelocity = vel;
      }
    }

    return PipeSizerResult(
      recommendedDiameterMm: bestSize,
      velocityMs: bestVelocity,
      frictionLossPaPerM: bestFriction,
      pipeSchedule: useCopper ? 'Type L' : 'Schedule 40',
    );
  }

  static double _reynolds(double velocityMs, double diameterMm) {
    if (diameterMm <= 0) return 0;
    return velocityMs * diameterMm / 1000 / (_mu / _rho);
  }

  static double _frictionFactor(double re, double roughnessMm, double diameterMm) {
    if (re <= 0 || diameterMm <= 0) return 0;
    if (re < 2300) return 64 / re;
    final e = roughnessMm / diameterMm;
    return 0.25 / pow(log(e / 3.7 + 5.74 / pow(re, 0.9)) / log(10), 2);
  }
}
