import 'dart:math';

import '../../../core/hvac/models/enums.dart';
import '../constants/air_distribution_constants.dart';
import 'duct_pressure_loss_engine.dart' show DuctRoughness;

enum EqualFrictionRoundDuctSize {
  // Standard round duct diameters (inches)
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

extension EqualFrictionRoundDuctSizeExt on EqualFrictionRoundDuctSize {
  double get diameterIn {
    switch (this) {
      case EqualFrictionRoundDuctSize.d4:
        return 4;
      case EqualFrictionRoundDuctSize.d5:
        return 5;
      case EqualFrictionRoundDuctSize.d6:
        return 6;
      case EqualFrictionRoundDuctSize.d7:
        return 7;
      case EqualFrictionRoundDuctSize.d8:
        return 8;
      case EqualFrictionRoundDuctSize.d9:
        return 9;
      case EqualFrictionRoundDuctSize.d10:
        return 10;
      case EqualFrictionRoundDuctSize.d12:
        return 12;
      case EqualFrictionRoundDuctSize.d14:
        return 14;
      case EqualFrictionRoundDuctSize.d16:
        return 16;
      case EqualFrictionRoundDuctSize.d18:
        return 18;
      case EqualFrictionRoundDuctSize.d20:
        return 20;
      case EqualFrictionRoundDuctSize.d22:
        return 22;
      case EqualFrictionRoundDuctSize.d24:
        return 24;
      case EqualFrictionRoundDuctSize.d26:
        return 26;
      case EqualFrictionRoundDuctSize.d28:
        return 28;
      case EqualFrictionRoundDuctSize.d30:
        return 30;
      case EqualFrictionRoundDuctSize.d32:
        return 32;
      case EqualFrictionRoundDuctSize.d36:
        return 36;
      case EqualFrictionRoundDuctSize.d40:
        return 40;
      case EqualFrictionRoundDuctSize.d44:
        return 44;
      case EqualFrictionRoundDuctSize.d48:
        return 48;
    }
  }

  double get diameterFt => diameterIn / 12.0;
  double get areaSqFt => pi * pow(diameterFt / 2, 2);
}

class EqualFrictionInput {
  final double airflowCfm;
  final double frictionRateInWg100ft; // Target friction rate
  final double lengthFt;
  final DuctType ductType;
  final DuctMaterial material;
  final DuctShape shape;
  final UnitSystem unit;
  final double maxVelocityFpm;
  final int? fixedAspectRatio;
  final int? fixedWidthIn;

  const EqualFrictionInput({
    required this.airflowCfm,
    required this.frictionRateInWg100ft,
    required this.lengthFt,
    required this.ductType,
    required this.material,
    required this.shape,
    required this.unit,
    required this.maxVelocityFpm,
    this.fixedAspectRatio,
    this.fixedWidthIn,
  });

  double get airflowM3s =>
      unit == UnitSystem.imperial ? airflowCfm / 2118.88 : airflowCfm / 3600;

  double get airflowM3h =>
      unit == UnitSystem.imperial ? airflowCfm * 1.699 : airflowCfm;

  double get airflowLs =>
      unit == UnitSystem.imperial ? airflowCfm * 0.4719 : airflowCfm / 3.6;

  /// CFM value for engine calculations.
  /// In metric mode, [airflowCfm] holds m³/h, so convert to CFM.
  double get airflowCfmEffective =>
      unit == UnitSystem.imperial ? airflowCfm : airflowCfm * 0.5886;

  double get frictionRatePaPerM =>
      frictionRateInWg100ft * AirDistributionConstants.inWg100ftToPaPerM;

  double get lengthM => unit == UnitSystem.imperial
      ? lengthFt * AirDistributionConstants.ftToM
      : lengthFt;

  double get lengthFtActual => unit == UnitSystem.imperial
      ? lengthFt
      : lengthFt / AirDistributionConstants.ftToM;

  double get maxVelocityMs =>
      unit == UnitSystem.imperial ? maxVelocityFpm / 196.85 : maxVelocityFpm;

