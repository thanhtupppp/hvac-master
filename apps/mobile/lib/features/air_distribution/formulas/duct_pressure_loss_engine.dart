import 'dart:math';

import '../../../core/hvac/models/enums.dart';
import '../constants/air_distribution_constants.dart';
import '../data/fitting_coefficients.dart';

enum DuctShapeForLoss { round, rectangular }

class DuctRoughness {
  final DuctMaterial material;
  final double absoluteRoughnessFt;
  final double absoluteRoughnessM;

  const DuctRoughness({
    required this.material,
    required this.absoluteRoughnessFt,
    required this.absoluteRoughnessM,
  });

  static const Map<DuctMaterial, DuctRoughness> values = {
    DuctMaterial.galvanized: DuctRoughness(
      material: DuctMaterial.galvanized,
      absoluteRoughnessFt: 0.0005,
      absoluteRoughnessM: 0.00015,
    ),
    DuctMaterial.fiberglass: DuctRoughness(
      material: DuctMaterial.fiberglass,
      absoluteRoughnessFt: 0.003,
      absoluteRoughnessM: 0.0009,
    ),
    DuctMaterial.flexible: DuctRoughness(
      material: DuctMaterial.flexible,
      absoluteRoughnessFt: 0.010,
      absoluteRoughnessM: 0.003,
    ),
    DuctMaterial.plastic: DuctRoughness(
      material: DuctMaterial.plastic,
      absoluteRoughnessFt: 0.00015,
      absoluteRoughnessM: 0.000045,
    ),
    DuctMaterial.aluminum: DuctRoughness(
      material: DuctMaterial.aluminum,
      absoluteRoughnessFt: 0.0003,
      absoluteRoughnessM: 0.00009,
    ),
    DuctMaterial.stainless: DuctRoughness(
      material: DuctMaterial.stainless,
      absoluteRoughnessFt: 0.0003,
      absoluteRoughnessM: 0.00009,
    ),
  };

  static DuctRoughness get(DuctMaterial material) {
    return values[material] ?? values[DuctMaterial.galvanized]!;
  }
}

class DuctPressureLossInput {
  final double flowRate;
  final UnitSystem unit;
  final DuctShapeForLoss shape;
  final double? ductDiameter;
  final double? ductWidth;
  final double? ductHeight;
  final double length;
  final DuctMaterial material;
  final List<FittingWithQuantity> fittings;

  const DuctPressureLossInput({
    required this.flowRate,
    required this.unit,
    required this.shape,
    this.ductDiameter,
    this.ductWidth,
    this.ductHeight,
    required this.length,
    required this.material,
    this.fittings = const [],
  });

  double get flowRateLs =>
      unit == UnitSystem.imperial ? flowRate / 2.11888 : flowRate;

  double get flowRateM3h =>
      unit == UnitSystem.imperial ? flowRate : flowRate * 1.699;

  double get flowRateCfm =>
      unit == UnitSystem.imperial ? flowRate : flowRate * 0.5886;

  double get lengthM => unit == UnitSystem.imperial ? length * 0.3048 : length;

  double get lengthFt => unit == UnitSystem.imperial ? length : length / 0.3048;

  double get ductDiameterM =>
      (ductDiameter != null && unit == UnitSystem.imperial)
      ? ductDiameter! * 0.0254
      : (ductDiameter ?? 0) / 1000;

  double get ductDiameterIn =>
      (ductDiameter != null && unit == UnitSystem.imperial)
      ? ductDiameter!
      : (ductDiameter ?? 0) / 25.4;

  double get ductWidthM => (ductWidth != null && unit == UnitSystem.imperial)
      ? ductWidth! * 0.0254
      : (ductWidth ?? 0) / 1000;

  double get ductHeightM => (ductHeight != null && unit == UnitSystem.imperial)
      ? ductHeight! * 0.0254
      : (ductHeight ?? 0) / 1000;

