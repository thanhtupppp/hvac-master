import 'dart:math';

import '../../../core/hvac/models/enums.dart';
import '../data/diffuser_catalog.dart';

enum GrilleApplication {
  returnAir, // Hồi gió
  exhaustAir, // Xả
  transferAir, // Chuyển phòng
  supplyAirWall, // Cấp gió tường
}

class GrilleSelectionInput {
  final double totalCfm;
  final double roomAreaSqFt;
  final double ceilingHeightFt;
  final int grilleCount;
  final GrilleType grilleType;
  final GrilleApplication application;
  final UnitSystem unit;
  final bool byRoomArea;
  final double ach;
  final double maxFaceVelocityFpm;
  final double maxNcRating;
  final double mountingHeightFt;

  const GrilleSelectionInput({
    required this.totalCfm,
    required this.roomAreaSqFt,
    required this.ceilingHeightFt,
    required this.grilleCount,
    required this.grilleType,
    required this.application,
    required this.unit,
    required this.byRoomArea,
    required this.ach,
    required this.maxFaceVelocityFpm,
    required this.maxNcRating,
    required this.mountingHeightFt,
  });

  double get totalM3h =>
      unit == UnitSystem.imperial ? totalCfm * 1.699 : totalCfm;

  double get totalCfmEffective =>
      unit == UnitSystem.imperial ? totalCfm : totalCfm * 0.5886;

  double get roomAreaM2 =>
      unit == UnitSystem.imperial ? roomAreaSqFt * 0.092903 : roomAreaSqFt;

  double get roomAreaSqFtActual =>
      unit == UnitSystem.imperial ? roomAreaSqFt : roomAreaSqFt / 0.092903;

  double get ceilingHeightFtActual =>
      unit == UnitSystem.imperial ? ceilingHeightFt : ceilingHeightFt / 0.3048;

  /// Volume in ft³ always — uses conversion from m² if needed
  double get roomVolumeFt3 => roomAreaSqFtActual * ceilingHeightFtActual;
}

class GrilleSelectionPerUnit {
  final DiffuserSize size;
  final double cfmPerGrille;
  final double faceVelocityFpm;
  final double faceVelocityMs;
  final double cfmPerSqFtFace;
  final double neckVelocityFpm;
  final double neckVelocityMs;
  final double pressureDropInWg;
  final double pressureDropPa;
  final double areaSqFt;
  final int ncRating;
  final bool meetsFaceVelocity;
  final bool meetsNc;
  final String? warning;

  const GrilleSelectionPerUnit({
    required this.size,
    required this.cfmPerGrille,
    required this.faceVelocityFpm,
    required this.faceVelocityMs,
    required this.cfmPerSqFtFace,
    required this.neckVelocityFpm,
    required this.neckVelocityMs,
    required this.pressureDropInWg,
    required this.pressureDropPa,
    required this.areaSqFt,
    required this.ncRating,
    required this.meetsFaceVelocity,
    required this.meetsNc,
    this.warning,
  });
}

class GrilleSelectionResult {
  final double totalCfm;
  final double cfmPerGrille;
  final int grilleCount;
  final double roomAreaSqFt;
  final double roomAreaM2;
  final double effectiveAch;
  final GrilleApplication application;
  final DiffuserDefinition grilleDefinition;
  final DiffuserSize? selectedSize;
  final List<GrilleSelectionPerUnit> alternatives;
  final String? sizeWarning;
  final String? achWarning;
  final String? velocityWarning;
  final String applicationLabel;
  final GrilleSelectionInput input;

  const GrilleSelectionResult({
    required this.totalCfm,
    required this.cfmPerGrille,
    required this.grilleCount,
    required this.roomAreaSqFt,
    required this.roomAreaM2,
    required this.effectiveAch,
    required this.application,
    required this.grilleDefinition,
    required this.selectedSize,
    required this.alternatives,
    this.sizeWarning,
    this.achWarning,
    this.velocityWarning,
    required this.applicationLabel,
    required this.input,
  });
}

class GrilleSelectionEngine {
  // Face velocity limits per ASHRAE for return grilles
  static const Map<GrilleApplication, double> _defaultFaceVelocityLimits = {
    GrilleApplication.returnAir: 300, // Return — quiet
    GrilleApplication.exhaustAir: 400, // Exhaust — slightly higher OK
    GrilleApplication.transferAir: 500, // Transfer — for door grilles
    GrilleApplication.supplyAirWall: 500, // Wall supply — moderate
  };