  /// Effective max velocity in FPM for engine comparison.
  /// In metric mode the field holds m/s, so convert to FPM.
  double get maxVelocityFpmEffective =>
      unit == UnitSystem.imperial ? maxVelocityFpm : maxVelocityFpm * 196.85;
}

class RoundSizeCandidate {
  final EqualFrictionRoundDuctSize size;
  final double velocityFpm;
  final double velocityMs;
  final double velocityPressureInWg;
  final double velocityPressurePa;
  final double actualFrictionRateInWg100ft;
  final double actualFrictionRatePaPerM;
  final double hydraulicDiameterIn;
  final double reynolds;
  final double frictionFactor;
  final double meetsVelocity;
  final double meetsFriction;
  final double? frictionDeviationPct;
  final bool isSelected;

  const RoundSizeCandidate({
    required this.size,
    required this.velocityFpm,
    required this.velocityMs,
    required this.velocityPressureInWg,
    required this.velocityPressurePa,
    required this.actualFrictionRateInWg100ft,
    required this.actualFrictionRatePaPerM,
    required this.hydraulicDiameterIn,
    required this.reynolds,
    required this.frictionFactor,
    required this.meetsVelocity,
    required this.meetsFriction,
    this.frictionDeviationPct,
    required this.isSelected,
  });
}

class RectangularCandidate {
  final double widthIn;
  final double heightIn;
  final double aspectRatio;
  final double velocityFpm;
  final double velocityMs;
  final double velocityPressureInWg;
  final double velocityPressurePa;
  final double actualFrictionRateInWg100ft;
  final double actualFrictionRatePaPerM;
  final double equivalentDiameterIn;
  final double reynolds;
  final double frictionFactor;
  final bool meetsVelocity;
  final bool meetsFriction;
  final double? frictionDeviationPct;
  final bool isSelected;

  const RectangularCandidate({
    required this.widthIn,
    required this.heightIn,
    required this.aspectRatio,
    required this.velocityFpm,
    required this.velocityMs,
    required this.velocityPressureInWg,
    required this.velocityPressurePa,
    required this.actualFrictionRateInWg100ft,
    required this.actualFrictionRatePaPerM,
    required this.equivalentDiameterIn,
    required this.reynolds,
    required this.frictionFactor,
    required this.meetsVelocity,
    required this.meetsFriction,
    this.frictionDeviationPct,
    required this.isSelected,
  });
}

class EqualFrictionResult {
  final EqualFrictionInput input;
  final double airflowCfm;
  final double airflowM3h;
  final double airflowLs;
  final double targetFrictionRateInWg100ft;
  final double targetFrictionRatePaPerM;
  final List<RoundSizeCandidate> roundCandidates;
  final List<RectangularCandidate> rectangularCandidates;
  final EqualFrictionRoundDuctSize? selectedRoundSize;
  final RectangularCandidate? selectedRectangular;
  final String? sizeWarning;
  final String? frictionWarning;
  final String? velocityWarning;

  const EqualFrictionResult({
    required this.input,
    required this.airflowCfm,
    required this.airflowM3h,
    required this.airflowLs,
    required this.targetFrictionRateInWg100ft,
    required this.targetFrictionRatePaPerM,
    required this.roundCandidates,
    required this.rectangularCandidates,
    this.selectedRoundSize,
    this.selectedRectangular,
    this.sizeWarning,
    this.frictionWarning,
    this.velocityWarning,
  });

  double get totalFrictionLossInWg {
    final lenFt = input.unit == UnitSystem.imperial
        ? input.lengthFt
        : input.lengthFt / AirDistributionConstants.ftToM;
    return targetFrictionRateInWg100ft * (lenFt / 100.0);
  }

  double get totalFrictionLossPa => targetFrictionRatePaPerM * input.lengthM;

  bool get hasSelection =>
      selectedRoundSize != null || selectedRectangular != null;
}

class EqualFrictionEngine {
  static const double _rho = 1.2;
  static const double _mu = 1.81e-5;

  /// Calculate Equal Friction duct sizing.
  ///
  /// Equal Friction method: select duct size such that friction rate
  /// (pressure loss per 100 ft) is constant throughout the system.
  /// Common target: 0.10 in.wg/100ft for commercial HVAC.
  static EqualFrictionResult calculate(EqualFrictionInput input) {
    if (input.airflowCfm <= 0 || input.lengthFt <= 0) {
      return _emptyResult(input);
    }

    if (input.shape == DuctShape.round) {
      return _calculateRound(input);
    } else {
      return _calculateRectangular(input);
    }
  }

