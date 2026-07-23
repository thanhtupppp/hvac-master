import 'dart:math';

import '../../../core/hvac/models/enums.dart';
import '../data/fitting_coefficients.dart';
import 'duct_pressure_loss_engine.dart';

enum FittingLossShape { round, rectangular }

class FittingLossInput {
  final double flowRate;
  final UnitSystem unit;
  final FittingLossShape shape;
  final double ductDiameter;
  final double? ductWidth;
  final double? ductHeight;
  final double velocityOverride;
  final bool useVelocityOverride;
  final List<FittingWithQuantity> fittings;

  const FittingLossInput({
    required this.flowRate,
    required this.unit,
    required this.shape,
    required this.ductDiameter,
    this.ductWidth,
    this.ductHeight,
    this.velocityOverride = 0,
    this.useVelocityOverride = false,
    this.fittings = const [],
  });

  double get flowRateLs =>
      unit == UnitSystem.imperial ? flowRate / 2.11888 : flowRate;

  double get flowRateCfm =>
      unit == UnitSystem.imperial ? flowRate : flowRate * 0.5886;

  double get ductDiameterM =>
      unit == UnitSystem.imperial ? ductDiameter * 0.0254 : ductDiameter / 1000;

  double get ductDiameterIn =>
      unit == UnitSystem.imperial ? ductDiameter : ductDiameter / 25.4;

  double get ductWidthM => (ductWidth != null && unit == UnitSystem.imperial)
      ? ductWidth! * 0.0254
      : (ductWidth ?? 0) / 1000;

  double get ductHeightM => (ductHeight != null && unit == UnitSystem.imperial)
      ? ductHeight! * 0.0254
      : (ductHeight ?? 0) / 1000;

  double get areaM2 {
    if (shape == FittingLossShape.round) {
      final d = ductDiameterM;
      if (d <= 0) return 0;
      return pi * d * d / 4;
    } else {
      final w = ductWidthM;
      final h = ductHeightM;
      if (w <= 0 || h <= 0) return 0;
      return w * h;
    }
  }

  double get velocityMs {
    if (useVelocityOverride && velocityOverride > 0) {
      return velocityOverride;
    }
    if (areaM2 <= 0) return 0;
    return flowRateLs / 1000 / areaM2;
  }
}

class FittingContribution {
  final FittingType type;
  final String nameVi;
  final int quantity;
  final double kPerUnit;
  final double totalK;
  final double lossPa;
  final double lossInWg;
  final double sharePercent;

  const FittingContribution({
    required this.type,
    required this.nameVi,
    required this.quantity,
    required this.kPerUnit,
    required this.totalK,
    required this.lossPa,
    required this.lossInWg,
    required this.sharePercent,
  });
}

class FittingLossResult {
  final double velocityMs;
  final double velocityFpm;
  final double velocityPressurePa;
  final double velocityPressureInWg;
  final double totalK;
  final double totalLossPa;
  final double totalLossInWg;
  final double totalLossMmH2O;
  final List<FittingContribution> contributions;
  final String? warning;

  const FittingLossResult({
    required this.velocityMs,
    required this.velocityFpm,
    required this.velocityPressurePa,
    required this.velocityPressureInWg,
    required this.totalK,
    required this.totalLossPa,
    required this.totalLossInWg,
    required this.totalLossMmH2O,
    required this.contributions,
    this.warning,
  });
}

class FittingLossEngine {
  static const double _rho = 1.2;
  // 1 Pa = 0.10197 mmH2O
  static const double _paToMmH2O = 0.10197;

  static FittingLossResult? calculate(FittingLossInput input) {
    final velocity = input.velocityMs;
    if (velocity <= 0) return null;
    if (input.fittings.isEmpty) {
      return FittingLossResult(
        velocityMs: velocity,
        velocityFpm: velocity * 196.85,
        velocityPressurePa: 0,
        velocityPressureInWg: 0,
        totalK: 0,
        totalLossPa: 0,
        totalLossInWg: 0,
        totalLossMmH2O: 0,
        contributions: const [],
      );
    }

    // Velocity pressure: Pv = 0.5 × ρ × v²
    final velocityPressurePa = 0.5 * _rho * velocity * velocity;
    final velocityPressureInWg = velocityPressurePa / 248.84;

    final contributions = <FittingContribution>[];
    double totalK = 0;
    double totalLossPa = 0;

    for (final f in input.fittings) {
      final def = FittingCoefficients.get(f.type);
      final kPerUnit = def.defaultK;
      final k = kPerUnit * f.quantity;
      final lossPa = k * velocityPressurePa;
      totalK += k;
      totalLossPa += lossPa;
      contributions.add(
        FittingContribution(
          type: f.type,
          nameVi: def.displayName,
          quantity: f.quantity,
          kPerUnit: kPerUnit,
          totalK: k,
          lossPa: lossPa,
          lossInWg: lossPa / 248.84,
          sharePercent: 0,
        ),
      );
    }

    // Compute share percentages
    final withShare = contributions.map((c) {
      final share = totalLossPa > 0 ? (c.lossPa / totalLossPa) * 100 : 0.0;
      return FittingContribution(
        type: c.type,
        nameVi: c.nameVi,
        quantity: c.quantity,
        kPerUnit: c.kPerUnit,
        totalK: c.totalK,
        lossPa: c.lossPa,
        lossInWg: c.lossInWg,
        sharePercent: share,
      );
    }).toList()..sort((a, b) => b.lossPa.compareTo(a.lossPa));

    final totalLossInWg = totalLossPa / 248.84;
    final totalLossMmH2O = totalLossPa * _paToMmH2O;

    String? warning;
    if (velocity > 15) {
      warning =
          'Vận tốc cao (${velocity.toStringAsFixed(1)} m/s). Kiểm tra vận tốc cho phép.';
    } else if (velocityPressureInWg > 1.0) {
      warning =
          'Áp suất động cao (${velocityPressureInWg.toStringAsFixed(3)} in.wg) — kiểm tra noise.';
    }

    return FittingLossResult(
      velocityMs: velocity,
      velocityFpm: velocity * 196.85,
      velocityPressurePa: velocityPressurePa,
      velocityPressureInWg: velocityPressureInWg,
      totalK: totalK,
      totalLossPa: totalLossPa,
      totalLossInWg: totalLossInWg,
      totalLossMmH2O: totalLossMmH2O,
      contributions: withShare,
      warning: warning,
    );
  }
}
