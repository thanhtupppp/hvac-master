import '../../../core/hvac/models/enums.dart';
import '../constants/hydronic_constants.dart';

/// Tank sizing input.
class ExpansionTankInput {
  /// Total system water volume (liters or gallons depending on unit system)
  final double systemVolume;

  /// Initial temperature (°C or °F)
  final double tempInitialC;

  /// Final (max) operating temperature (°C or °F)
  final double tempFinalC;

  /// Precharge (initial) gauge pressure (PSI or kPa)
  final double prechargePressure;

  /// Safety relief valve setting (PSI or kPa)
  final double reliefPressure;

  /// Glycol concentration (0.0–1.0)
  final double glycolConcentration;

  /// Tank type
  final ExpansionTankType tankType;

  /// Unit system
  final UnitSystem unit;

  const ExpansionTankInput({
    required this.systemVolume,
    required this.tempInitialC,
    required this.tempFinalC,
    required this.prechargePressure,
    required this.reliefPressure,
    this.glycolConcentration = 0.0,
    this.tankType = ExpansionTankType.closedDiaphragm,
    this.unit = UnitSystem.imperial,
  });
}

/// Result of expansion tank sizing.
class ExpansionTankResult {
  /// Required tank volume (in selected unit)
  final double requiredVolume;
  final double requiredVolumeLiters;
  final double requiredVolumeGallons;

  /// Acceptance volume — extra volume reserved at acceptance (typically 20%)
  final double acceptanceVolumeLiters;
  final double acceptanceVolumeGallons;

  /// Total tank size including acceptance factor
  final double totalVolumeLiters;
  final double totalVolumeGallons;

  /// Effective expansion volume (ΔV due to heating)
  final double expansionVolumeLiters;
  final double expansionVolumeGallons;

  /// Effective water expansion coefficient used
  final double expansionCoeff; // per °C

  /// Pressure ratios
  final double prechargeRatio; // P_i / P_f (should be < 1)

  /// Temperature rise
  final double tempRiseC;

  /// Recommended standard tank size (rounded up)
  final double recommendedStandardSizeGal;
  final double recommendedStandardSizeL;

  /// Warnings
  final List<String> warnings;

  const ExpansionTankResult({
    required this.requiredVolume,
    required this.requiredVolumeLiters,
    required this.requiredVolumeGallons,
    required this.acceptanceVolumeLiters,
    required this.acceptanceVolumeGallons,
    required this.totalVolumeLiters,
    required this.totalVolumeGallons,
    required this.expansionVolumeLiters,
    required this.expansionVolumeGallons,
    required this.expansionCoeff,
    required this.prechargeRatio,
    required this.tempRiseC,
    required this.recommendedStandardSizeGal,
    required this.recommendedStandardSizeL,
    required this.warnings,
  });
}

/// Engine for closed-type expansion tank sizing (ASPE 2003 / ITT Bell & Gossett).
class ExpansionTankEngine {
  ExpansionTankEngine._();

  /// Standard recommended acceptance volumes (extra factor): 20% typical.
  static const double acceptanceFactor = 0.20;

  /// Standard tank sizes available (commercial diaphragmatic, gallons).
  static const List<double> standardSizesGal = [
    2,
    4.4,
    7.6,
    14,
    20,
    30,
    40,
    60,
    80,
    100,
    130,
    160,
    200,
    250,
    300,
  ];

