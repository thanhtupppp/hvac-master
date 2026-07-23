// No imports needed for this file — all values are self-contained

/// Service type for velocity limit lookups.
enum PipeService {
  hotWaterHeating,
  chilledWater,
  condenserWater,
  boilerFeed,
  steamCondensate,
  serviceWater,
  glycol20,
  glycol30,
  glycol40,
}

/// Pipe schedule types.
enum PipeSchedule { schedule40, schedule80 }

/// Pipe material types with roughness values (Colebrook-White).
/// References:
///   - ASHRAE Handbook Fundamentals 2021, Chapter 21
///   - Hydronics Institute (HI) Pipe Design Manual
enum PipeMaterial {
  steelGalvanized,
  steelBlack,
  copperTypeK,
  copperTypeL,
  copperTypeM,
  pvcSch40,
  pvcSch80,
  cpvcSch40,
  cpvcSch80,
  pex,
  stainless304,
  stainless316,
}

/// Flow regime based on Reynolds number.
enum FlowRegime {
  laminar,       // Re < 2300
  transitional,  // 2300 <= Re < 4000
  turbulent,     // Re >= 4000
}

/// Expansion tank types.
enum ExpansionTankType {
  closedDiaphragm,
  closedBladder,
  open,
}

/// ============================================================
// CONSTANTS
// ============================================================

class HydronicConstants {
  HydronicConstants._();

  // ── Water physical properties at 20°C (reference) ──────────────
  static const double rhoWater20C = 997.0;   // kg/m³
  static const double muWater20C = 1.002e-3; // Pa·s (dynamic viscosity)
  static const double nuWater20C = 1.005e-6; // m²/s (kinematic viscosity)
  static const double cpWater20C = 4182.0;   // J/(kg·K)
  static const double betaWater = 0.000207;  // 1/K (volumetric thermal expansion coeff)

  // ── Gravity ───────────────────────────────────────────────────
  static const double g = 9.80665; // m/s²

  // ── Unit conversions ────────────────────────────────────────────
  // Volume flow
  static const double gpmToM3s = 6.30902e-5;   // GPM → m³/s
  static const double gpmToLs = 0.0630902;      // GPM → L/s
  static const double gpmToM3h = 0.227125;     // GPM → m³/h
  static const double m3hToGpm = 4.40287;      // m³/h → GPM
  static const double lsToGpm = 15.8503;       // L/s → GPM
  static const double lsToM3h = 3.6;           // L/s → m³/h

  // Length
  static const double ftToM = 0.3048;
  static const double inchToM = 0.0254;
  static const double mmToInch = 0.0393701;
  static const double inchToMm = 25.4;

  // Pressure / head
  static const double ftHeadToPa = 2989.07;   // ft H₂O → Pa
  static const double ftHeadToKPa = 2.98907; // ft H₂O → kPa
  static const double ftHeadToPsi = 0.4335;  // ft H₂O → PSI
  static const double psiToPa = 6894.76;
  static const double psiToBar = 0.0689476;
  static const double kpaToPsi = 0.145038;
  static const double barToPsi = 14.5038;
  static const double inchWgToPa = 249.089;   // 1 in.wg = 249.089 Pa
  static const double paToInWg = 0.00401463; // inverse

  // ── Reynolds regime thresholds ─────────────────────────────────
  static const double reLaminarMax = 2300.0;
  static const double reTurbulentMin = 4000.0;

  // ── Colebrook-White constants ──────────────────────────────────
  static const double swameeJainA = 0.25;   // coefficient for Swamee-Jain
  static const double swameeJainB = 5.74;   // coefficient for Swamee-Jain
  static const double swameeJainC = 1.0;    // coefficient for Swamee-Jain (epsilon/D)^0.9

  // ── Hazen-Williams coefficient (default) ──────────────────────
  static const double hwCoefficientDefault = 130.0; // clean water

  // ── Glycol thermal expansion ───────────────────────────────────
  // Volume expansion factor (fractional) per °C rise
  // Glycol ≈ 0.0004/°C; Water ≈ 0.000207/°C
  static const double glycolExpansionPerDegC = 0.00040;
  static const double waterExpansionPerDegC = 0.000207;