  static EqualFrictionResult _emptyResult(EqualFrictionInput input) {
    return EqualFrictionResult(
      input: input,
      airflowCfm: input.airflowCfm,
      airflowM3h: input.airflowM3h,
      airflowLs: input.airflowLs,
      targetFrictionRateInWg100ft: input.frictionRateInWg100ft,
      targetFrictionRatePaPerM: input.frictionRatePaPerM,
      roundCandidates: const [],
      rectangularCandidates: const [],
    );
  }

  static EqualFrictionResult _calculateRound(EqualFrictionInput input) {
    final roughness = DuctRoughness.get(input.material);
    final airflowCfm = input.airflowCfmEffective;

    final candidates = <RoundSizeCandidate>[];

    // Iterate through all standard sizes
    for (final size in EqualFrictionRoundDuctSize.values) {
      final dhFt = size.diameterFt;
      final dhIn = size.diameterIn;
      final areaSqFt = size.areaSqFt;

      // Velocity
      final velocityFpm = airflowCfm / areaSqFt;
      final velocityMs = velocityFpm / 196.85;

      // Reynolds
      final reynolds =
          (velocityFpm / 60) * (dhFt) / (_mu / _rho); // ft/s × ft / (ft²/s)

      // Friction factor
      final eD = roughness.absoluteRoughnessFt / dhFt;
      final f = _frictionFactor(reynolds, eD);

      // Friction rate (in.wg per 100 ft) using Darcy-Weisbach:
      // ΔP/100ft = f × (L/D) × ρV²/2
      // Derivation for standard air (ρ=1.2 kg/m³):
      //   L=100ft = 30.48m, V in FPM, D in inches
      //   → ΔP(in.wg/100ft) = f × V² / (D_in × 13413)
      // Reference: ASHRAE Handbook Fundamentals 2021, Ch.21, Eq.21
      const double frictionConstant = 13413.0;
      final frictionRateInWg100ft =
          (f * velocityFpm * velocityFpm) / (frictionConstant * dhIn);
      final frictionRatePaPerM =
          frictionRateInWg100ft * AirDistributionConstants.inWg100ftToPaPerM;

      // Velocity pressure
      final vpInWg = pow(velocityFpm / 4005.0, 2).toDouble();
      final vpPa = vpInWg * AirDistributionConstants.inchToPa;

      // Deviation from target
      final deviationPct = input.frictionRateInWg100ft > 0
          ? ((frictionRateInWg100ft - input.frictionRateInWg100ft) /
                    input.frictionRateInWg100ft) *
                100
          : 0.0;

      candidates.add(
        RoundSizeCandidate(
          size: size,
          velocityFpm: velocityFpm,
          velocityMs: velocityMs,
          velocityPressureInWg: vpInWg,
          velocityPressurePa: vpPa,
          actualFrictionRateInWg100ft: frictionRateInWg100ft,
          actualFrictionRatePaPerM: frictionRatePaPerM,
          hydraulicDiameterIn: dhIn,
          reynolds: reynolds,
          frictionFactor: f,
          meetsVelocity: velocityFpm <= input.maxVelocityFpmEffective ? 1 : 0,
          meetsFriction: frictionRateInWg100ft >= input.frictionRateInWg100ft
              ? 1
              : 0,
          frictionDeviationPct: deviationPct,
          isSelected: false,
        ),
      );
    }

    // Select: smallest size where friction rate >= target AND velocity <= max
    RoundSizeCandidate? selected;
    for (final c in candidates) {
      if (c.meetsFriction == 1 && c.meetsVelocity == 1) {
        selected = c;
        break;
      }
    }

    // Fallback 1: smallest with velocity <= max AND friction >= target
    // is preferred; if none, find smallest velocity-compliant
    if (selected == null) {
      for (final c in candidates) {
        if (c.meetsVelocity == 1) {
          selected = c;
          break;
        }
      }
    }

    // Final fallback: any size that satisfies friction (last resort, may have
    // high velocity — emit velocityWarning)
    if (selected == null) {
      for (final c in candidates) {
        if (c.meetsFriction == 1) {
          selected = c;
          break;
        }
      }
    }

    // Mark selected
    final markedCandidates = candidates.map((c) {
      return RoundSizeCandidate(
        size: c.size,
        velocityFpm: c.velocityFpm,
        velocityMs: c.velocityMs,
        velocityPressureInWg: c.velocityPressureInWg,
        velocityPressurePa: c.velocityPressurePa,
        actualFrictionRateInWg100ft: c.actualFrictionRateInWg100ft,
        actualFrictionRatePaPerM: c.actualFrictionRatePaPerM,
        hydraulicDiameterIn: c.hydraulicDiameterIn,
        reynolds: c.reynolds,
        frictionFactor: c.frictionFactor,
        meetsVelocity: c.meetsVelocity,
        meetsFriction: c.meetsFriction,
        frictionDeviationPct: c.frictionDeviationPct,
        isSelected: c.size == selected?.size,
      );
    }).toList();

    String? sizeWarning;
    if (selected == null) {
      sizeWarning =
          'Không tìm được size tiêu chuẩn nào đạt friction rate ${input.frictionRateInWg100ft.toStringAsFixed(3)} in.wg/100ft. Giảm friction rate hoặc tăng lưu lượng.';
    }

    String? velocityWarning;
    if (selected != null && selected.meetsVelocity == 0) {
      velocityWarning =
          'Velocity ${selected.velocityFpm.toStringAsFixed(0)} FPM > max ${input.maxVelocityFpmEffective.toStringAsFixed(0)} FPM. Có thể gây ồn.';
    }

    return EqualFrictionResult(
      input: input,
      airflowCfm: airflowCfm,
      airflowM3h: input.airflowM3h,
      airflowLs: input.airflowLs,
      targetFrictionRateInWg100ft: input.frictionRateInWg100ft,
      targetFrictionRatePaPerM: input.frictionRatePaPerM,
      roundCandidates: markedCandidates,
      rectangularCandidates: const [],
      selectedRoundSize: selected?.size,
      sizeWarning: sizeWarning,
      velocityWarning: velocityWarning,
    );
  }

