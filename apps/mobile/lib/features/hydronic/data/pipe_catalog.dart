import '../constants/hydronic_constants.dart';

/// Standard pipe size with nominal size, schedule, and inner diameter.
class PipeSizeEntry {
  /// Nominal pipe size in inches (e.g., 0.5, 0.75, 1.0, etc.)
  final double nominalInch;

  /// Inner diameter in inches.
  final double idInch;

  /// Wall thickness in inches (for reference).
  final double wallThicknessInch;

  /// Outer diameter in inches.
  final double odInch;

  /// Inner diameter in meters.
  double get idM => idInch * HydronicConstants.inchToM;

  /// Inner diameter in mm.
  double get idMm => idInch * HydronicConstants.inchToMm;

  const PipeSizeEntry({
    required this.nominalInch,
    required this.idInch,
    required this.wallThicknessInch,
    required this.odInch,
  });

  /// Flow area in m².
  double get areaM2 => 3.14159265359 * idM * idM / 4;

  /// Flow area in ft².
  double get areaFt2 => areaM2 * 10.764;

  @override
  String toString() => '$nominalInch" (ID: ${idInch.toStringAsFixed(3)}")';
}

/// Standard copper tube size (CTS — Copper Tube Size).
class CopperSizeEntry {
  final double nominalInch;
  final double odInch;       // outer diameter (CTS)
  final double idTypeKInch;
  final double idTypeLInch;
  final double idTypeMInch;

  const CopperSizeEntry({
    required this.nominalInch,
    required this.odInch,
    required this.idTypeKInch,
    required this.idTypeLInch,
    required this.idTypeMInch,
  });

  double idFor(PipeMaterial copper) {
    switch (copper) {
      case PipeMaterial.copperTypeK: return idTypeKInch;
      case PipeMaterial.copperTypeL: return idTypeLInch;
      case PipeMaterial.copperTypeM: return idTypeMInch;
      default: return idTypeLInch;
    }
  }
}

/// All standard pipe sizes for Steel IPS (Schedule 40 and 80).
/// Source: ASME B36.10M (carbon/alloy steel) + ASTM A53.
/// ID values reference: Hydronics Institute Pipe Design Manual Table 1.
const List<PipeSizeEntry> steelPipeSizesSch40 = [
  // NPS   ID(in)   Wall(in)   OD(in)
  PipeSizeEntry(nominalInch: 0.5,  idInch: 0.622, wallThicknessInch: 0.109, odInch: 0.840),
  PipeSizeEntry(nominalInch: 0.75,  idInch: 0.824, wallThicknessInch: 0.113, odInch: 1.050),
  PipeSizeEntry(nominalInch: 1.0,   idInch: 1.049, wallThicknessInch: 0.133, odInch: 1.315),
  PipeSizeEntry(nominalInch: 1.25,  idInch: 1.380, wallThicknessInch: 0.140, odInch: 1.660),
  PipeSizeEntry(nominalInch: 1.5,   idInch: 1.610, wallThicknessInch: 0.145, odInch: 1.900),
  PipeSizeEntry(nominalInch: 2.0,   idInch: 2.067, wallThicknessInch: 0.154, odInch: 2.375),
  PipeSizeEntry(nominalInch: 2.5,   idInch: 2.469, wallThicknessInch: 0.203, odInch: 2.875),
  PipeSizeEntry(nominalInch: 3.0,   idInch: 3.068, wallThicknessInch: 0.216, odInch: 3.500),
  PipeSizeEntry(nominalInch: 3.5,   idInch: 3.548, wallThicknessInch: 0.226, odInch: 4.000),
  PipeSizeEntry(nominalInch: 4.0,   idInch: 4.026, wallThicknessInch: 0.237, odInch: 4.500),
  PipeSizeEntry(nominalInch: 5.0,   idInch: 5.047, wallThicknessInch: 0.258, odInch: 5.563),
  PipeSizeEntry(nominalInch: 6.0,   idInch: 6.065, wallThicknessInch: 0.280, odInch: 6.625),
  PipeSizeEntry(nominalInch: 8.0,   idInch: 7.981, wallThicknessInch: 0.322, odInch: 8.625),
  PipeSizeEntry(nominalInch: 10.0,  idInch: 10.020, wallThicknessInch: 0.365, odInch: 10.750),
  PipeSizeEntry(nominalInch: 12.0,  idInch: 11.938, wallThicknessInch: 0.406, odInch: 12.750),
  PipeSizeEntry(nominalInch: 14.0,  idInch: 13.124, wallThicknessInch: 0.437, odInch: 14.000),
  PipeSizeEntry(nominalInch: 16.0,  idInch: 15.000, wallThicknessInch: 0.500, odInch: 16.000),
  PipeSizeEntry(nominalInch: 18.0,  idInch: 16.876, wallThicknessInch: 0.562, odInch: 18.000),
  PipeSizeEntry(nominalInch: 20.0,  idInch: 18.812, wallThicknessInch: 0.594, odInch: 20.000),
  PipeSizeEntry(nominalInch: 24.0,  idInch: 22.624, wallThicknessInch: 0.688, odInch: 24.000),
];