  // NC rating limits per application
  static const Map<GrilleApplication, double> _defaultNcLimits = {
    GrilleApplication.returnAir: 30,
    GrilleApplication.exhaustAir: 35,
    GrilleApplication.transferAir: 40,
    GrilleApplication.supplyAirWall: 30,
  };

  /// Calculate grille selection.
  /// Simpler than diffuser — no throw distance; focuses on face velocity
  /// (which is the key acoustic criterion for return grilles).
  static GrilleSelectionResult? calculate(GrilleSelectionInput input) {
    if (input.grilleCount <= 0) return null;

    // Step 1: Resolve grille type from application
    final def = _resolveGrilleDefinition(input);

    // Step 2: Determine total CFM
    double totalCfm = input.totalCfmEffective;
    if (input.byRoomArea) {
      // CFM = (Volume × ACH) / 60 — use getter for correct unit conversion
      final volFt3 = input.roomVolumeFt3;
      if (volFt3 <= 0) return null;
      totalCfm = (volFt3 * input.ach) / 60;
    } else {
      if (totalCfm <= 0) return null;
    }

    // Step 3: CFM per grille
    final cfmPerGrille = totalCfm / input.grilleCount;

    // Step 4: Defaults
    final defaultFaceVel = _defaultFaceVelocityLimits[input.application] ?? 300;
    final maxFaceVel = input.maxFaceVelocityFpm > 0
        ? input.maxFaceVelocityFpm
        : defaultFaceVel;
    final defaultNc = _defaultNcLimits[input.application] ?? 30;
    final maxNc = input.maxNcRating > 0 ? input.maxNcRating : defaultNc;

    // Step 5: Build candidates
    final candidates = <GrilleSelectionPerUnit>[];

    for (final size in def.availableSizes) {
      final area = size.area;
      final neckArea = size.neckAreaSqFt ?? area;

      final faceVelocityFpm = cfmPerGrille / area;
      final faceVelocityMs = faceVelocityFpm * 0.00508;
      final neckVelocityFpm = cfmPerGrille / neckArea;
      final neckVelocityMs = neckVelocityFpm * 0.00508;
      final cfmPerSqFtFace = cfmPerGrille / area;

      // Pressure drop (face) — formula similar to diffuser
      final pressureDropInWg =
          (faceVelocityFpm / 4005) * (faceVelocityFpm / 4005);
      final pressureDropPa = pressureDropInWg * 248.84;

      // NC rating: lower for return grilles
      // NC ≈ 15 + log10(V_face / 100) × 12
      final ncRating = (15 + (log(faceVelocityFpm / 100) / ln10) * 12)
          .round()
          .clamp(15, 45);

      final meetsFace = faceVelocityFpm <= maxFaceVel;
      final meetsNc = ncRating <= maxNc;

      String? warning;
      if (!meetsFace) {
        warning =
            'Vận tốc mặt ${faceVelocityFpm.toStringAsFixed(0)} FPM vượt giới hạn (${maxFaceVel.toStringAsFixed(0)} FPM) — gây ồn.';
      } else if (cfmPerSqFtFace > def.maxCfmPerSqFt) {
        warning =
            'CFM/sqft ${cfmPerSqFtFace.toStringAsFixed(2)} vượt max ${def.maxCfmPerSqFt} — nên chọn size lớn hơn hoặc thêm grille.';
      }

      candidates.add(
        GrilleSelectionPerUnit(
          size: size,
          cfmPerGrille: cfmPerGrille,
          faceVelocityFpm: faceVelocityFpm,
          faceVelocityMs: faceVelocityMs,
          cfmPerSqFtFace: cfmPerSqFtFace,
          neckVelocityFpm: neckVelocityFpm,
          neckVelocityMs: neckVelocityMs,
          pressureDropInWg: pressureDropInWg,
          pressureDropPa: pressureDropPa,
          areaSqFt: area,
          ncRating: ncRating,
          meetsFaceVelocity: meetsFace,
          meetsNc: meetsNc,
          warning: warning,
        ),
      );
    }

    // Step 6: Select first size that meets all criteria
    DiffuserSize? selectedSize;
    GrilleSelectionPerUnit? selectedPerUnit;
    for (final c in candidates) {
      if (c.meetsFaceVelocity && c.meetsNc) {
        selectedSize = c.size;
        selectedPerUnit = c;
        break;
      }
    }

    // Fallback
    String? sizeWarning;
    if (selectedSize == null && candidates.isNotEmpty) {
      GrilleSelectionPerUnit? best;
      double bestScore = double.infinity;
      for (final c in candidates) {
        double score = 0;
        if (!c.meetsFaceVelocity) score += 1000;
        if (!c.meetsNc) score += 100;
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
            'Không size nào đạt tiêu chí. Size chọn gần nhất: ${best.size.width}×${best.size.length}".';
      }
    }

    // Step 7: Room stats
    final roomAreaSqFt = input.roomAreaSqFtActual;
    final roomAreaM2 = input.roomAreaM2;
    final volFt3 = input.roomVolumeFt3;
    final effectiveAch = volFt3 > 0 ? (totalCfm * 60) / volFt3 : 0.0;

    String? achWarning;
    if (input.byRoomArea &&
        effectiveAch > 0 &&
        (effectiveAch < input.ach * 0.9 || effectiveAch > input.ach * 1.5)) {
      achWarning =
          'ACH thực tế ${effectiveAch.toStringAsFixed(1)} lệch mục tiêu ${input.ach.toStringAsFixed(1)} — kiểm tra lại thể tích.';
    }

    String? velocityWarning;
    if (selectedPerUnit != null && !selectedPerUnit.meetsFaceVelocity) {
      velocityWarning =
          'Vận tốc mặt ${selectedPerUnit.faceVelocityFpm.toStringAsFixed(0)} FPM > max ${maxFaceVel.toStringAsFixed(0)} FPM. Cân nhắc thêm grille hoặc chọn size lớn.';
    }

    return GrilleSelectionResult(
      totalCfm: totalCfm,
      cfmPerGrille: cfmPerGrille,
      grilleCount: input.grilleCount,
      roomAreaSqFt: roomAreaSqFt,
      roomAreaM2: roomAreaM2,
      effectiveAch: effectiveAch,
      application: input.application,
      grilleDefinition: def,
      selectedSize: selectedSize,
      alternatives: candidates,
      sizeWarning: sizeWarning,
      achWarning: achWarning,
      velocityWarning: velocityWarning,
      applicationLabel: _applicationLabel(input.application),
      input: input,
    );
  }