  /// Calculate required expansion tank volume.
  ///
  /// Formula (ASPE simplified):
  ///   V_t = V_s × [ η × ΔT / (1 − P_i/P_f) ]
  ///
  /// where η is volumetric expansion coefficient (per °C):
  ///   - Water at 20–90 °C:  0.00404  (= ~0.0004/°C)
  ///   - 30% glycol:         0.00609 (approx)
  ///   - 50% glycol:         0.00802
  static ExpansionTankResult? calculate(ExpansionTankInput input) {
    if (input.systemVolume <= 0) return null;
    if (input.tempFinalC <= input.tempInitialC) return null;
    if (input.prechargePressure <= 0 || input.reliefPressure <= 0) return null;

    final warnings = <String>[];

    // Convert to SI internally (liters, kPa, °C)
    final volumeLiters = input.unit == UnitSystem.imperial
        ? input.systemVolume *
              3.78541 // gal → L
        : input.systemVolume;

    final prechargeKpa = input.unit == UnitSystem.imperial
        ? input.prechargePressure *
              6.89476 // PSI → kPa
        : input.prechargePressure;
    final reliefKpa = input.unit == UnitSystem.imperial
        ? input.reliefPressure * 6.89476
        : input.reliefPressure;

    // Convert temperatures to °C for physics calculations
    final tempInitialInC = input.unit == UnitSystem.imperial
        ? (input.tempInitialC - 32.0) * 5.0 / 9.0
        : input.tempInitialC;
    final tempFinalInC = input.unit == UnitSystem.imperial
        ? (input.tempFinalC - 32.0) * 5.0 / 9.0
        : input.tempFinalC;
    final tempRiseCForWarn = tempFinalInC - tempInitialInC;

    // Expansion coefficient (per °C)
    final coeff = _expansionCoefficient(input.glycolConcentration);

    // Pressure ratio (must be < 1 for precharge < relief)
    // Use absolute pressures (add atmospheric if not absolute)
    final atmKpa = 101.325;
    final prechargeAbs = prechargeKpa + atmKpa;
    final reliefAbs = reliefKpa + atmKpa;

    if (prechargeAbs >= reliefAbs) {
      // Physically invalid configuration: precharge must be less than relief
      // so the system has pressurization range available.
      return null;
    }

    // Expansion volume ΔV = V_s × η × ΔT (in °C)
    final expansionLiters = volumeLiters * coeff * tempRiseCForWarn;
    final expansionGal = expansionLiters / 3.78541;

    // V_t = ΔV / (1 − P_i/P_f)
    final pressureFactor = 1.0 - prechargeAbs / reliefAbs;
    if (pressureFactor <= 0.01) {
      warnings.add(
        'Pressure ratio too close to 1.0 — relief and precharge pressures '
        'must be sufficiently different.',
      );
      return null;
    }

    var totalLiters = expansionLiters / pressureFactor;
    var totalGal = totalLiters / 3.78541;

    // Add acceptance factor (20%)
    final acceptanceLiters = totalLiters * acceptanceFactor;
    final acceptanceGal = acceptanceLiters / 3.78541;
    totalLiters += acceptanceLiters;
    totalGal += acceptanceGal;

    // Determine which is "required volume" without acceptance
    final requiredLiters = totalLiters - acceptanceLiters;
    final requiredGal = requiredLiters / 3.78541;

    // Round up to nearest standard size
    final standardSizeL = _roundUpToStandardSize(totalLiters, isGallon: false);
    final standardSizeGal = _roundUpToStandardSize(totalGal, isGallon: true);

    // Warnings
    if (prechargeAbs / reliefAbs > 0.8) {
      warnings.add(
        'Precharge pressure is more than 80% of relief pressure — large tank.',
      );
    }
    if (tempRiseCForWarn > 100) {
      warnings.add(
        'temperature rise > 100 °C — verify fluid is suitable for the system.',
      );
    }
    if (input.glycolConcentration > 0.4) {
      warnings.add(
        'Glycol concentration > 40% — physical properties may differ.',
      );
    }

    return ExpansionTankResult(
      requiredVolume: input.unit == UnitSystem.imperial
          ? requiredGal
          : requiredLiters,
      requiredVolumeLiters: requiredLiters,
      requiredVolumeGallons: requiredGal,
      acceptanceVolumeLiters: acceptanceLiters,
      acceptanceVolumeGallons: acceptanceGal,
      totalVolumeLiters: totalLiters,
      totalVolumeGallons: totalGal,
      expansionVolumeLiters: expansionLiters,
      expansionVolumeGallons: expansionGal,
      expansionCoeff: coeff,
      prechargeRatio: prechargeAbs / reliefAbs,
      tempRiseC: tempRiseCForWarn,
      recommendedStandardSizeGal: standardSizeGal,
      recommendedStandardSizeL: standardSizeL,
      warnings: warnings,
    );
  }

  /// Volumetric expansion coefficient (per °C) for the given glycol %.
  ///
  /// Standard values from ITT Bell & Gossett / ASPE:
  /// - Water: 0.000378 (avg 20–90 °C, conservative)
  /// - 20% glycol: 0.000584
  /// - 30% glycol: 0.000733
  /// - 50% glycol: 0.000989
  static double _expansionCoefficient(double glycolPct) {
    const waterCoeff = 0.000378;
    if (glycolPct <= 0) return waterCoeff;
    if (glycolPct <= 0.20) {
      // Interpolate water → 20% glycol
      final t = glycolPct / 0.20;
      return _lerp(waterCoeff, 0.000584, t);
    }
    if (glycolPct <= 0.30) {
      final t = (glycolPct - 0.20) / 0.10;
      return _lerp(0.000584, 0.000733, t);
    }
    if (glycolPct <= 0.50) {
      final t = (glycolPct - 0.30) / 0.20;
      return _lerp(0.000733, 0.000989, t);
    }
    return 0.000989;
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double _roundUpToStandardSize(double value, {required bool isGallon}) {
    final sizes = isGallon ? standardSizesGal : _standardSizesLiters();
    for (final s in sizes) {
      if (s >= value) return s;
    }
    // Beyond standard range — round up to next 50 (gal) or 100 (L)
    if (isGallon) {
      return ((value / 50).ceil() * 50).toDouble();
    }
    return ((value / 100).ceil() * 100).toDouble();
  }

  static List<double> _standardSizesLiters() {
    return const [
      8,
      15,
      20,
      35,
      50,
      80,
      100,
      150,
      200,
      300,
      400,
      500,
      600,
      750,
      1000,
    ];
  }
}

/// Convenience alias.
typedef ExpansionTankCalculator = ExpansionTankEngine;
