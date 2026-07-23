import 'dart:math';

import '../../../core/hvac/models/enums.dart';
import '../constants/air_distribution_constants.dart';
import 'duct_pressure_loss_engine.dart' show DuctRoughness;

enum VelocityReductionRoundDuctSize {
  d4,
  d5,
  d6,
  d7,
  d8,
  d9,
  d10,
  d12,
  d14,
  d16,
  d18,
  d20,
  d22,
  d24,
  d26,
  d28,
  d30,
  d32,
  d36,
  d40,
  d44,
  d48,
}

extension VelocityReductionRoundDuctSizeExt on VelocityReductionRoundDuctSize {
  double get diameterIn {
    switch (this) {
      case VelocityReductionRoundDuctSize.d4:
        return 4;
      case VelocityReductionRoundDuctSize.d5:
        return 5;
      case VelocityReductionRoundDuctSize.d6:
        return 6;
      case VelocityReductionRoundDuctSize.d7:
        return 7;
      case VelocityReductionRoundDuctSize.d8:
        return 8;
      case VelocityReductionRoundDuctSize.d9:
        return 9;
      case VelocityReductionRoundDuctSize.d10:
        return 10;
      case VelocityReductionRoundDuctSize.d12:
        return 12;
      case VelocityReductionRoundDuctSize.d14:
        return 14;
      case VelocityReductionRoundDuctSize.d16:
        return 16;
      case VelocityReductionRoundDuctSize.d18:
        return 18;
      case VelocityReductionRoundDuctSize.d20:
        return 20;
      case VelocityReductionRoundDuctSize.d22:
        return 22;
      case VelocityReductionRoundDuctSize.d24:
        return 24;
      case VelocityReductionRoundDuctSize.d26:
        return 26;
      case VelocityReductionRoundDuctSize.d28:
        return 28;
      case VelocityReductionRoundDuctSize.d30:
        return 30;
      case VelocityReductionRoundDuctSize.d32:
        return 32;
      case VelocityReductionRoundDuctSize.d36:
        return 36;
      case VelocityReductionRoundDuctSize.d40:
        return 40;
      case VelocityReductionRoundDuctSize.d44:
        return 44;
      case VelocityReductionRoundDuctSize.d48:
        return 48;
    }
  }

  double get diameterFt => diameterIn / 12.0;
  double get areaSqFt => pi * pow(diameterFt / 2, 2);
}

class DuctSection {
  final String name;
  final double airflowCfm;
  final double lengthFt;
  final int sectionIndex;

  const DuctSection({
    required this.name,
    required this.airflowCfm,
    required this.lengthFt,
    required this.sectionIndex,
  });
}

class VelocityReductionInput {
  final double airflowCfm;
  final double initialVelocityFpm;
  final int numberOfSections;
  final double reductionRatio; // e.g. 0.8 = reduce to 80% each section
  final double lengthFt;
  final DuctType ductType;
  final DuctMaterial material;
  final DuctShape shape;
  final UnitSystem unit;
  final double maxFrictionRateInWg100ft;
  final double? aspectRatio;

  const VelocityReductionInput({
    required this.airflowCfm,
    required this.initialVelocityFpm,
    required this.numberOfSections,
    required this.reductionRatio,
    required this.lengthFt,
    required this.ductType,
    required this.material,
    required this.shape,
    required this.unit,
    required this.maxFrictionRateInWg100ft,
    this.aspectRatio,
  });

  double get airflowM3h =>
      unit == UnitSystem.imperial ? airflowCfm * 1.699 : airflowCfm;

  double get initialVelocityMs => unit == UnitSystem.imperial
      ? initialVelocityFpm / 196.85
      : initialVelocityFpm;

  double get totalLengthFt => lengthFtActual * numberOfSections;

  double get lengthFtActual => unit == UnitSystem.imperial
      ? lengthFt
      : lengthFt / AirDistributionConstants.ftToM;

  double get lengthM => unit == UnitSystem.imperial
      ? lengthFt * AirDistributionConstants.ftToM
      : lengthFt;

  double get totalLengthM => lengthM * numberOfSections;
}

class VelocitySectionResult {
  final int sectionIndex;
  final String name;
  final double airflowCfm;
  final double velocityFpm;
  final double velocityMs;
  final double velocityPressureInWg;
  final double velocityPressurePa;
  final double? roundDiameterIn;
  final double? rectWidthIn;
  final double? rectHeightIn;
  final double areaSqFt;
  final double frictionRateInWg100ft;
  final double frictionRatePaPerM;
  final double frictionLossInWg;
  final double frictionLossPa;
  final double reynolds;
  final double frictionFactor;
  final double equivalentDiameterIn;
  final bool meetsVelocityLimit;
  final bool meetsFrictionLimit;
  final double reductionPct;

