import 'dart:math';

import '../../../core/hvac/models/enums.dart';
import '../constants/hydronic_constants.dart';

/// Input for water flow calculation.
class WaterFlowInput {
  final double flowRate;

  /// Pipe inner diameter. Imperial: inches. Metric: mm.
  final double diameter;
  final PipeMaterial material;
  final PipeService service;
  final UnitSystem unit;

  const WaterFlowInput({
    required this.flowRate,
    required this.diameter,
    required this.material,
    required this.service,
    required this.unit,
  });

  double get flowRateGpm => unit == UnitSystem.imperial
      ? flowRate
      : flowRate / HydronicConstants.gpmToM3h;

  double get flowRateM3s => unit == UnitSystem.imperial
      ? flowRate * HydronicConstants.gpmToM3s
      : flowRate / 3600;

  double get flowRateLs => unit == UnitSystem.imperial
      ? flowRate * HydronicConstants.gpmToLs
      : flowRate / 3.6;

  double get diameterM => unit == UnitSystem.imperial
      ? diameter * HydronicConstants.inchToM
      : diameter / 1000;

  double get diameterIn => unit == UnitSystem.imperial
      ? diameter
      : diameter / HydronicConstants.inchToMm;
}

class WaterFlowResult {
  final double flowRateGpm;
  final double flowRateLs;
  final double flowRateM3h;
  final double flowRateM3s;
  final double diameterM;
  final double diameterIn;
  final double velocityMs;
  final double velocityFps;
  final double velocityFpm;
  final double areaM2;
  final double areaFt2;
  final double reynolds;
  final FlowRegime regime;

  /// Fanning friction factor (f_F).
  final double frictionFactor;

  /// Darcy friction factor (f_D = 4 × f_F).
  final double darcyFrictionFactor;
  final double roughnessM;
  final double relativeRoughness;
  final double velocityPressurePa;
  final double velocityPressureInWg;
  final String? warning;
  final WaterFlowInput input;

  const WaterFlowResult({
    required this.flowRateGpm,
    required this.flowRateLs,
    required this.flowRateM3h,
    required this.flowRateM3s,
    required this.diameterM,
    required this.diameterIn,
    required this.velocityMs,
    required this.velocityFps,
    required this.velocityFpm,
    required this.areaM2,
    required this.areaFt2,
    required this.reynolds,
    required this.regime,
    required this.frictionFactor,
    required this.darcyFrictionFactor,
    required this.roughnessM,
    required this.relativeRoughness,
    required this.velocityPressurePa,
    required this.velocityPressureInWg,
    this.warning,
    required this.input,
  });
}

/// Calculates water/hydronic flow properties given pipe diameter and flow rate.
class WaterFlowEngine {
  static const double _rho = HydronicConstants.rhoWater20C; // kg/m³
  static const double _nu = HydronicConstants.nuWater20C; // m²/s

  static WaterFlowResult? calculate(WaterFlowInput input) {
    if (input.flowRate <= 0 || input.diameter <= 0) return null;

    final qM3s = input.flowRateM3s;
    final dM = input.diameterM;
    final dIn = input.diameterIn;

    final areaM2 = pi * dM * dM / 4;
    if (areaM2 <= 0) return null;

    final vMs = qM3s / areaM2;
    if (!vMs.isFinite || vMs <= 0) return null;

    final re = vMs * dM / _nu;
    final regime = _classifyRegime(re);

    final roughnessM = _roughnessM(input.material);
    final relRough = roughnessM / dM;
    final fDarcy = _swameeJainDarcy(re, relRough);
    final fanning = fDarcy / 4;

    // Velocity pressure: vp = ½ × ρ × V²
    final vpPa = 0.5 * _rho * vMs * vMs;
    final vpInWg = vpPa * HydronicConstants.paToInWg; // 1 in.wg = 249.089 Pa

    // Velocity warnings
    final limits = HydronicConstants.velocityLimitsMps[input.service]!;
    final vFps = vMs / HydronicConstants.ftToM;
    String? warning;
    if (vMs > limits.max) {
      warning =
          'Vận tốc ${vMs.toStringAsFixed(1)} m/s (${vFps.toStringAsFixed(1)} ft/s) '
          'vượt giới hạn tối đa ${limits.max} m/s. '
          'Có thể gây ồn hoặc xói mòn.';
    } else if (vMs < limits.min) {
      warning =
          'Vận tốc ${vMs.toStringAsFixed(2)} m/s (${vFps.toStringAsFixed(2)} ft/s) '
          'thấp hơn giới hạn tối thiểu ${limits.min} m/s. Có thể gây đọng cặn.';
    }

    return WaterFlowResult(
      flowRateGpm: input.flowRateGpm,
      flowRateLs: input.flowRateLs,
      flowRateM3h: input.flowRateM3s * 3600,
      flowRateM3s: qM3s,
      diameterM: dM,
      diameterIn: dIn,
      velocityMs: vMs,
      velocityFps: vFps,
      velocityFpm: vFps * 60,
      areaM2: areaM2,
      areaFt2: areaM2 * 10.764,
      reynolds: re,
      regime: regime,
      frictionFactor: fanning,
      darcyFrictionFactor: fDarcy,
      roughnessM: roughnessM,
      relativeRoughness: relRough,
      velocityPressurePa: vpPa,
      velocityPressureInWg: vpInWg,
      warning: warning,
      input: input,
    );
  }

  /// Swamee-Jain — Darcy friction factor (f_D).
  /// Reference: Swamee & Jain (1973), J. Hydraulics Div., ASCE.
  static double _swameeJainDarcy(double re, double relRough) {
    if (re <= 0 || relRough <= 0) return 0.03;
    if (re < 2300) return 64.0 / re; // laminar (Darcy)
    if (relRough > 0.01) return 0.05;

    // f_D = 0.25 / [log10(ε/D/3.7 + 5.74/Re^0.9)]²
    final logTerm = relRough / 3.7 + 5.74 / pow(re, 0.9);
    if (logTerm <= 0) return 0.05;
    final log10 = log(logTerm) / ln10; // base-10 logarithm
    if (log10 == 0) return 0.05;
    return (0.25 / (log10 * log10)).clamp(0.001, 0.5);
  }

  static FlowRegime _classifyRegime(double re) {
    if (re < HydronicConstants.reLaminarMax) return FlowRegime.laminar;
    if (re < HydronicConstants.reTurbulentMin) return FlowRegime.transitional;
    return FlowRegime.turbulent;
  }

  static double _roughnessM(PipeMaterial m) {
    return HydronicConstants.roughnessFt[m]! * HydronicConstants.ftToM;
  }
}