  double get hydraulicDiameterM {
    if (shape == DuctShapeForLoss.round) {
      return ductDiameterM;
    }
    // Hydraulic diameter for rectangular: Dh = 2ab/(a+b)
    final a = ductWidthM;
    final b = ductHeightM;
    if (a <= 0 || b <= 0) return 0;
    return 2 * a * b / (a + b);
  }
}

class FittingWithQuantity {
  final FittingType type;
  final int quantity;

  const FittingWithQuantity({required this.type, this.quantity = 1});

  double get totalK => FittingCoefficients.get(type).defaultK * quantity;
}

class DuctPressureLossResult {
  final double velocityMs;
  final double velocityFpm;
  final double velocityMpm;
  final double frictionLossPaPerM;
  final double frictionLossInWgPer100ft;
  final double totalFrictionLossPa;
  final double totalFrictionLossInWg;
  final double reynoldsNumber;
  final double darcyFrictionFactor;
  final double roughnessRatio;
  final double fittingLossPa;
  final double fittingLossInWg;
  final double totalLossPa;
  final double totalLossInWg;
  final double aspectRatio;
  final String? velocityWarning;
  final String? frictionWarning;
  final bool isHighVelocity;
  final bool isLowVelocity;
  final bool isHighFriction;
  final DuctPressureLossInput input;

  const DuctPressureLossResult({
    required this.velocityMs,
    required this.velocityFpm,
    required this.velocityMpm,
    required this.frictionLossPaPerM,
    required this.frictionLossInWgPer100ft,
    required this.totalFrictionLossPa,
    required this.totalFrictionLossInWg,
    required this.reynoldsNumber,
    required this.darcyFrictionFactor,
    required this.roughnessRatio,
    required this.fittingLossPa,
    required this.fittingLossInWg,
    required this.totalLossPa,
    required this.totalLossInWg,
    required this.aspectRatio,
    this.velocityWarning,
    this.frictionWarning,
    required this.isHighVelocity,
    required this.isLowVelocity,
    required this.isHighFriction,
    required this.input,
  });
}

class DuctPressureLossEngine {
  static const double _rho = 1.2;
  static const double _mu = 1.81e-5;

