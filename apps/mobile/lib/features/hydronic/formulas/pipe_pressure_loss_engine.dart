import 'dart:math';

import '../../../core/hvac/models/enums.dart';
import '../constants/hydronic_constants.dart';
import '../data/fitting_coefficients.dart';

/// Friction calculation method.
enum FrictionMethod { darcyWeisbach, hazenWilliams }

/// Individual fitting entry.
class FittingEntry {
  final FittingType type;
  final double nominalSizeIn;
  final int quantity;
  final String connectionType;

  const FittingEntry({
    required this.type,
    required this.nominalSizeIn,
    this.quantity = 1,
    this.connectionType = 'threaded',
  });
}

/// Input for pipe pressure loss calculation.
class PipePressureLossInput {
  final double flowRate;
  final double diameterIn;
  final double lengthFt;
  final PipeMaterial material;
  final PipeService service;
  final double glycolConcentration; // 0.0 to 0.4
  final FrictionMethod method;
  final List<FittingEntry> fittings;
  final UnitSystem unit;

  const PipePressureLossInput({
    required this.flowRate,
    required this.diameterIn,
    required this.lengthFt,
    required this.material,
    required this.service,
    this.glycolConcentration = 0.0,
    this.method = FrictionMethod.darcyWeisbach,
    this.fittings = const [],
    required this.unit,
  });
}

/// Result of pipe pressure loss calculation.
class PipePressureLossResult {
  /// Total friction loss in ft of head.
  final double totalFrictionFt;

  /// Total friction loss in m of head.
  final double totalFrictionM;

  /// Total friction loss in PSI.
  final double totalFrictionPsi;

  /// Total friction loss in kPa.
  final double totalFrictionKpa;

  /// Total friction loss in Bar.
  final double totalFrictionBar;

  /// Friction loss from straight pipe in ft head.
  final double pipeFrictionFt;

  /// Friction loss from fittings in ft head.
  final double fittingFrictionFt;

  /// Flow velocity in m/s.
  final double velocityMs;

  /// Flow velocity in ft/s.
  final double velocityFps;

  /// Reynolds number.
  final double reynolds;

  /// Darcy friction factor.
  final double darcyFrictionFactor;

  /// Hazen-Williams C-factor (if applicable).
  final double? hazenWilliamsC;

  /// Friction rate in ft/100ft.
  final double frictionRateFth;

  /// Friction rate in m/m.
  final double frictionRateMperM;

  /// Relative roughness ε/D.
  final double relativeRoughness;

  /// Fluid density used (kg/m³).
  final double fluidDensity;

  /// Fluid viscosity used (Pa·s).
  final double fluidViscosity;

  /// Kinetic energy coefficient (2α, default 1.0 for turbulent).
  final double kineticEnergyCoefficient;

  /// Per-fitting loss breakdown.
  final List<FittingLossItem> fittingBreakdown;

  final PipePressureLossInput input;

  const PipePressureLossResult({
    required this.totalFrictionFt,
    required this.totalFrictionM,
    required this.totalFrictionPsi,
    required this.totalFrictionKpa,
    required this.totalFrictionBar,
    required this.pipeFrictionFt,
    required this.fittingFrictionFt,
    required this.velocityMs,
    required this.velocityFps,
    required this.reynolds,
    required this.darcyFrictionFactor,
    this.hazenWilliamsC,
    required this.frictionRateFth,
    required this.frictionRateMperM,
    required this.relativeRoughness,
    required this.fluidDensity,
    required this.fluidViscosity,
    required this.kineticEnergyCoefficient,
    required this.fittingBreakdown,
    required this.input,
  });
}

class FittingLossItem {
  final String name;
  final int quantity;
  final double kValue;
  final double velocityHeadFt;
  final double totalLossFt;

  const FittingLossItem({
    required this.name,
    required this.quantity,
    required this.kValue,
    required this.velocityHeadFt,
    required this.totalLossFt,
  });
}

/// Calculates pipe friction loss using Darcy-Weisbach and optionally Hazen-Williams.
///
/// Key formulas:
///   Darcy-Weisbach: h_f = f × L/D × V²/2g
///   Fitting loss:  h_f = Σ K × V²/2g
///   Hazen-Williams: h_f = 10.67 × L × Q^1.852 / (C^1.852 × D^4.87)  (ft)
class PipePressureLossEngine {
  static const double _g = HydronicConstants.g; // 9.80665 m/s²
  static const double _ftTom = HydronicConstants.ftToM; // 0.3048
  static const double _gFt = 32.174; // ft/s²

