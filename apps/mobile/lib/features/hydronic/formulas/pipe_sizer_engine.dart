import 'dart:math';

import '../../../core/hvac/models/enums.dart';
import '../constants/hydronic_constants.dart';
import '../data/pipe_catalog.dart';

/// Input for pipe sizing calculation.
class PipeSizerInput {
  /// Flow rate. Unit depends on [unit].
  /// Imperial: GPM. Metric: m³/h.
  final double flowRate;

  /// Fluid service type (for velocity limits).
  final PipeService service;

  /// Pipe material.
  final PipeMaterial material;

  /// Pipe schedule (Sch40 or Sch80). Ignored for copper/pex.
  final PipeSchedule schedule;

  /// Maximum allowed velocity. Unit depends on [unit].
  /// Imperial: ft/s. Metric: m/s.
  /// If null, uses service default.
  final double? maxVelocity;

  /// Minimum allowed velocity. Unit depends on [unit].
  /// Imperial: ft/s. Metric: m/s.
  final double? minVelocity;

  final UnitSystem unit;

  const PipeSizerInput({
    required this.flowRate,
    required this.service,
    required this.material,
    this.schedule = PipeSchedule.schedule40,
    this.maxVelocity,
    this.minVelocity,
    required this.unit,
  });

  /// Flow rate in GPM.
  double get flowRateGpm => unit == UnitSystem.imperial
      ? flowRate
      : flowRate / HydronicConstants.gpmToM3h;

  /// Maximum velocity in m/s.
  double get maxVelocityMs {
    if (maxVelocity != null) {
      return unit == UnitSystem.imperial
          ? maxVelocity! * HydronicConstants.ftToM
          : maxVelocity!;
    }
    return HydronicConstants.velocityLimitsMps[service]!.max;
  }

  /// Minimum velocity in m/s.
  double get minVelocityMs {
    if (minVelocity != null) {
      return unit == UnitSystem.imperial
          ? minVelocity! * HydronicConstants.ftToM
          : minVelocity!;
    }
    return HydronicConstants.velocityLimitsMps[service]!.min;
  }

  /// Recommended velocity in m/s.
  double get recommendedVelocityMs =>
      HydronicConstants.velocityLimitsMps[service]!.recommended;
}

/// Result of pipe sizing.
class PipeSizerResult {
  /// Nominal pipe size selected (inches).
  final double nominalSizeIn;

  /// Actual inner diameter of selected pipe (inches).
  final double actualIdIn;

  /// Inner diameter in meters.
  final double actualIdM;

  /// Flow velocity at selected pipe (m/s).
  final double velocityMs;

  /// Flow velocity at selected pipe (ft/s).
  final double velocityFps;

  /// Flow velocity at selected pipe (FPM).
  final double velocityFpm;

  /// Reynolds number.
  final double reynolds;

  /// Flow regime.
  final FlowRegime regime;

  /// Friction factor (Darcy).
  final double darcyFrictionFactor;

  /// Friction rate (ft/100 ft).
  final double frictionRateFth;

  /// Friction rate (m/m).
  final double frictionRateMperM;

  /// Recommended velocity (m/s) per service.
  final double recommendedVelocityMs;

  /// Minimum velocity (m/s) per service.
  final double minVelocityMs;

  /// Maximum velocity (m/s) per service.
  final double maxVelocityMs;

  /// Calculated minimum diameter (m) before rounding.
  final double calculatedDiameterM;

  /// Warning if selected velocity is outside limits.
  final String? warning;

  /// All candidate sizes with their velocities.
  final List<PipeSizerCandidate> candidates;

  final PipeSizerInput input;

  const PipeSizerResult({
    required this.nominalSizeIn,
    required this.actualIdIn,
    required this.actualIdM,
    required this.velocityMs,
    required this.velocityFps,
    required this.velocityFpm,
    required this.reynolds,
    required this.regime,
    required this.darcyFrictionFactor,
    required this.frictionRateFth,
    required this.frictionRateMperM,
    required this.recommendedVelocityMs,
    required this.minVelocityMs,
    required this.maxVelocityMs,
    required this.calculatedDiameterM,
    this.warning,
    required this.candidates,
    required this.input,
  });
}

