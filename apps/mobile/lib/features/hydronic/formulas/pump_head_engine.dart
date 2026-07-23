import 'dart:math' as math;

import '../../../../core/hvac/models/enums.dart';
import '../constants/hydronic_constants.dart';
import 'pipe_pressure_loss_engine.dart';

/// Pump head calculation input.
///
/// Covers the standard pumping-system equation:
///   H_total = H_static + H_friction + H_velocity − H_pressure
///
/// Where:
///   H_static     = elevation difference + (ΔP_suction→discharge) / (ρg)
///   H_friction   = sum of pipe friction + fittings losses (head form)
///   H_velocity   = velocity-head gain/loss (typically small; rarely zero on
///                  discharge side if discharge is to atmosphere, included for
///                  completeness)
///   H_pressure   = pressure at suction minus pressure at discharge (if both
///                  are pressurized, this can be negative)
class PumpHeadInput {
  final double flowRate; // GPM (imperial) or m³/h (metric)
  final double pipeDiameterIn; // pipe ID (in for imperial, mm for metric)
  final double pipeLengthFt; // ft (imperial) or m (metric)
  final PipeMaterial material;
  final PipeService service;
  final double glycolConcentration; // 0.0–0.4 (fraction)
  final FrictionMethod method;
  final List<FittingEntry> fittings;
  final double staticHeadFt; // elevation difference (ft or m)
  final double suctionPressurePsi; // PSI (imperial) or kPa (metric)
  final double dischargePressurePsi; // PSI (imperial) or kPa (metric)
  final UnitSystem unit;

  const PumpHeadInput({
    required this.flowRate,
    required this.pipeDiameterIn,
    required this.pipeLengthFt,
    required this.material,
    required this.service,
    this.glycolConcentration = 0.0,
    this.method = FrictionMethod.darcyWeisbach,
    this.fittings = const [],
    this.staticHeadFt = 0.0,
    this.suctionPressurePsi = 0.0,
    this.dischargePressurePsi = 0.0,
    this.unit = UnitSystem.imperial,
  });
}

/// Pump head calculation result.
///
/// All head values are reported in **feet of water** (ftH₂O) and **meters of
/// water** (mH₂O). Pressure equivalents are PSI/kPa/bar.
class PumpHeadResult {
  // Static head (from elevation + pressure differential)
  final double staticHeadFt;
  final double staticHeadM;
  final double staticHeadPsi;
  final double staticHeadKpa;
  final double staticHeadBar;

  // Friction head (pipe + fittings)
  final double frictionHeadFt;
  final double frictionHeadM;
  final double frictionHeadPsi;
  final double frictionHeadKpa;
  final double frictionHeadBar;

  // Pipe friction only
  final double pipeFrictionFt;
  final double fittingFrictionFt;

  // Velocity head
  final double velocityHeadFt;
  final double velocityHeadM;

  // Total dynamic head (the headline number)
  final double totalHeadFt;
  final double totalHeadM;
  final double totalHeadPsi;
  final double totalHeadKpa;
  final double totalHeadBar;

  // Hydraulic power & brake power (motor)
  final double waterPowerHp;
  final double waterPowerKw;
  final double brakePowerHp;
  final double brakePowerKw;
  final double motorEfficiency;

  // Warnings
  final List<String> warnings;

  const PumpHeadResult({
    required this.staticHeadFt,
    required this.staticHeadM,
    required this.staticHeadPsi,
    required this.staticHeadKpa,
    required this.staticHeadBar,
    required this.frictionHeadFt,
    required this.frictionHeadM,
    required this.frictionHeadPsi,
    required this.frictionHeadKpa,
    required this.frictionHeadBar,
    required this.pipeFrictionFt,
    required this.fittingFrictionFt,
    required this.velocityHeadFt,
    required this.velocityHeadM,
    required this.totalHeadFt,
    required this.totalHeadM,
    required this.totalHeadPsi,
    required this.totalHeadKpa,
    required this.totalHeadBar,
    required this.waterPowerHp,
    required this.waterPowerKw,
    required this.brakePowerHp,
    required this.brakePowerKw,
    required this.motorEfficiency,
    required this.warnings,
  });
}

/// Engine that computes total dynamic head for a closed-loop pumping system.
///
/// References:
///   - HI (Hydronics Institute) Pump Standards
///   - ASHRAE Handbook HVAC Applications, Chapter 47
///   - Crane Co. TP-410, "Flow of Fluids"
class PumpHeadEngine {
  PumpHeadEngine._();