  static EqualFrictionResult _calculateRectangular(EqualFrictionInput input) {
    final roughness = DuctRoughness.get(input.material);
    final airflowCfm = input.airflowCfmEffective;

    // Aspect ratio to use
    final aspectRatio = (input.fixedAspectRatio ?? 2.0).clamp(1.0, 8.0);

    // Generate standard rectangular sizes
    // For each width (in inches, rounded up to integer), compute height
    final widths = <int>[];
    for (int w = 6; w <= 60; w += 2) {
      widths.add(w);
    }

    final candidates = <RectangularCandidate>[];

    for (final widthIn in widths) {
      // If fixedWidthIn specified, only use that width
      if (input.fixedWidthIn != null && widthIn != input.fixedWidthIn) {
        continue;
      }

      final heightIn = (widthIn / aspectRatio).ceilToDouble().clamp(4.0, 60.0);

      final widthFt = widthIn / 12.0;
      final heightFt = heightIn / 12.0;
      final areaSqFt = widthFt * heightFt;

      // Velocity
      final velocityFpm = airflowCfm / areaSqFt;
      final velocityMs = velocityFpm / 196.85;

      // Equivalent diameter (for non-circular ducts)
      // De = 4 × Area / Perimeter = 2ab / (a+b)
      final perimeterFt = 2 * (widthFt + heightFt);
      final equivalentDiameterFt = 4 * areaSqFt / perimeterFt;
      final equivalentDiameterIn = equivalentDiameterFt * 12.0;

      // Reynolds based on equivalent diameter
      final reynolds = (velocityFpm / 60) * equivalentDiameterFt / (_mu / _rho);

      // Friction factor
      final eD = roughness.absoluteRoughnessFt / equivalentDiameterFt;
      final f = _frictionFactor(reynolds, eD);

      // Friction rate (in.wg per 100 ft) using Darcy-Weisbach with De
      // Same constant as round: ΔP = f × V² / (D × 13413) for V in FPM, D in inches
      const double frictionConstantRect = 13413.0;
      final frictionRateInWg100ft =
          (f * velocityFpm * velocityFpm) /
          (frictionConstantRect * equivalentDiameterIn);
      final frictionRatePaPerM =
          frictionRateInWg100ft * AirDistributionConstants.inWg100ftToPaPerM;

      // Velocity pressure
      final vpInWg = pow(velocityFpm / 4005.0, 2).toDouble();
      final vpPa = vpInWg * AirDistributionConstants.inchToPa;

      // Deviation from target
      final deviationPct = input.frictionRateInWg100ft > 0
          ? ((frictionRateInWg100ft - input.frictionRateInWg100ft) /
                    input.frictionRateInWg100ft) *
                100
          : 0.0;

      candidates.add(
        RectangularCandidate(
          widthIn: widthIn.toDouble(),
          heightIn: heightIn,
          aspectRatio: widthIn / heightIn,
          velocityFpm: velocityFpm,
          velocityMs: velocityMs,
          velocityPressureInWg: vpInWg,
          velocityPressurePa: vpPa,
          actualFrictionRateInWg100ft: frictionRateInWg100ft,
          actualFrictionRatePaPerM: frictionRatePaPerM,
          equivalentDiameterIn: equivalentDiameterIn,
          reynolds: reynolds,
          frictionFactor: f,
          meetsVelocity: velocityFpm <= input.maxVelocityFpmEffective,
          meetsFriction: frictionRateInWg100ft >= input.frictionRateInWg100ft,
          frictionDeviationPct: deviationPct,
          isSelected: false,
        ),
      );
    }

    // Select: smallest width where friction >= target AND velocity OK
    RectangularCandidate? selected;
    for (final c in candidates) {
      if (c.meetsFriction && c.meetsVelocity) {
        selected = c;
        break;
      }
    }

    // Fallback
    if (selected == null) {
      for (final c in candidates) {
        if (c.meetsFriction) {
          selected = c;
          break;
        }
      }
    }

    // Mark selected
    final markedCandidates = candidates.map((c) {
      return RectangularCandidate(
        widthIn: c.widthIn,
        heightIn: c.heightIn,
        aspectRatio: c.aspectRatio,
        velocityFpm: c.velocityFpm,
        velocityMs: c.velocityMs,
        velocityPressureInWg: c.velocityPressureInWg,
        velocityPressurePa: c.velocityPressurePa,
        actualFrictionRateInWg100ft: c.actualFrictionRateInWg100ft,
        actualFrictionRatePaPerM: c.actualFrictionRatePaPerM,
        equivalentDiameterIn: c.equivalentDiameterIn,
        reynolds: c.reynolds,
        frictionFactor: c.frictionFactor,
        meetsVelocity: c.meetsVelocity,
        meetsFriction: c.meetsFriction,
        frictionDeviationPct: c.frictionDeviationPct,
        isSelected:
            c.widthIn == selected?.widthIn && c.heightIn == selected?.heightIn,
      );
    }).toList();

    String? sizeWarning;
    if (selected == null) {
      sizeWarning =
          'Không tìm được size rectangular nào đạt friction rate ${input.frictionRateInWg100ft.toStringAsFixed(3)} in.wg/100ft.';
    }

    String? velocityWarning;
    if (selected != null && !selected.meetsVelocity) {
      velocityWarning =
          'Velocity ${selected.velocityFpm.toStringAsFixed(0)} FPM > max ${input.maxVelocityFpm.toStringAsFixed(0)} FPM.';
    }

    return EqualFrictionResult(
      input: input,
      airflowCfm: airflowCfm,
      airflowM3h: input.airflowM3h,
      airflowLs: input.airflowLs,
      targetFrictionRateInWg100ft: input.frictionRateInWg100ft,
      targetFrictionRatePaPerM: input.frictionRatePaPerM,
      roundCandidates: const [],
      rectangularCandidates: markedCandidates,
      selectedRectangular: selected,
      sizeWarning: sizeWarning,
      velocityWarning: velocityWarning,
    );
  }

  /// Colebrook-White friction factor via Swamee-Jain approximation
  static double _frictionFactor(double re, double eD) {
    if (re <= 0) return 0;
    if (re < 2300) return 64 / re;
    final term = eD / 3.7 + 5.74 / pow(re, 0.9);
    if (term <= 0) return 0.02;
    return 0.25 / pow(log(term) / log(10), 2);
  }
}
