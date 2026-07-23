import 'dart:math';

import '../../../core/hvac/models/enums.dart';
import '../data/diffuser_catalog.dart';

enum DiffuserSizingMethod { byAirflow, byRoom, byAch }

class DiffuserSelectionInput {
  final double totalCfm; // Total air volume to distribute
  final double roomLengthFt; // Room dimensions for ACH calc
  final double roomWidthFt;
  final double ceilingHeightFt;
  final double ach; // Air changes per hour
  final int diffuserCount; // Number of diffusers
  final double
  throwDistanceFt; // Target throw distance (typically 0.5-1.5× room length)
  final double mountingHeightFt; // Mounting height (for throw velocity calc)
  final double maxNeckVelocityFpm; // Override default from catalog
  final double maxNcRating; // Override default from catalog
  final DiffuserType diffuserType;
  final UnitSystem unit;
  final DiffuserSizingMethod method;

  const DiffuserSelectionInput({
    required this.totalCfm,
    required this.roomLengthFt,
    required this.roomWidthFt,
    required this.ceilingHeightFt,
    required this.ach,
    required this.diffuserCount,
    required this.throwDistanceFt,
    required this.mountingHeightFt,
    required this.maxNeckVelocityFpm,
    required this.maxNcRating,
    required this.diffuserType,
    required this.unit,
    required this.method,
  });

  double get totalM3h =>
      unit == UnitSystem.imperial ? totalCfm * 1.699 : totalCfm;

  double get totalCfmEffective =>
      unit == UnitSystem.imperial ? totalCfm : totalCfm * 0.5886;

  double get roomLengthM =>
      unit == UnitSystem.imperial ? roomLengthFt * 0.3048 : roomLengthFt;

  double get roomLengthFtActual =>
      unit == UnitSystem.imperial ? roomLengthFt : roomLengthFt / 0.3048;

  double get roomWidthM =>
      unit == UnitSystem.imperial ? roomWidthFt * 0.3048 : roomWidthFt;

  double get roomWidthFtActual =>
      unit == UnitSystem.imperial ? roomWidthFt : roomWidthFt / 0.3048;

  double get ceilingHeightM =>
      unit == UnitSystem.imperial ? ceilingHeightFt * 0.3048 : ceilingHeightFt;

  double get ceilingHeightFtActual =>
      unit == UnitSystem.imperial ? ceilingHeightFt : ceilingHeightFt / 0.3048;

  double get throwDistanceM =>
      unit == UnitSystem.imperial ? throwDistanceFt * 0.3048 : throwDistanceFt;

  double get mountingHeightM => unit == UnitSystem.imperial
      ? mountingHeightFt * 0.3048
      : mountingHeightFt;

  /// Room volume in m³ (for ACH calc)
  double get roomVolumeM3 => roomLengthM * roomWidthM * ceilingHeightM;

  /// Room volume in ft³ — always correct regardless of stored unit
  double get roomVolumeFt3 =>
      roomLengthFtActual * roomWidthFtActual * ceilingHeightFtActual;
}

class DiffuserSelectionPerUnit {
  final DiffuserSize size;
  final double cfmPerDiffuser;
  final double cfmPerSqFt;
  final double neckVelocityFpm;
  final double neckVelocityMs;
  final double throwVelocityFpm;
  final double throwVelocityMs;
  final double throwDistanceFt;
  final double pressureDropInWg;
  final double pressureDropPa;
  final int ncRating;
  final double areaSqFt;
  final bool meetsNeckVelocity;
  final bool meetsThrow;
  final bool meetsNc;
  final String? warning;

  const DiffuserSelectionPerUnit({
    required this.size,
    required this.cfmPerDiffuser,
    required this.cfmPerSqFt,
    required this.neckVelocityFpm,
    required this.neckVelocityMs,
    required this.throwVelocityFpm,
    required this.throwVelocityMs,
    required this.throwDistanceFt,
    required this.pressureDropInWg,
    required this.pressureDropPa,
    required this.ncRating,
    required this.areaSqFt,
    required this.meetsNeckVelocity,
    required this.meetsThrow,
    required this.meetsNc,
    this.warning,
  });
}