const List<PipeSizeEntry> steelPipeSizesSch80 = [
  PipeSizeEntry(nominalInch: 0.5,  idInch: 0.546, wallThicknessInch: 0.147, odInch: 0.840),
  PipeSizeEntry(nominalInch: 0.75,  idInch: 0.742, wallThicknessInch: 0.154, odInch: 1.050),
  PipeSizeEntry(nominalInch: 1.0,   idInch: 0.957, wallThicknessInch: 0.179, odInch: 1.315),
  PipeSizeEntry(nominalInch: 1.25,  idInch: 1.278, wallThicknessInch: 0.191, odInch: 1.660),
  PipeSizeEntry(nominalInch: 1.5,   idInch: 1.500, wallThicknessInch: 0.200, odInch: 1.900),
  PipeSizeEntry(nominalInch: 2.0,   idInch: 1.939, wallThicknessInch: 0.218, odInch: 2.375),
  PipeSizeEntry(nominalInch: 2.5,   idInch: 2.323, wallThicknessInch: 0.276, odInch: 2.875),
  PipeSizeEntry(nominalInch: 3.0,   idInch: 2.900, wallThicknessInch: 0.300, odInch: 3.500),
  PipeSizeEntry(nominalInch: 3.5,   idInch: 3.364, wallThicknessInch: 0.318, odInch: 4.000),
  PipeSizeEntry(nominalInch: 4.0,   idInch: 3.826, wallThicknessInch: 0.337, odInch: 4.500),
  PipeSizeEntry(nominalInch: 5.0,   idInch: 4.813, wallThicknessInch: 0.375, odInch: 5.563),
  PipeSizeEntry(nominalInch: 6.0,   idInch: 5.741, wallThicknessInch: 0.432, odInch: 6.625),
  PipeSizeEntry(nominalInch: 8.0,   idInch: 7.625, wallThicknessInch: 0.500, odInch: 8.625),
  PipeSizeEntry(nominalInch: 10.0,  idInch: 9.564, wallThicknessInch: 0.593, odInch: 10.750),
  PipeSizeEntry(nominalInch: 12.0,  idInch: 11.374, wallThicknessInch: 0.688, odInch: 12.750),
  PipeSizeEntry(nominalInch: 14.0,  idInch: 12.500, wallThicknessInch: 0.750, odInch: 14.000),
  PipeSizeEntry(nominalInch: 16.0,  idInch: 14.312, wallThicknessInch: 0.844, odInch: 16.000),
  PipeSizeEntry(nominalInch: 18.0,  idInch: 16.124, wallThicknessInch: 0.938, odInch: 18.000),
  PipeSizeEntry(nominalInch: 20.0,  idInch: 17.938, wallThicknessInch: 1.031, odInch: 20.000),
  PipeSizeEntry(nominalInch: 24.0,  idInch: 21.562, wallThicknessInch: 1.219, odInch: 24.000),
];