  const VelocitySectionResult({
    required this.sectionIndex,
    required this.name,
    required this.airflowCfm,
    required this.velocityFpm,
    required this.velocityMs,
    required this.velocityPressureInWg,
    required this.velocityPressurePa,
    this.roundDiameterIn,
    this.rectWidthIn,
    this.rectHeightIn,
    required this.areaSqFt,
    required this.frictionRateInWg100ft,
    required this.frictionRatePaPerM,
    required this.frictionLossInWg,
    required this.frictionLossPa,
    required this.reynolds,
    required this.frictionFactor,
    required this.equivalentDiameterIn,
    required this.meetsVelocityLimit,
    required this.meetsFrictionLimit,
    required this.reductionPct,
  });
}

class VelocityReductionResult {
  final VelocityReductionInput input;
  final List<VelocitySectionResult> sections;
  final double totalFrictionLossInWg;
  final double totalFrictionLossPa;
  final double finalVelocityFpm;
  final double totalReductionPct;
  final String? warning;

  const VelocityReductionResult({
    required this.input,
    required this.sections,
    required this.totalFrictionLossInWg,
    required this.totalFrictionLossPa,
    required this.finalVelocityFpm,
    required this.totalReductionPct,
    this.warning,
  });
}

class VelocityReductionEngine {
  static const double _rho = 1.2;
  static const double _mu = 1.81e-5;

  /// Velocity Reduction Method (also called "Constant Velocity Reduction").
  ///
  /// The duct main is divided into sections; each successive section has a
  /// reduced velocity, sized so the friction rate is approximately constant
  /// or within limits. Common ratios: 0.6-0.8.
  static VelocityReductionResult? calculate(VelocityReductionInput input) {
    if (input.airflowCfm <= 0 ||
        input.initialVelocityFpm <= 0 ||
        input.numberOfSections <= 0) {
      return null;
    }

    // Velocity limits based on duct type
    final limits = AirDistributionConstants.ductVelocityLimits[input.ductType];
    final maxVel = (limits?.max ?? input.initialVelocityFpm).toDouble();

    if (input.reductionRatio <= 0 || input.reductionRatio >= 1) {
      return null;
    }

    // Build sections
    // Each section keeps some fraction of the total airflow
    // First section: full airflow. Each subsequent section: airflow * ratio
    final roughness = DuctRoughness.get(input.material);

    // Convert metric → imperial for internal calculations
    // (engine works in FPM and CFM)
    final initialVelocityFpmEffective = input.unit == UnitSystem.imperial
        ? input.initialVelocityFpm
        : input.initialVelocityFpm * 196.85;
    final airflowCfmEffective = input.unit == UnitSystem.imperial
        ? input.airflowCfm
        : input.airflowCfm * 0.5886;

    final sections = <VelocitySectionResult>[];
    double currentVelocity = initialVelocityFpmEffective;
    double currentAirflow = airflowCfmEffective;
    double totalFriction = 0;
    double initialVel = initialVelocityFpmEffective;

    String? overallWarning;

    for (int i = 0; i < input.numberOfSections; i++) {
      // Reduce airflow and velocity for each subsequent section
      if (i > 0) {
        currentAirflow *= input.reductionRatio;
        currentVelocity *= input.reductionRatio;
      }

      // Find appropriate duct size for this velocity and airflow
      final selected = _selectSize(
        shape: input.shape,
        airflowCfm: currentAirflow,
        velocityFpm: currentVelocity,
        aspectRatio: input.aspectRatio ?? 2.0,
        material: input.material,
        roughness: roughness,
        maxFrictionRateInWg100ft: input.maxFrictionRateInWg100ft,
      );

      if (selected == null) {
        overallWarning =
            'Section $i: không tìm được size phù hợp. Giảm số section hoặc tăng initial velocity.';
        break;
      }

      // Compute friction loss for this section
      // Use lengthFtActual so that the unit field is honored
      final frictionLossInWg =
          selected.frictionRateInWg100ft * (input.lengthFtActual / 100.0);
      totalFriction += frictionLossInWg;

      // Build section name
      String sectionName;
      if (i == 0) {
        sectionName = 'Trục chính (Main)';
      } else if (i == input.numberOfSections - 1) {
        sectionName = 'Nhánh cuối (Last Branch)';
      } else {
        sectionName = 'Nhánh $i';
      }

      // Reduction pct relative to initial
      final reductionPct = i == 0
          ? 0.0
          : ((initialVel - currentVelocity) / initialVel) * 100.0;

      sections.add(
        VelocitySectionResult(
          sectionIndex: i,
          name: sectionName,
          airflowCfm: currentAirflow,
          velocityFpm: selected.actualVelocityFpm,
          velocityMs: selected.actualVelocityFpm / 196.85,
          velocityPressureInWg: selected.velocityPressureInWg,
          velocityPressurePa: selected.velocityPressurePa,
          roundDiameterIn: input.shape == DuctShape.round
              ? selected.roundSize?.diameterIn
              : null,
          rectWidthIn: input.shape == DuctShape.rectangular
              ? selected.rectWidthIn
              : null,
          rectHeightIn: input.shape == DuctShape.rectangular
              ? selected.rectHeightIn
              : null,
          areaSqFt: selected.areaSqFt,
          frictionRateInWg100ft: selected.frictionRateInWg100ft,
          frictionRatePaPerM: selected.frictionRatePaPerM,
          frictionLossInWg: frictionLossInWg,
          frictionLossPa: frictionLossInWg * AirDistributionConstants.inchToPa,
          reynolds: selected.reynolds,
          frictionFactor: selected.frictionFactor,
          equivalentDiameterIn: selected.equivalentDiameterIn,
          meetsVelocityLimit: selected.actualVelocityFpm <= maxVel,
          meetsFrictionLimit:
              selected.frictionRateInWg100ft <= input.maxFrictionRateInWg100ft,
          reductionPct: reductionPct,
        ),
      );
    }

    final finalVel = sections.isNotEmpty
        ? sections.last.velocityFpm
        : initialVelocityFpmEffective;
    final totalReduction = ((initialVel - finalVel) / initialVel) * 100.0;

    return VelocityReductionResult(
      input: input,
      sections: sections,
      totalFrictionLossInWg: totalFriction,
      totalFrictionLossPa: totalFriction * AirDistributionConstants.inchToPa,
      finalVelocityFpm: finalVel,
      totalReductionPct: totalReduction,
      warning: overallWarning,
    );
  }