/// A candidate pipe size with its properties.
class PipeSizerCandidate {
  final double nominalIn;
  final double idIn;
  final double idM;
  final double velocityMs;
  final double velocityFps;
  final double reynolds;
  final FlowRegime regime;
  final double darcyFrictionFactor;
  final double frictionRateFth;

  const PipeSizerCandidate({
    required this.nominalIn,
    required this.idIn,
    required this.idM,
    required this.velocityMs,
    required this.velocityFps,
    required this.reynolds,
    required this.regime,
    required this.darcyFrictionFactor,
    required this.frictionRateFth,
  });
}

/// Sizing engine: given flow rate + velocity limit → select standard pipe size.
///
/// Key formula:
///   D_calc = √(4 × Q_m3s / (π × V_target))
///   Round up to next standard size, verify velocity, friction rate.
class PipeSizerEngine {
  // Imperial constants for Darcy-Weisbach in ft/s units
  static const double _nuFt2s =
      HydronicConstants.nuWater20C; // m²/s — will convert
  static const double _ftTom = HydronicConstants.ftToM; // 0.3048
  static const double _gFt = 32.174; // ft/s² (standard gravity)

  /// Calculate pipe size recommendation.
  ///
  /// Returns null if flow rate ≤ 0.
  static PipeSizerResult? calculate(PipeSizerInput input) {
    if (input.flowRate <= 0) return null;

    final qM3s = input.flowRateGpm * HydronicConstants.gpmToM3s;
    final maxVelMs = input.maxVelocityMs;
    final minVelMs = input.minVelocityMs;
    final recVelMs = input.recommendedVelocityMs;

    // Calculate theoretical diameter at maximum allowed velocity
    // D_calc = √(4Q / (πV))
    final dCalcM = sqrt(4 * qM3s / (pi * maxVelMs));
    if (!dCalcM.isFinite || dCalcM <= 0) return null;

    // Collect all candidate sizes
    final candidates = _buildCandidates(input, qM3s);

    // Select: smallest size where velocity ≤ maxVelocity
    PipeSizerCandidate? selected;
    for (final c in candidates) {
      if (c.velocityMs <= maxVelMs) {
        selected = c;
        break;
      }
    }

    // Fallback: use largest available size if nothing fits
    selected ??= candidates.last;

    // Velocity warning
    String? warning;
    if (selected.velocityMs > maxVelMs) {
      warning =
          'Vận tốc ${selected.velocityMs.toStringAsFixed(2)} m/s '
          '(${selected.velocityFps.toStringAsFixed(1)} ft/s) '
          'vượt giới hạn tối đa ${maxVelMs.toStringAsFixed(1)} m/s '
          'cho dịch vụ "${HydronicConstants.getServiceNameVi(input.service)}". '
          'Chọn cỡ ống lớn hơn.';
    } else if (selected.velocityMs < minVelMs) {
      warning =
          'Vận tốc ${selected.velocityMs.toStringAsFixed(2)} m/s '
          'thấp hơn giới hạn tối thiểu ${minVelMs.toStringAsFixed(1)} m/s. '
          'Cân nhắc chọn cỡ ống nhỏ hơn để tiết kiệm vật liệu.';
    }

    return PipeSizerResult(
      nominalSizeIn: selected.nominalIn,
      actualIdIn: selected.idIn,
      actualIdM: selected.idM,
      velocityMs: selected.velocityMs,
      velocityFps: selected.velocityFps,
      velocityFpm: selected.velocityFps * 60,
      reynolds: selected.reynolds,
      regime: selected.regime,
      darcyFrictionFactor: selected.darcyFrictionFactor,
      frictionRateFth: selected.frictionRateFth,
      frictionRateMperM: selected.frictionRateFth * 0.3048 / 100,
      recommendedVelocityMs: recVelMs,
      minVelocityMs: minVelMs,
      maxVelocityMs: maxVelMs,
      calculatedDiameterM: dCalcM,
      warning: warning,
      candidates: candidates,
      input: input,
    );
  }