/// Copper tube sizes (CTS — Copper Tube Sizes).
/// Source: ASTM B88 (water tube).
const List<CopperSizeEntry> copperTubeSizes = [
  // NPS(OD)   OD(in)    ID Type K   ID Type L   ID Type M
  CopperSizeEntry(nominalInch: 0.375, odInch: 0.500,  idTypeKInch: 0.402, idTypeLInch: 0.430, idTypeMInch: 0.450),
  CopperSizeEntry(nominalInch: 0.5,   odInch: 0.625,  idTypeKInch: 0.527, idTypeLInch: 0.545, idTypeMInch: 0.569),
  CopperSizeEntry(nominalInch: 0.75,  odInch: 0.875,  idTypeKInch: 0.745, idTypeLInch: 0.785, idTypeMInch: 0.811),
  CopperSizeEntry(nominalInch: 1.0,   odInch: 1.125,  idTypeKInch: 0.995, idTypeLInch: 1.025, idTypeMInch: 1.055),
  CopperSizeEntry(nominalInch: 1.25,  odInch: 1.375,  idTypeKInch: 1.245, idTypeLInch: 1.265, idTypeMInch: 1.291),
  CopperSizeEntry(nominalInch: 1.5,   odInch: 1.625,  idTypeKInch: 1.481, idTypeLInch: 1.505, idTypeMInch: 1.527),
  CopperSizeEntry(nominalInch: 2.0,   odInch: 2.125,  idTypeKInch: 1.959, idTypeLInch: 1.985, idTypeMInch: 2.009),
  CopperSizeEntry(nominalInch: 2.5,   odInch: 2.625,  idTypeKInch: 2.435, idTypeLInch: 2.465, idTypeMInch: 2.495),
  CopperSizeEntry(nominalInch: 3.0,   odInch: 3.125,  idTypeKInch: 2.907, idTypeLInch: 2.945, idTypeMInch: 2.981),
  CopperSizeEntry(nominalInch: 3.5,   odInch: 3.625,  idTypeKInch: 3.385, idTypeLInch: 3.425, idTypeMInch: 3.459),
  CopperSizeEntry(nominalInch: 4.0,   odInch: 4.125,  idTypeKInch: 3.857, idTypeLInch: 3.905, idTypeMInch: 3.935),
  CopperSizeEntry(nominalInch: 5.0,   odInch: 5.125,  idTypeKInch: 4.805, idTypeLInch: 4.875, idTypeMInch: 4.907),
  CopperSizeEntry(nominalInch: 6.0,   odInch: 6.125,  idTypeKInch: 5.741, idTypeLInch: 5.845, idTypeMInch: 5.881),
  CopperSizeEntry(nominalInch: 8.0,   odInch: 8.125,  idTypeKInch: 7.583, idTypeLInch: 7.725, idTypeMInch: 7.785),
];

/// PVC/CPVC IPS (Iron Pipe Size) Schedule 40 and 80.
/// Source: ASTM D1785 (PVC) / ASTM F441 (CPVC).
/// OD matches Steel IPS for compatibility.
const List<PipeSizeEntry> pvcPipeSizesSch40 = [
  PipeSizeEntry(nominalInch: 0.5,  idInch: 0.622, wallThicknessInch: 0.109, odInch: 0.840),
  PipeSizeEntry(nominalInch: 0.75,  idInch: 0.824, wallThicknessInch: 0.113, odInch: 1.050),
  PipeSizeEntry(nominalInch: 1.0,   idInch: 1.049, wallThicknessInch: 0.133, odInch: 1.315),
  PipeSizeEntry(nominalInch: 1.25,  idInch: 1.380, wallThicknessInch: 0.140, odInch: 1.660),
  PipeSizeEntry(nominalInch: 1.5,   idInch: 1.610, wallThicknessInch: 0.145, odInch: 1.900),
  PipeSizeEntry(nominalInch: 2.0,   idInch: 2.067, wallThicknessInch: 0.154, odInch: 2.375),
  PipeSizeEntry(nominalInch: 2.5,   idInch: 2.469, wallThicknessInch: 0.203, odInch: 2.875),
  PipeSizeEntry(nominalInch: 3.0,   idInch: 3.068, wallThicknessInch: 0.216, odInch: 3.500),
  PipeSizeEntry(nominalInch: 4.0,   idInch: 4.026, wallThicknessInch: 0.237, odInch: 4.500),
  PipeSizeEntry(nominalInch: 6.0,   idInch: 6.065, wallThicknessInch: 0.280, odInch: 6.625),
  PipeSizeEntry(nominalInch: 8.0,   idInch: 7.981, wallThicknessInch: 0.322, odInch: 8.625),
  PipeSizeEntry(nominalInch: 10.0,  idInch: 10.020, wallThicknessInch: 0.365, odInch: 10.750),
  PipeSizeEntry(nominalInch: 12.0,  idInch: 11.938, wallThicknessInch: 0.406, odInch: 12.750),
  PipeSizeEntry(nominalInch: 14.0,  idInch: 13.124, wallThicknessInch: 0.437, odInch: 14.000),
  PipeSizeEntry(nominalInch: 16.0,  idInch: 15.000, wallThicknessInch: 0.500, odInch: 16.000),
];