  // ── Pump motor efficiency tiers ───────────────────────────────
  static const Map<int, double> motorEfficiencyTiers = {
    1: 0.78,
    2: 0.81,
    3: 0.84,
    5: 0.87,
    7: 0.89,
    10: 0.90,
    15: 0.91,
    20: 0.92,
    25: 0.93,
    30: 0.93,
    40: 0.94,
    50: 0.94,
    60: 0.95,
    75: 0.95,
    100: 0.95,
  };

  // ── Velocity limits by service (m/s) ─────────────────────────
  // Reference: ASHRAE 2021 Handbook Fundamentals, Chapter 22, Table 2
  static const Map<PipeService, VelocityLimitPair> velocityLimitsMps = {
    PipeService.hotWaterHeating: VelocityLimitPair(min: 0.3, max: 2.4, recommended: 1.2),
    PipeService.chilledWater: VelocityLimitPair(min: 1.2, max: 3.0, recommended: 2.0),
    PipeService.condenserWater: VelocityLimitPair(min: 1.2, max: 3.6, recommended: 2.5),
    PipeService.boilerFeed: VelocityLimitPair(min: 1.8, max: 4.5, recommended: 3.0),
    PipeService.steamCondensate: VelocityLimitPair(min: 0.6, max: 2.4, recommended: 1.5),
    PipeService.serviceWater: VelocityLimitPair(min: 0.6, max: 3.0, recommended: 2.0),
    PipeService.glycol20: VelocityLimitPair(min: 0.6, max: 2.5, recommended: 1.5),
    PipeService.glycol30: VelocityLimitPair(min: 0.6, max: 2.3, recommended: 1.3),
    PipeService.glycol40: VelocityLimitPair(min: 0.5, max: 2.0, recommended: 1.1),
  };

  // Imperial (ft/s)
  static const Map<PipeService, VelocityLimitPair> velocityLimitsFps = {
    PipeService.hotWaterHeating: VelocityLimitPair(min: 1.0, max: 8.0, recommended: 4.0),
    PipeService.chilledWater: VelocityLimitPair(min: 4.0, max: 10.0, recommended: 7.0),
    PipeService.condenserWater: VelocityLimitPair(min: 4.0, max: 12.0, recommended: 8.0),
    PipeService.boilerFeed: VelocityLimitPair(min: 6.0, max: 15.0, recommended: 10.0),
    PipeService.steamCondensate: VelocityLimitPair(min: 2.0, max: 8.0, recommended: 5.0),
    PipeService.serviceWater: VelocityLimitPair(min: 2.0, max: 10.0, recommended: 6.0),
    PipeService.glycol20: VelocityLimitPair(min: 2.0, max: 8.0, recommended: 5.0),
    PipeService.glycol30: VelocityLimitPair(min: 2.0, max: 7.5, recommended: 4.5),
    PipeService.glycol40: VelocityLimitPair(min: 1.5, max: 6.5, recommended: 3.5),
  };

  // ── Pipe roughness ε (ft) — Colebrook-White ────────────────────
  // Reference: ASHRAE 2021 Fundamentals, Table 1, Chapter 21
  static const Map<PipeMaterial, double> roughnessFt = {
    PipeMaterial.steelGalvanized: 0.0005,    // 150 μm
    PipeMaterial.steelBlack: 0.00015,       // 45 μm (smooth new black iron)
    PipeMaterial.copperTypeK: 0.000005,    // 1.5 μm
    PipeMaterial.copperTypeL: 0.000005,
    PipeMaterial.copperTypeM: 0.000005,
    PipeMaterial.pvcSch40: 0.000005,
    PipeMaterial.pvcSch80: 0.000005,
    PipeMaterial.cpvcSch40: 0.000005,
    PipeMaterial.cpvcSch80: 0.000005,
    PipeMaterial.pex: 0.000005,
    PipeMaterial.stainless304: 0.000015,   // 4.5 μm
    PipeMaterial.stainless316: 0.000015,
  };