  static const double _g = 9.80665; // m/s²

  /// Calculate total dynamic head (TDH).
  ///
  /// Returns null if input is invalid (zero/negative values).
  static PumpHeadResult? calculate(PumpHeadInput input) {
    // Validate inputs
    if (input.flowRate <= 0 ||
        input.pipeDiameterIn <= 0 ||
        input.pipeLengthFt < 0) {
      return null;
    }

    final warnings = <String>[];

    // ── Normalize to SI internally ─────────────────────────────
    final rho = _density(input.glycolConcentration);
    final gpm = _toGpm(input);
    final idM = _toDiameterMeters(input.pipeDiameterIn, input.unit);
    final lengthFt = input.unit == UnitSystem.imperial
        ? input.pipeLengthFt
        : input.pipeLengthFt / HydronicConstants.ftToM;

    final qM3s = gpm * HydronicConstants.gpmToM3s;

    // Velocity
    final areaM2 = math.pi / 4.0 * idM * idM;
    final vMs = qM3s / areaM2;
    if (vMs <= 0) return null;

    // ── Static head ────────────────────────────────────────────
    // Elevation difference (m/ft)
    final elevM = input.unit == UnitSystem.imperial
        ? input.staticHeadFt * HydronicConstants.ftToM
        : input.staticHeadFt;
    final elevFt = input.unit == UnitSystem.imperial
        ? input.staticHeadFt
        : input.staticHeadFt / HydronicConstants.ftToM;

    // Pressure differential (discharge − suction), converted to head
    // Discharge pressure pushes against the pump → subtract.
    final dischargePa = input.unit == UnitSystem.imperial
        ? input.dischargePressurePsi * HydronicConstants.psiToPa
        : input.dischargePressurePsi * 1000.0; // kPa → Pa
    final suctionPa = input.unit == UnitSystem.imperial
        ? input.suctionPressurePsi * HydronicConstants.psiToPa
        : input.suctionPressurePsi * 1000.0;
    final deltaPressurePa = dischargePa - suctionPa;
    final pressureHeadM = deltaPressurePa / (rho * _g);
    final pressureHeadFt = pressureHeadM / HydronicConstants.ftToM;

    // Static = elevation + pressure differential (in head form)
    final staticHeadM = elevM + pressureHeadM;
    final staticHeadFt = elevFt + pressureHeadFt;

    // ── Friction head (pipe + fittings) ─────────────────────────
    final loss = PipePressureLossEngine.calculate(
      PipePressureLossInput(
        flowRate: gpm,
        diameterIn: _toDiameterForPressureLoss(input),
        lengthFt: lengthFt,
        material: input.material,
        service: input.service,
        glycolConcentration: input.glycolConcentration,
        method: input.method,
        fittings: input.fittings,
        unit: UnitSystem.imperial, // pressure loss engine works in imperial
      ),
    );

    final pipeFrictionFt = loss?.pipeFrictionFt ?? 0.0;
    final pipeFrictionM = pipeFrictionFt * HydronicConstants.ftToM;
    final fittingFrictionFt = loss?.fittingFrictionFt ?? 0.0;
    final fittingFrictionM = fittingFrictionFt * HydronicConstants.ftToM;
    final frictionHeadFt = pipeFrictionFt + fittingFrictionFt;
    final frictionHeadM = pipeFrictionM + fittingFrictionM;

    // ── Velocity head ───────────────────────────────────────────
    final velocityHeadM = vMs * vMs / (2.0 * _g);
    final velocityHeadFt = velocityHeadM / HydronicConstants.ftToM;

    // ── Total dynamic head ─────────────────────────────────────
    // H_total = H_static + H_friction + H_velocity
    final totalHeadM = staticHeadM + frictionHeadM + velocityHeadM;
    final totalHeadFt = staticHeadFt + frictionHeadFt + velocityHeadFt;

    // ── Pressure equivalents (water column) ────────────────────
    final totalHeadPa = totalHeadM * rho * _g;
    final totalHeadPsi = totalHeadPa / HydronicConstants.psiToPa;
    final totalHeadKpa = totalHeadPa / 1000.0;
    final totalHeadBar = totalHeadKpa / 100.0;

    final staticHeadPa = staticHeadM * rho * _g;
    final staticHeadPsi = staticHeadPa / HydronicConstants.psiToPa;
    final staticHeadKpa = staticHeadPa / 1000.0;
    final staticHeadBar = staticHeadKpa / 100.0;

    final frictionHeadPa = frictionHeadM * rho * _g;
    final frictionHeadPsi = frictionHeadPa / HydronicConstants.psiToPa;
    final frictionHeadKpa = frictionHeadPa / 1000.0;
    final frictionHeadBar = frictionHeadKpa / 100.0;

    // ── Hydraulic power ─────────────────────────────────────────
    // P_water = ρ × g × Q × H (W)
    final waterPowerW = rho * _g * qM3s * totalHeadM;
    final waterPowerHp = waterPowerW / 745.7;
    final waterPowerKw = waterPowerW / 1000.0;

    // ── Brake power (motor shaft) ──────────────────────────────
    // P_motor = P_water / η_motor
    final motorHp = _estimateMotorSize(waterPowerHp);
    final motorEff = HydronicConstants.motorEfficiencyTiers[motorHp] ?? 0.85;
    final brakePowerW = waterPowerW / motorEff;
    final brakePowerHp = brakePowerW / 745.7;
    final brakePowerKw = brakePowerW / 1000.0;

    // ── Warnings ────────────────────────────────────────────────
    if (vMs > HydronicConstants.velocityLimitsMps[input.service]!.max) {
      warnings.add(
        'Van toc ${vMs.toStringAsFixed(2)} m/s vuot gioi han toi da.',
      );
    }
    if (totalHeadFt < 0) {
      warnings.add('Cot ap am — he thong tu dan nuoc, khong can bom.');
    }
    if (totalHeadFt > 300) {
      warnings.add('Cot ap rat cao (>300 ft). Kiem tra thiet ke he thong.');
    }
    if (frictionHeadFt > 0 &&
        totalHeadFt > 0 &&
        frictionHeadFt / totalHeadFt > 0.7) {
      warnings.add(
        'Ton that ma sat chiem >70% cot ap — xem xet duong ong lon hon.',
      );
    }

    return PumpHeadResult(
      staticHeadFt: staticHeadFt,
      staticHeadM: staticHeadM,
      staticHeadPsi: staticHeadPsi,
      staticHeadKpa: staticHeadKpa,
      staticHeadBar: staticHeadBar,
      frictionHeadFt: frictionHeadFt,
      frictionHeadM: frictionHeadM,
      frictionHeadPsi: frictionHeadPsi,
      frictionHeadKpa: frictionHeadKpa,
      frictionHeadBar: frictionHeadBar,
      pipeFrictionFt: pipeFrictionFt,
      fittingFrictionFt: fittingFrictionFt,
      velocityHeadFt: velocityHeadFt,
      velocityHeadM: velocityHeadM,
      totalHeadFt: totalHeadFt,
      totalHeadM: totalHeadM,
      totalHeadPsi: totalHeadPsi,
      totalHeadKpa: totalHeadKpa,
      totalHeadBar: totalHeadBar,
      waterPowerHp: waterPowerHp,
      waterPowerKw: waterPowerKw,
      brakePowerHp: brakePowerHp,
      brakePowerKw: brakePowerKw,
      motorEfficiency: motorEff,
      warnings: warnings,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  /// Estimate motor size in HP from water power, rounded up to standard tier.
  static int _estimateMotorSize(double waterHp) {
    if (waterHp <= 0) return 1;
    const tiers = [1, 2, 3, 5, 7, 10, 15, 20, 25, 30, 40, 50, 60, 75, 100];
    for (final t in tiers) {
      if (waterHp <= t) return t;
    }
    return ((waterHp / 50).ceil() * 50).clamp(100, 1000);
  }

  static double _toGpm(PumpHeadInput i) {
    if (i.unit == UnitSystem.imperial) return i.flowRate;
    return i.flowRate * HydronicConstants.m3hToGpm;
  }

  static double _toDiameterMeters(double diameterIn, UnitSystem unit) {
    if (unit == UnitSystem.imperial) {
      return diameterIn * HydronicConstants.inchToM;
    }
    return diameterIn / 1000.0; // mm → m
  }

  static double _toDiameterForPressureLoss(PumpHeadInput i) {
    if (i.unit == UnitSystem.imperial) return i.pipeDiameterIn;
    return i.pipeDiameterIn * HydronicConstants.mmToInch;
  }

  static double _density(double glycolConcentration) {
    return HydronicConstants.glycolDensity(glycolConcentration, 20.0);
  }
}

/// Convenience alias for clarity at call sites.
typedef PumpHeadCalculator = PumpHeadEngine;
