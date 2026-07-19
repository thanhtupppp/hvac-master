import 'dart:math';

class DuctPressureLossResult {
  final double frictionLossPaPerM;
  final double frictionLossInWgPer100ft;
  final double reynoldsNumber;
  final double darcyFrictionFactor;
  final double velocityMs;

  DuctPressureLossResult({
    required this.frictionLossPaPerM,
    required double frictionLossInWgPerM,
    required this.reynoldsNumber,
    required this.darcyFrictionFactor,
    required this.velocityMs,
  }) : frictionLossInWgPer100ft = frictionLossInWgPerM * 304.8;
}

class DuctPressureLoss {
  static const double _rho = 1.2;
  static const double _mu = 1.81e-5;

  static DuctPressureLossResult calculate({
    required double flowRateLs,
    required double ductDiameterMm,
    required double roughnessMm,
    required double lengthM,
  }) {
    final area = _area(ductDiameterMm);
    if (area <= 0) return _zeroResult();

    final velocityMs = flowRateLs / area;
    final reynolds = _reynolds(velocityMs, ductDiameterMm);
    final f = _frictionFactor(reynolds, roughnessMm, ductDiameterMm);
    final frictionPaPerM = f * _rho * velocityMs * velocityMs / (2 * ductDiameterMm / 1000);

    return DuctPressureLossResult(
      frictionLossPaPerM: frictionPaPerM,
      frictionLossInWgPerM: frictionPaPerM * 0.00401865,
      reynoldsNumber: reynolds,
      darcyFrictionFactor: f,
      velocityMs: velocityMs,
    );
  }

  static double _area(double diameterMm) {
    if (diameterMm <= 0) return 0;
    final d = diameterMm / 1000;
    return pi * d * d / 4;
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

  static DuctPressureLossResult _zeroResult() => DuctPressureLossResult(
    frictionLossPaPerM: 0,
    frictionLossInWgPerM: 0,
    reynoldsNumber: 0,
    darcyFrictionFactor: 0,
    velocityMs: 0,
  );
}

class FittingLoss {
  static double totalLoss({
    required double velocityMs,
    required List<double> lossCoefficients,
  }) {
    if (lossCoefficients.isEmpty) return 0;
    final sum = lossCoefficients.reduce((a, b) => a + b);
    return 0.5 * 1.2 * velocityMs * velocityMs * sum;
  }
}