  static _SizeSelection? _selectSize({
    required DuctShape shape,
    required double airflowCfm,
    required double velocityFpm,
    required double aspectRatio,
    required DuctMaterial material,
    required DuctRoughness roughness,
    required double maxFrictionRateInWg100ft,
  }) {
    if (shape == DuctShape.round) {
      return _selectRound(
        airflowCfm: airflowCfm,
        velocityFpm: velocityFpm,
        roughness: roughness,
        maxFrictionRateInWg100ft: maxFrictionRateInWg100ft,
      );
    } else {
      return _selectRect(
        airflowCfm: airflowCfm,
        velocityFpm: velocityFpm,
        aspectRatio: aspectRatio,
        roughness: roughness,
        maxFrictionRateInWg100ft: maxFrictionRateInWg100ft,
      );
    }
  }

  static _SizeSelection? _selectRound({
    required double airflowCfm,
    required double velocityFpm,
    required DuctRoughness roughness,
    required double maxFrictionRateInWg100ft,
  }) {
    // Find smallest round size that gives velocity <= target
    VelocityReductionRoundDuctSize? bestSize;
    double bestActualVel = 0;
    double bestArea = 0;
    for (final size in VelocityReductionRoundDuctSize.values) {
      final area = size.areaSqFt;
      final v = airflowCfm / area;
      if (v <= velocityFpm) {
        bestSize = size;
        bestActualVel = v;
        bestArea = area;
        break;
      }
    }
    // If no size found within target velocity, take largest available
    if (bestSize == null) {
      final size = VelocityReductionRoundDuctSize.d48;
      bestSize = size;
      bestActualVel = airflowCfm / size.areaSqFt;
      bestArea = size.areaSqFt;
    }

    // Compute friction for selected size
    final dhFt = bestSize.diameterFt;
    final dhIn = bestSize.diameterIn;
    final reynolds = (bestActualVel / 60) * dhFt / (_mu / _rho);
    final eD = roughness.absoluteRoughnessFt / dhFt;
    final f = _frictionFactor(reynolds, eD);
    // Corrected constant for ASHRAE Darcy-Weisbach with V in FPM, D in inches
    const double frictionConstant = 13413.0;
    final frictionRateInWg100ft =
        (f * bestActualVel * bestActualVel) / (frictionConstant * dhIn);
    final vpInWg = pow(bestActualVel / 4005.0, 2).toDouble();

    return _SizeSelection(
      roundSize: bestSize,
      areaSqFt: bestArea,
      actualVelocityFpm: bestActualVel,
      velocityPressureInWg: vpInWg,
      velocityPressurePa: vpInWg * AirDistributionConstants.inchToPa,
      frictionRateInWg100ft: frictionRateInWg100ft,
      frictionRatePaPerM:
          frictionRateInWg100ft * AirDistributionConstants.inWg100ftToPaPerM,
      reynolds: reynolds,
      frictionFactor: f,
      equivalentDiameterIn: dhIn,
    );
  }