  static List<PipeSizerCandidate> _buildCandidates(
    PipeSizerInput input,
    double qM3s,
  ) {
    final List<PipeSizerCandidate> candidates = [];
    final roughnessM = _roughnessM(input.material);
    // ν in ft²/s: 1 m²/s = 10.764 ft²/s
    final nuFt2s = _nuFt2s * 10.764;

    List<double> nominalSizes;
    if (input.material == PipeMaterial.copperTypeK ||
        input.material == PipeMaterial.copperTypeL ||
        input.material == PipeMaterial.copperTypeM ||
        input.material == PipeMaterial.pex) {
      nominalSizes = [
        0.375,
        0.5,
        0.75,
        1.0,
        1.25,
        1.5,
        2.0,
        2.5,
        3.0,
        3.5,
        4.0,
        5.0,
        6.0,
        8.0,
      ];
    } else {
      nominalSizes = [
        0.5,
        0.75,
        1.0,
        1.25,
        1.5,
        2.0,
        2.5,
        3.0,
        3.5,
        4.0,
        5.0,
        6.0,
        8.0,
        10.0,
        12.0,
        14.0,
        16.0,
        18.0,
        20.0,
        24.0,
      ];
    }

    for (final nomIn in nominalSizes) {
      final idIn = _idFor(nomIn, input);
      if (idIn <= 0) continue;

      final idM = idIn * HydronicConstants.inchToM;
      final areaM2 = pi * idM * idM / 4;
      if (areaM2 <= 0) continue;

      final vMs = qM3s / areaM2;
      if (!vMs.isFinite || vMs <= 0) continue;

      // Imperial values
      final idFt = idIn / 12.0;
      final vFps = vMs / _ftTom;
      final vFt3s = vFps * idFt * idFt * pi / 4;
      if (vFt3s <= 0) continue;

      // Reynolds in ft units
      final re = vFps * idFt / nuFt2s;
      final fDarcy = _frictionFactor(re, roughnessM / idM);

      // Darcy-Weisbach friction rate: h_f/L (ft/ft) = f × V²/(2gD)
      // Multiply by 100 to get ft/100ft
      final frictionRateFth = fDarcy * vFps * vFps / (2 * _gFt * idFt) * 100;

      candidates.add(
        PipeSizerCandidate(
          nominalIn: nomIn,
          idIn: idIn,
          idM: idM,
          velocityMs: vMs,
          velocityFps: vFps,
          reynolds: re,
          regime: _classifyRegime(re),
          darcyFrictionFactor: fDarcy,
          frictionRateFth: frictionRateFth,
        ),
      );
    }

    return candidates;
  }

  static double _idFor(double nominalIn, PipeSizerInput input) {
    switch (input.material) {
      case PipeMaterial.copperTypeK:
      case PipeMaterial.copperTypeL:
      case PipeMaterial.copperTypeM:
      case PipeMaterial.pex:
        return copperIdInch(nominalIn, input.material);
      case PipeMaterial.pvcSch40:
      case PipeMaterial.cpvcSch40:
        final match = findSizeByNominal(
          nominalIn,
          input.material,
          PipeSchedule.schedule40,
        );
        return match?.idInch ?? 0;
      case PipeMaterial.pvcSch80:
      case PipeMaterial.cpvcSch80:
        final match = findSizeByNominal(
          nominalIn,
          input.material,
          PipeSchedule.schedule80,
        );
        return match?.idInch ?? 0;
      default:
        final match = findSizeByNominal(
          nominalIn,
          input.material,
          input.schedule,
        );
        return match?.idInch ?? 0;
    }
  }

  static double _frictionFactor(double re, double relRough) {
    if (re <= 0 || relRough <= 0) return 0.03;
    if (re < 2300) return 64.0 / re; // laminar (Darcy)
    if (relRough > 0.01) return 0.05;

    // Swamee-Jain (Darcy friction factor):
    // f_D = 0.25 / [log10(ε/D/3.7 + 5.74/Re^0.9)]²
    final logTerm = relRough / 3.7 + 5.74 / pow(re, 0.9);
    if (logTerm <= 0) return 0.05;
    final log10 = log(logTerm) / ln10; // base-10 logarithm
    if (log10 == 0) return 0.05;
    final f = 0.25 / (log10 * log10);
    return f.clamp(0.001, 0.5);
  }

  static double _roughnessM(PipeMaterial m) {
    return (HydronicConstants.roughnessFt[m] ?? 0.00015) *
        HydronicConstants.ftToM;
  }

  static FlowRegime _classifyRegime(double re) {
    if (re < HydronicConstants.reLaminarMax) return FlowRegime.laminar;
    if (re < HydronicConstants.reTurbulentMin) return FlowRegime.transitional;
    return FlowRegime.turbulent;
  }
}