class DiffuserSelectionResult {
  final double totalCfm;
  final double cfmPerDiffuser;
  final int diffuserCount;
  final double roomAreaSqFt;
  final double roomAreaM2;
  final double roomVolumeFt3;
  final double roomVolumeM3;
  final double effectiveAch;
  final DiffuserDefinition diffuserDefinition;
  final DiffuserSize? selectedSize;
  final List<DiffuserSelectionPerUnit> alternatives;
  final String? sizeWarning;
  final String? achWarning;
  final String? throwWarning;
  final DiffuserSelectionInput input;

  const DiffuserSelectionResult({
    required this.totalCfm,
    required this.cfmPerDiffuser,
    required this.diffuserCount,
    required this.roomAreaSqFt,
    required this.roomAreaM2,
    required this.roomVolumeFt3,
    required this.roomVolumeM3,
    required this.effectiveAch,
    required this.diffuserDefinition,
    required this.selectedSize,
    required this.alternatives,
    this.sizeWarning,
    this.achWarning,
    this.throwWarning,
    required this.input,
  });
}

class DiffuserSelectionEngine {
  /// Calculate diffuser selection per ASHRAE and SMACNA guidelines.
  /// Selects smallest size that satisfies all criteria (neck velocity,
  /// throw distance, NC rating).
  static DiffuserSelectionResult? calculate(DiffuserSelectionInput input) {
    if (input.diffuserCount <= 0) return null;

    final def = DiffuserCatalog.get(input.diffuserType);

    // Step 1: Determine total CFM if method is by ACH
    double totalCfm = input.totalCfmEffective;
    if (input.method == DiffuserSizingMethod.byRoom ||
        input.method == DiffuserSizingMethod.byAch) {
      if (input.method == DiffuserSizingMethod.byAch) {
        // CFM = (Volume × ACH) / 60
        // Use ft³ directly via getter so unit conversion is correct
        final volFt3 = input.roomVolumeFt3;
        if (volFt3 <= 0) return null;
        totalCfm = (volFt3 * input.ach) / 60;
      } else {
        // byRoom — totalCfm already given
        if (totalCfm <= 0) return null;
      }
    } else {
      if (totalCfm <= 0) return null;
    }

    // Step 2: CFM per diffuser
    final cfmPerDiffuser = totalCfm / input.diffuserCount;

    // Step 3: Build candidates from catalog
    final candidates = <DiffuserSelectionPerUnit>[];

    for (final size in def.availableSizes) {
      final area = size.area;
      final cfmPerSqFt = cfmPerDiffuser / area;
      final neckArea = size.neckAreaSqFt ?? area;
      // Neck velocity = CFM / neck area
      final neckVelocityFpm = cfmPerDiffuser / neckArea;
      final neckVelocityMs = neckVelocityFpm * 0.00508;

      // Throw distance (simple model): T = K × V_neck × sqrt(Cd) / V_terminal
      // Simplified: T = 0.6 × V_neck / (50 × mounting factor)
      // For ceiling diffusers, terminal velocity typically 50 FPM
      final mountingFactor = (input.mountingHeightFt / 8).clamp(0.7, 1.5);
      final throwDistanceFt = (neckVelocityFpm / 60) * mountingFactor;

      // Throw velocity at terminal (assumed 50 FPM for occupied zones)
      final throwVelocityFpm = neckVelocityFpm * 0.6;
      final throwVelocityMs = throwVelocityFpm * 0.00508;

      // Pressure drop: ΔP = (V_neck / 4005)² — typical formula
      final pressureDropInWg =
          (neckVelocityFpm / 4005) * (neckVelocityFpm / 4005);
      final pressureDropPa = pressureDropInWg * 248.84;

      // NC rating estimation based on neck velocity
      // Rough rule: NC ≈ 20 + log10(V_neck / 100) × 15 (clamped)
      final ncRating = (20 + (log(neckVelocityFpm / 100) / ln10) * 15)
          .round()
          .clamp(20, 50);

      // Checks
      final meetsNeck = neckVelocityFpm <= input.maxNeckVelocityFpm;
      final targetThrow = input.throwDistanceFt;
      final meetsThrow =
          (targetThrow > 0 &&
              (throwDistanceFt >= targetThrow * 0.7 &&
                  throwDistanceFt <= targetThrow * 1.3)) ||
          targetThrow == 0;
      final meetsNc = ncRating <= input.maxNcRating;

      String? warning;
      if (!meetsNeck) {
        warning =
            'Vận tốc cổ ${neckVelocityFpm.toStringAsFixed(0)} FPM vượt giới hạn (${input.maxNeckVelocityFpm.toStringAsFixed(0)} FPM) — gây ồn.';
      } else if (cfmPerSqFt > def.maxCfmPerSqFt) {
        warning =
            'CFM/sqft ${cfmPerSqFt.toStringAsFixed(2)} vượt max ${def.maxCfmPerSqFt} — nên chọn size lớn hơn hoặc thêm diffuser.';
      }

      candidates.add(
        DiffuserSelectionPerUnit(
          size: size,
          cfmPerDiffuser: cfmPerDiffuser,
          cfmPerSqFt: cfmPerSqFt,
          neckVelocityFpm: neckVelocityFpm,
          neckVelocityMs: neckVelocityMs,
          throwVelocityFpm: throwVelocityFpm,
          throwVelocityMs: throwVelocityMs,
          throwDistanceFt: throwDistanceFt,
          pressureDropInWg: pressureDropInWg,
          pressureDropPa: pressureDropPa,
          ncRating: ncRating,
          areaSqFt: area,
          meetsNeckVelocity: meetsNeck,
          meetsThrow: meetsThrow,
          meetsNc: meetsNc,
          warning: warning,
        ),
      );
    }

    // Step 4: Select first size that meets all criteria
    DiffuserSize? selectedSize;
    DiffuserSelectionPerUnit? selectedPerUnit;
    for (int i = 0; i < candidates.length; i++) {
      final c = candidates[i];
      if (c.meetsNeckVelocity && c.meetsThrow && c.meetsNc) {
        selectedSize = c.size;
        selectedPerUnit = c;
        break;
      }
    }

    // If none meet all, pick the closest one
    String? sizeWarning;
    if (selectedSize == null && candidates.isNotEmpty) {
      // Find candidate with best score
      DiffuserSelectionPerUnit? best;
      double bestScore = double.infinity;
      for (final c in candidates) {
        double score = 0;
        if (!c.meetsNeckVelocity) score += 1000;
        if (!c.meetsThrow) score += 100;
        if (!c.meetsNc) score += 200;
        if (c.warning != null) score += 10;
        if (score < bestScore) {
          bestScore = score;
          best = c;
        }
      }
      if (best != null) {
        selectedSize = best.size;
        selectedPerUnit = best;
        sizeWarning =
            'Không có size nào đáp ứng đầy đủ tiêu chí. Size chọn gần nhất: ${best.size.width}×${best.size.length}".';
      }
    }

    // Step 5: Room stats
    final roomAreaSqFt = input.roomLengthFtActual * input.roomWidthFtActual;
    final roomAreaM2 = input.roomLengthM * input.roomWidthM;
    final roomVolumeFt3 = input.roomVolumeFt3;
    final roomVolumeM3 = input.roomVolumeM3;

    // Effective ACH (only meaningful if we have volume)
    double effectiveAch = 0;
    if (roomVolumeFt3 > 0) {
      effectiveAch = (totalCfm * 60) / roomVolumeFt3;
    }

    // Warnings
    String? achWarning;
    if (effectiveAch > 0 &&
        (effectiveAch < input.ach * 0.9 || effectiveAch > input.ach * 1.5)) {
      achWarning =
          'ACH thực tế ${effectiveAch.toStringAsFixed(1)} khác xa mục tiêu ${input.ach.toStringAsFixed(1)} — kiểm tra lại thể tích phòng hoặc lưu lượng.';
    }

    String? throwWarning;
    if (selectedPerUnit != null &&
        input.throwDistanceFt > 0 &&
        !selectedPerUnit.meetsThrow) {
      throwWarning =
          'Throw ${selectedPerUnit.throwDistanceFt.toStringAsFixed(1)} ft không đạt yêu cầu ${input.throwDistanceFt.toStringAsFixed(1)} ft.';
    }

    return DiffuserSelectionResult(
      totalCfm: totalCfm,
      cfmPerDiffuser: cfmPerDiffuser,
      diffuserCount: input.diffuserCount,
      roomAreaSqFt: roomAreaSqFt,
      roomAreaM2: roomAreaM2,
      roomVolumeFt3: roomVolumeFt3,
      roomVolumeM3: roomVolumeM3,
      effectiveAch: effectiveAch,
      diffuserDefinition: def,
      selectedSize: selectedSize,
      alternatives: candidates,
      sizeWarning: sizeWarning,
      achWarning: achWarning,
      throwWarning: throwWarning,
      input: input,
    );
  }
}