const List<PipeSizeEntry> pvcPipeSizesSch80 = [
  PipeSizeEntry(nominalInch: 0.5,  idInch: 0.546, wallThicknessInch: 0.147, odInch: 0.840),
  PipeSizeEntry(nominalInch: 0.75,  idInch: 0.742, wallThicknessInch: 0.154, odInch: 1.050),
  PipeSizeEntry(nominalInch: 1.0,   idInch: 0.957, wallThicknessInch: 0.179, odInch: 1.315),
  PipeSizeEntry(nominalInch: 1.25,  idInch: 1.278, wallThicknessInch: 0.191, odInch: 1.660),
  PipeSizeEntry(nominalInch: 1.5,   idInch: 1.500, wallThicknessInch: 0.200, odInch: 1.900),
  PipeSizeEntry(nominalInch: 2.0,   idInch: 1.939, wallThicknessInch: 0.218, odInch: 2.375),
  PipeSizeEntry(nominalInch: 2.5,   idInch: 2.323, wallThicknessInch: 0.276, odInch: 2.875),
  PipeSizeEntry(nominalInch: 3.0,   idInch: 2.900, wallThicknessInch: 0.300, odInch: 3.500),
  PipeSizeEntry(nominalInch: 4.0,   idInch: 3.826, wallThicknessInch: 0.337, odInch: 4.500),
  PipeSizeEntry(nominalInch: 6.0,   idInch: 5.741, wallThicknessInch: 0.432, odInch: 6.625),
  PipeSizeEntry(nominalInch: 8.0,   idInch: 7.625, wallThicknessInch: 0.500, odInch: 8.625),
  PipeSizeEntry(nominalInch: 10.0,  idInch: 9.564, wallThicknessInch: 0.593, odInch: 10.750),
  PipeSizeEntry(nominalInch: 12.0,  idInch: 11.374, wallThicknessInch: 0.688, odInch: 12.750),
  PipeSizeEntry(nominalInch: 14.0,  idInch: 12.500, wallThicknessInch: 0.750, odInch: 14.000),
  PipeSizeEntry(nominalInch: 16.0,  idInch: 14.312, wallThicknessInch: 0.844, odInch: 16.000),
];

/// PEX (CTS) sizes. Source: ASTM F876/F877.
/// OD matches copper tube size (CTS).
const List<CopperSizeEntry> pexSizes = [
  CopperSizeEntry(nominalInch: 0.375, odInch: 0.500,  idTypeKInch: 0.350, idTypeLInch: 0.350, idTypeMInch: 0.350),
  CopperSizeEntry(nominalInch: 0.5,   odInch: 0.625,  idTypeKInch: 0.475, idTypeLInch: 0.475, idTypeMInch: 0.475),
  CopperSizeEntry(nominalInch: 0.75,  odInch: 0.875,  idTypeKInch: 0.671, idTypeLInch: 0.671, idTypeMInch: 0.671),
  CopperSizeEntry(nominalInch: 1.0,   odInch: 1.125,  idTypeKInch: 0.862, idTypeLInch: 0.862, idTypeMInch: 0.862),
  CopperSizeEntry(nominalInch: 1.25,  odInch: 1.375,  idTypeKInch: 1.102, idTypeLInch: 1.102, idTypeMInch: 1.102),
  CopperSizeEntry(nominalInch: 1.5,   odInch: 1.625,  idTypeKInch: 1.327, idTypeLInch: 1.327, idTypeMInch: 1.327),
  CopperSizeEntry(nominalInch: 2.0,   odInch: 2.125,  idTypeKInch: 1.720, idTypeLInch: 1.720, idTypeMInch: 1.720),
];

/// ─────────────────────────────────────────────────────────────
/// CATALOG LOOKUP FUNCTIONS
/// ─────────────────────────────────────────────────────────────

/// Get all standard pipe sizes for a given material.
List<PipeSizeEntry> standardSizesFor(PipeMaterial material, PipeSchedule schedule) {
  switch (material) {
    case PipeMaterial.steelGalvanized:
    case PipeMaterial.steelBlack:
    case PipeMaterial.stainless304:
    case PipeMaterial.stainless316:
      return schedule == PipeSchedule.schedule40
          ? steelPipeSizesSch40
          : steelPipeSizesSch80;
    case PipeMaterial.pvcSch40:
    case PipeMaterial.cpvcSch40:
      return pvcPipeSizesSch40;
    case PipeMaterial.pvcSch80:
    case PipeMaterial.cpvcSch80:
      return pvcPipeSizesSch80;
    default:
      return steelPipeSizesSch40;
  }
}

/// Get standard pipe size by nominal inch (closest match).
PipeSizeEntry? findSizeByNominal(double nominalInch, PipeMaterial material, PipeSchedule schedule) {
  final sizes = standardSizesFor(material, schedule);
  PipeSizeEntry? best;
  double bestDiff = double.infinity;
  for (final s in sizes) {
    final diff = (s.nominalInch - nominalInch).abs();
    if (diff < bestDiff) {
      bestDiff = diff;
      best = s;
    }
  }
  return best;
}

/// Get inner diameter in inches for a copper/pex tube.
double copperIdInch(double nominalInch, PipeMaterial material) {
  for (final s in copperTubeSizes) {
    if ((s.nominalInch - nominalInch).abs() < 0.001) {
      return s.idFor(material);
    }
  }
  for (final s in pexSizes) {
    if ((s.nominalInch - nominalInch).abs() < 0.001) {
      return s.idFor(material);
    }
  }
  return nominalInch * 0.85; // fallback approximation
}