  static PipePressureLossResult? calculate(PipePressureLossInput input) {
    if (input.flowRate <= 0 || input.diameterIn <= 0 || input.lengthFt <= 0) {
      return null;
    }

    // Flow in GPM
    final gpm = input.unit == UnitSystem.imperial
        ? input.flowRate
        : input.flowRate / HydronicConstants.gpmToM3h;

    // Flow in m³/s
    final qM3s = gpm * HydronicConstants.gpmToM3s;

    // Pipe geometry
    final idM = input.diameterIn * HydronicConstants.inchToM;
    final idFt = input.diameterIn / 12.0;
    final areaM2 = pi * idM * idM / 4;

    if (areaM2 <= 0) return null;

    // Velocity
    final vMs = qM3s / areaM2;
    final vFps = vMs / _ftTom;
    if (!vMs.isFinite || vMs <= 0) return null;

    // Fluid properties
    final rho = _density(input.glycolConcentration);
    final mu = _viscosity(input.glycolConcentration);
    final nu = mu / rho; // kinematic viscosity (m²/s) = μ / ρ

    // Reynolds number: Re = V × D / ν
    final re = vMs * idM / nu;

    // Friction factor (Darcy)
    final roughnessM = _roughnessM(input.material);
    final relRough = roughnessM / idM;
    final fDarcy = _swameeJainDarcy(re, relRough);

    // Friction rate (ft/100ft)
    double frictionRateFth;
    double pipeFrictionFt;

    if (input.method == FrictionMethod.hazenWilliams) {
      // Hazen-Williams formula (ft of head)
      // h_f = 10.67 × L × Q^1.852 / (C^1.852 × D^4.87)
      // Q must be in ft³/s; D in feet.
      final c = HydronicConstants.hwCoefficientDefault;
      final qFt3s = qM3s * 35.3147; // m³/s → ft³/s
      pipeFrictionFt = 10.67 *
          input.lengthFt *
          pow(qFt3s, 1.852) /
          (pow(c, 1.852) * pow(idFt, 4.87));
      // Friction rate per 100ft
      frictionRateFth = pipeFrictionFt / input.lengthFt * 100;
    } else {
      // Darcy-Weisbach: h_f = f × L/D × V²/2g
      frictionRateFth = fDarcy * vFps * vFps / (2 * _gFt * idFt) * 100;
      pipeFrictionFt =
          fDarcy * input.lengthFt / idFt * vFps * vFps / (2 * _gFt);
    }

    // Velocity head V²/2g (ft)
    final velocityHeadFt = vFps * vFps / (2 * _gFt);

    // Fitting losses: h_fittings = Σ(K × V²/2g)
    List<FittingLossItem> fittingBreakdown = [];
    double totalFittingFt = 0;
    for (final fit in input.fittings) {
      final catalogEntry = fittingCatalog[fit.type];
      final k =
          catalogEntry?.kFor(fit.nominalSizeIn, fit.connectionType) ?? kDefault;
      final fitLossFt = k * velocityHeadFt;
      totalFittingFt += fitLossFt * fit.quantity;
      fittingBreakdown.add(
        FittingLossItem(
          name: getFittingNameVi(fit.type),
          quantity: fit.quantity,
          kValue: k,
          velocityHeadFt: velocityHeadFt,
          totalLossFt: fitLossFt * fit.quantity,
        ),
      );
    }

    // Total friction loss
    final totalFrictionFt = pipeFrictionFt + totalFittingFt;
    final totalFrictionM = totalFrictionFt * _ftTom;
    final totalFrictionPsi = totalFrictionFt * HydronicConstants.ftHeadToPsi;
    final totalFrictionKpa = totalFrictionM * _g * 0.001;
    final totalFrictionBar = totalFrictionPsi * HydronicConstants.psiToBar;

    return PipePressureLossResult(
      totalFrictionFt: totalFrictionFt,
      totalFrictionM: totalFrictionM,
      totalFrictionPsi: totalFrictionPsi,
      totalFrictionKpa: totalFrictionKpa,
      totalFrictionBar: totalFrictionBar,
      pipeFrictionFt: pipeFrictionFt,
      fittingFrictionFt: totalFittingFt,
      velocityMs: vMs,
      velocityFps: vFps,
      reynolds: re,
      darcyFrictionFactor: fDarcy,
      hazenWilliamsC: input.method == FrictionMethod.hazenWilliams
          ? HydronicConstants.hwCoefficientDefault
          : null,
      frictionRateFth: frictionRateFth,
      frictionRateMperM: frictionRateFth / 100 * _ftTom,
      relativeRoughness: relRough,
      fluidDensity: rho,
      fluidViscosity: mu,
      kineticEnergyCoefficient: re > 4000
          ? 1.0
          : 2.0, // α = 1 for turbulent, 2 for laminar
      fittingBreakdown: fittingBreakdown,
      input: input,
    );
  }

  /// Swamee-Jain — Darcy friction factor.
  static double _swameeJainDarcy(double re, double relRough) {
    if (re <= 0 || relRough <= 0) return 0.03;
    if (re < 2300) return 64.0 / re; // laminar
    if (relRough > 0.01) return 0.05;

    final logTerm = relRough / 3.7 + 5.74 / pow(re, 0.9);
    if (logTerm <= 0) return 0.05;
    final log10 = log(logTerm) / ln10;
    if (log10 == 0) return 0.05;
    return (0.25 / (log10 * log10)).clamp(0.001, 0.5);
  }

  static double _roughnessM(PipeMaterial m) {
    return (HydronicConstants.roughnessFt[m] ?? 0.00015) *
        HydronicConstants.ftToM;
  }

  static double _density(double glycolConcentration) {
    return HydronicConstants.glycolDensity(glycolConcentration, 20.0);
  }

  static double _viscosity(double glycolConcentration) {
    return HydronicConstants.glycolViscosity(glycolConcentration, 20.0);
  }
}