  /// Map application → default grille type
  static DiffuserDefinition _resolveGrilleDefinition(
    GrilleSelectionInput input,
  ) {
    // If user explicitly chose, honor it
    if (input.grilleType != GrilleType.returnGrille) {
      // For now return grille is the explicit type — find in catalog
      return DiffuserCatalog.get(input.grilleType.toDiffuserType());
    }
    // Default based on application
    switch (input.application) {
      case GrilleApplication.returnAir:
        return DiffuserCatalog.get(DiffuserType.eggCrate);
      case GrilleApplication.exhaustAir:
        return DiffuserCatalog.get(DiffuserType.returnGrille);
      case GrilleApplication.transferAir:
        return DiffuserCatalog.get(DiffuserType.linearBar);
      case GrilleApplication.supplyAirWall:
        return DiffuserCatalog.get(DiffuserType.supplyRegister);
    }
  }

  static String _applicationLabel(GrilleApplication app) {
    switch (app) {
      case GrilleApplication.returnAir:
        return 'Hồi gió (Return Air)';
      case GrilleApplication.exhaustAir:
        return 'Xả (Exhaust)';
      case GrilleApplication.transferAir:
        return 'Chuyển phòng (Transfer)';
      case GrilleApplication.supplyAirWall:
        return 'Cấp gió tường (Wall Supply)';
    }
  }

  static double getDefaultFaceVelocity(GrilleApplication app) =>
      _defaultFaceVelocityLimits[app] ?? 300;

  static double getDefaultNc(GrilleApplication app) =>
      _defaultNcLimits[app] ?? 30;
}

/// Wrapper enum for grille types (subset of diffuser types)
enum GrilleType { returnGrille, eggCrate, linearBar, supplyRegister }

extension on GrilleType {
  DiffuserType toDiffuserType() {
    switch (this) {
      case GrilleType.returnGrille:
        return DiffuserType.returnGrille;
      case GrilleType.eggCrate:
        return DiffuserType.eggCrate;
      case GrilleType.linearBar:
        return DiffuserType.linearBar;
      case GrilleType.supplyRegister:
        return DiffuserType.supplyRegister;
    }
  }
}