  static DuctPressureLossResult? calculate(DuctPressureLossInput input) {
    final flowRateLs = input.flowRateLs;
    final dhM = input.hydraulicDiameterM;

    if (flowRateLs <= 0 || dhM <= 0 || input.length <= 0) {
      return null;
    }

    // Cross-sectional area
    final areaM2 = _calculateAreaM2(input);
    if (areaM2 <= 0) return null;

    // Velocity (m/s) = (L/s → m³/s) / area
    final velocityMs = flowRateLs / 1000 / areaM2;
    final velocityFpm = velocityMs * 196.85;
    final velocityMpm = velocityMs * 60;

    // Reynolds number
    final reynolds = _reynolds(velocityMs, dhM);

    // Friction factor (Colebrook-White)
    final roughness = DuctRoughness.get(input.material);
    final eD = roughness.absoluteRoughnessM / dhM;
    final f = _frictionFactor(reynolds, eD);

    // Darcy-Weisbach: ΔP = f × (L/Dh) × (ρv²/2)
    final frictionLossPaPerM = f * _rho * velocityMs * velocityMs / (2 * dhM);
    final totalFrictionLossPa = frictionLossPaPerM * input.lengthM;
    // Convert Pa to in.wg: divide by 248.84
    final totalFrictionLossInWg = totalFrictionLossPa / 248.84;

    // Friction rate in in.wg/100ft
    final lengthFt = input.lengthFt;
    final frictionInWg100ft = lengthFt > 0
        ? (totalFrictionLossInWg / lengthFt) * 100
        : 0.0;

    // Fitting losses
    double fittingLossPa = 0;
    if (input.fittings.isNotEmpty) {
      for (final fitting in input.fittings) {
        final k = FittingCoefficients.get(fitting.type).defaultK;
        fittingLossPa +=
            0.5 * _rho * velocityMs * velocityMs * k * fitting.quantity;
      }
    }
    final fittingLossInWg = fittingLossPa / 248.84;

    // Total loss
    final totalLossPa = totalFrictionLossPa + fittingLossPa;
    final totalLossInWg = totalFrictionLossInWg + fittingLossInWg;

    // Aspect ratio for rectangular
    double aspectRatio = 1.0;
    if (input.shape == DuctShapeForLoss.rectangular) {
      final w = input.ductWidthM;
      final h = input.ductHeightM;
      if (h > 0) aspectRatio = w / h;
    }

    // Warnings — thresholds per ASHRAE/SMACNA
    String? velocityWarning;
    bool isHighVelocity = false;
    bool isLowVelocity = false;
    if (velocityFpm > AirDistributionConstants.highVelocityFpm) {
      isHighVelocity = true;
      velocityWarning =
          'Vận tốc cao (${velocityFpm.toStringAsFixed(0)} FPM > ${AirDistributionConstants.highVelocityFpm.toStringAsFixed(0)} FPM) — có thể gây tiếng ồn.';
    } else if (velocityFpm < AirDistributionConstants.lowVelocityFpm) {
      isLowVelocity = true;
      velocityWarning =
          'Vận tốc thấp (${velocityFpm.toStringAsFixed(0)} FPM < ${AirDistributionConstants.lowVelocityFpm.toStringAsFixed(0)} FPM) — có thể gây ứ đọng bụi.';
    }

    String? frictionWarning;
    bool isHighFriction = false;
    if (frictionInWg100ft >
        AirDistributionConstants.highFrictionRateInWg100ft) {
      isHighFriction = true;
      frictionWarning =
          'Tổn thất ma sát cao (${frictionInWg100ft.toStringAsFixed(2)} > ${AirDistributionConstants.highFrictionRateInWg100ft.toStringAsFixed(2)} in.wg/100ft) — cần quạt có cột áp lớn hơn.';
    }

    return DuctPressureLossResult(
      velocityMs: velocityMs,
      velocityFpm: velocityFpm,
      velocityMpm: velocityMpm,
      frictionLossPaPerM: frictionLossPaPerM,
      frictionLossInWgPer100ft: frictionInWg100ft,
      totalFrictionLossPa: totalFrictionLossPa,
      totalFrictionLossInWg: totalFrictionLossInWg,
      reynoldsNumber: reynolds,
      darcyFrictionFactor: f,
      roughnessRatio: eD,
      fittingLossPa: fittingLossPa,
      fittingLossInWg: fittingLossInWg,
      totalLossPa: totalLossPa,
      totalLossInWg: totalLossInWg,
      aspectRatio: aspectRatio,
      velocityWarning: velocityWarning,
      frictionWarning: frictionWarning,
      isHighVelocity: isHighVelocity,
      isLowVelocity: isLowVelocity,
      isHighFriction: isHighFriction,
      input: input,
    );
  }

  static double _calculateAreaM2(DuctPressureLossInput input) {
    if (input.shape == DuctShapeForLoss.round) {
      final d = input.ductDiameterM;
      if (d <= 0) return 0;
      return pi * d * d / 4;
    } else {
      final w = input.ductWidthM;
      final h = input.ductHeightM;
      if (w <= 0 || h <= 0) return 0;
      return w * h;
    }
  }

  static double _reynolds(double velocityMs, double diameterM) {
    if (diameterM <= 0) return 0;
    return velocityMs * diameterM / (_mu / _rho);
  }

  static double _frictionFactor(double re, double eD) {
    if (re <= 0) return 0;
    if (re < 2300) return 64 / re; // Laminar
    // Swamee-Jain approximation of Colebrook-White
    final term = eD / 3.7 + 5.74 / pow(re, 0.9);
    if (term <= 0) return 0.02;
    return 0.25 / pow(log(term) / log(10), 2);
  }
}