  // ── Glycol density at 20°C (kg/m³) ───────────────────────────
  // Keys are glycol concentration percentage (0 = pure water, 20 = 20%, etc.)
  static final Map<int, double> glycolDensityAt20C = {
    0: 997.0,
    20: 1024.0,
    30: 1036.0,
    40: 1048.0,
  };

  // ── Glycol dynamic viscosity at 20°C (Pa·s × 10⁻³) ───────────
  static final Map<int, double> glycolViscosityAt20CPs = {
    0: 1.002,
    20: 2.50,
    30: 4.50,
    40: 9.20,
  };

  // ── Material display names ─────────────────────────────────────
  static String getMaterialNameVi(PipeMaterial m) {
    switch (m) {
      case PipeMaterial.steelGalvanized: return 'Thép mạ kẽm (Galv.)';
      case PipeMaterial.steelBlack: return 'Thép đen (Black Iron)';
      case PipeMaterial.copperTypeK: return 'Đồng Type K';
      case PipeMaterial.copperTypeL: return 'Đồng Type L';
      case PipeMaterial.copperTypeM: return 'Đồng Type M';
      case PipeMaterial.pvcSch40: return 'PVC Schedule 40';
      case PipeMaterial.pvcSch80: return 'PVC Schedule 80';
      case PipeMaterial.cpvcSch40: return 'CPVC Schedule 40';
      case PipeMaterial.cpvcSch80: return 'CPVC Schedule 80';
      case PipeMaterial.pex: return 'PEX';
      case PipeMaterial.stainless304: return 'Inox 304';
      case PipeMaterial.stainless316: return 'Inox 316';
    }
  }

  static String getServiceNameVi(PipeService s) {
    switch (s) {
      case PipeService.hotWaterHeating: return 'Nước nóng sưởi';
      case PipeService.chilledWater: return 'Nước lạnh';
      case PipeService.condenserWater: return 'Nước giàn ngưng';
      case PipeService.boilerFeed: return 'Nước cấp lò hơi';
      case PipeService.steamCondensate: return 'Nước ngưng hơi';
      case PipeService.serviceWater: return 'Nước sinh hoạt';
      case PipeService.glycol20: return 'Glycol 20%';
      case PipeService.glycol30: return 'Glycol 30%';
      case PipeService.glycol40: return 'Glycol 40%';
    }
  }

  static String getRegimeNameVi(FlowRegime r) {
    switch (r) {
      case FlowRegime.laminar: return 'Dòng Laminar (Re < 2300)';
      case FlowRegime.transitional: return 'Dòng Chuyển tiếp (2300 < Re < 4000)';
      case FlowRegime.turbulent: return 'Dòng Turbulent (Re > 4000)';
    }
  }

  /// Interpolate glycol density at a given concentration and temperature.
  static double glycolDensity(double concentration, double tempC) {
    final pct = (concentration * 100).round().clamp(0, 40);
    final base = glycolDensityAt20C[pct] ?? 997.0;
    // Small linear correction for temperature: -0.02% per °C deviation from 20°C
    final delta = (tempC - 20.0) * -0.0002 * base;
    return (base + delta).clamp(800.0, 1200.0);
  }

  /// Interpolate glycol dynamic viscosity (Pa·s) at concentration and temperature.
  static double glycolViscosity(double concentration, double tempC) {
    final pct = (concentration * 100).round().clamp(0, 40);
    final base = glycolViscosityAt20CPs[pct] ?? 1.002;
    // Viscosity decreases with temperature: roughly -3% per °C
    final factor = 1.0 - 0.03 * (tempC - 20.0).clamp(-20.0, 40.0);
    return (base * factor * 0.001).clamp(0.0005, 0.1);
  }
}

/// Velocity limit pair (min, max, recommended) for one service type.
class VelocityLimitPair {
  final double min;
  final double max;
  final double recommended;

  const VelocityLimitPair({
    required this.min,
    required this.max,
    required this.recommended,
  });
}