  static _SizeSelection? _selectRect({
    required double airflowCfm,
    required double velocityFpm,
    required double aspectRatio,
    required DuctRoughness roughness,
    required double maxFrictionRateInWg100ft,
  }) {
    // Iterate through widths and pick best fit
    for (int widthIn = 6; widthIn <= 60; widthIn += 2) {
      final heightIn = (widthIn / aspectRatio).ceilToDouble();
      if (heightIn < 4 || heightIn > 60) continue;

      final widthFt = widthIn / 12.0;
      final heightFt = heightIn / 12.0;
      final area = widthFt * heightFt;
      final v = airflowCfm / area;
      if (v <= velocityFpm) {
        final perimeter = 2 * (widthFt + heightFt);
        final equivDiaFt = 4 * area / perimeter;
        final equivDiaIn = equivDiaFt * 12.0;
        final reynolds = (v / 60) * equivDiaFt / (_mu / _rho);
        final eD = roughness.absoluteRoughnessFt / equivDiaFt;
        final f = _frictionFactor(reynolds, eD);
        final frictionRate = (f * v * v) / (13413.0 * equivDiaIn);
        final vp = pow(v / 4005.0, 2).toDouble();

        return _SizeSelection(
          rectWidthIn: widthIn.toDouble(),
          rectHeightIn: heightIn,
          areaSqFt: area,
          actualVelocityFpm: v,
          velocityPressureInWg: vp,
          velocityPressurePa: vp * AirDistributionConstants.inchToPa,
          frictionRateInWg100ft: frictionRate,
          frictionRatePaPerM:
              frictionRate * AirDistributionConstants.inWg100ftToPaPerM,
          reynolds: reynolds,
          frictionFactor: f,
          equivalentDiameterIn: equivDiaIn,
        );
      }
    }

    // If no width fits, return largest
    final widthIn = 60.0;
    final heightIn = (60 / aspectRatio).ceilToDouble().clamp(4, 60).toDouble();
    final widthFt = widthIn / 12.0;
    final heightFt = heightIn / 12.0;
    final area = widthFt * heightFt;
    final v = airflowCfm / area;
    final perimeter = 2 * (widthFt + heightFt);
    final equivDiaFt = 4 * area / perimeter;
    final equivDiaIn = equivDiaFt * 12.0;
    final reynolds = (v / 60) * equivDiaFt / (_mu / _rho);
    final eD = roughness.absoluteRoughnessFt / equivDiaFt;
    final f = _frictionFactor(reynolds, eD);
    final frictionRate = (f * v * v) / (13413.0 * equivDiaIn);
    final vp = pow(v / 4005.0, 2).toDouble();
    return _SizeSelection(
      rectWidthIn: widthIn,
      rectHeightIn: heightIn,
      areaSqFt: area,
      actualVelocityFpm: v,
      velocityPressureInWg: vp,
      velocityPressurePa: vp * AirDistributionConstants.inchToPa,
      frictionRateInWg100ft: frictionRate,
      frictionRatePaPerM:
          frictionRate * AirDistributionConstants.inWg100ftToPaPerM,
      reynolds: reynolds,
      frictionFactor: f,
      equivalentDiameterIn: equivDiaIn,
    );
  }

  static double _frictionFactor(double re, double eD) {
    if (re <= 0) return 0;
    if (re < 2300) return 64 / re;
    final term = eD / 3.7 + 5.74 / pow(re, 0.9);
    if (term <= 0) return 0.02;
    return 0.25 / pow(log(term) / log(10), 2);
  }
}

class _SizeSelection {
  final VelocityReductionRoundDuctSize? roundSize;
  final double? rectWidthIn;
  final double? rectHeightIn;
  final double areaSqFt;
  final double actualVelocityFpm;
  final double velocityPressureInWg;
  final double velocityPressurePa;
  final double frictionRateInWg100ft;
  final double frictionRatePaPerM;
  final double reynolds;
  final double frictionFactor;
  final double equivalentDiameterIn;

  const _SizeSelection({
    this.roundSize,
    this.rectWidthIn,
    this.rectHeightIn,
    required this.areaSqFt,
    required this.actualVelocityFpm,
    required this.velocityPressureInWg,
    required this.velocityPressurePa,
    required this.frictionRateInWg100ft,
    required this.frictionRatePaPerM,
    required this.reynolds,
    required this.frictionFactor,
    required this.equivalentDiameterIn,
  });
}
