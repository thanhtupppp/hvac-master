enum DuctType {
  supplyMain,
  supplyBranch,
  returnMain,
  exhaust,
  freshAir,
  custom,
}

enum DuctMaterial {
  galvanized,
  fiberglass,
  flexible,
  plastic,
  aluminum,
  stainless,
}

enum DuctShape { round, rectangular }

enum PressureLossMode { straight, total }

enum FittingFlowType { branch, run }

class AirDistributionConstants {
  AirDistributionConstants._();

  // === Air physical properties ===
  static const double rhoAir = 1.2;
  static const double muAir = 1.81e-5;
  static const double cpAir = 1006.0;

  // === Unit conversions ===
  static const double cfmToM3h = 1.699;
  static const double m2ToFt2 = 10.764;
  static const double msToFpm = 196.85;
  static const double m3ToFt3 = 35.3147;
  static const double mmToInch = 25.4;
  static const double paToInH2O = 0.00401865;
  static const double inchToPa = 248.84;
  static const double ft2ToM2 = 0.092903;
  static const double ftToM = 0.3048;
  // Conversion: in.wg/100ft ↔ Pa/m
  // 1 in.wg = 248.84 Pa; 1 m = 3.28084 ft; 100 ft = 30.48 m
  // 1 in.wg/100ft = 248.84 / 30.48 = 8.16 Pa/m
  // Therefore 1 Pa/m = 1 / 8.16 = 0.1226 in.wg/100ft
  static const double paPerMToInWg100ft = 0.00401865 / 3.28084 * 100;
  // Inverse: in.wg/100ft → Pa/m. 248.84 Pa per in.wg / (100 ft / 3.28084 ft per m)
  // = 248.84 × 3.28084 / 100 = 8.16
  static const double inWg100ftToPaPerM = 248.84 * 3.28084 / 100;
  static const double lsToCfm = 2.11888;

  // === Recommended duct velocities (FPM) ===
  static const Map<DuctType, DuctVelocityLimit> ductVelocityLimits = {
    DuctType.supplyMain: DuctVelocityLimit(
      min: 700,
      max: 1300,
      recommended: 900,
    ),
    DuctType.supplyBranch: DuctVelocityLimit(
      min: 500,
      max: 1000,
      recommended: 600,
    ),
    DuctType.returnMain: DuctVelocityLimit(
      min: 600,
      max: 1100,
      recommended: 700,
    ),
    DuctType.exhaust: DuctVelocityLimit(min: 500, max: 1200, recommended: 800),
    DuctType.freshAir: DuctVelocityLimit(min: 400, max: 900, recommended: 500),
    DuctType.custom: DuctVelocityLimit(min: 600, max: 1200, recommended: 800),
  };

  static const Map<DuctType, DuctVelocityLimit> metricVelocityLimits = {
    DuctType.supplyMain: DuctVelocityLimit(
      min: 3.5,
      max: 6.6,
      recommended: 4.6,
    ),
    DuctType.supplyBranch: DuctVelocityLimit(
      min: 2.5,
      max: 5.1,
      recommended: 3.0,
    ),
    DuctType.returnMain: DuctVelocityLimit(
      min: 3.0,
      max: 5.6,
      recommended: 3.6,
    ),
    DuctType.exhaust: DuctVelocityLimit(min: 2.5, max: 6.1, recommended: 4.1),
    DuctType.freshAir: DuctVelocityLimit(min: 2.0, max: 4.6, recommended: 2.5),
    DuctType.custom: DuctVelocityLimit(min: 3.0, max: 6.1, recommended: 4.1),
  };

  // === Friction rate limits ===
  static const double frictionMinInWg100ft = 0.05;
  static const double frictionMaxInWg100ft = 0.30;
  static const double frictionRecommendedInWg100ft = 0.10;
  static const double frictionMinPaPerM = 0.4;
  static const double frictionMaxPaPerM = 2.5;

  // === Aspect ratio ===
  static const double aspectRatioMax = 4.0;
  static const double aspectRatioRecommended = 3.0;

  // === Velocity warning thresholds ===
  // Per ASHRAE Handbook Fundamentals 2021, Table 21.2 (Residential):
  //   - Supply main: 700-900 FPM recommended
  //   - Supply branch: 500-700 FPM
  //   - Return main: 600-800 FPM
  // Warnings trigger when velocity approaches upper limit for typical ducts.
  static const double highVelocityFpm = 1000; // Warn if above 1000 FPM
  static const double lowVelocityFpm = 300; // Warn if below 300 FPM (dust)
  static const double highVelocityMs = 5.1; // 1000 FPM in m/s
  static const double lowVelocityMs = 1.5; // 300 FPM in m/s

  // === Friction rate thresholds ===
  // Per ASHRAE/SMACNA: 0.10 in.wg/100ft is typical for low-velocity (residential)
  // 0.15 for medium-velocity commercial, 0.20 for high-velocity systems
  static const double highFrictionRateInWg100ft = 0.20;

  // === Pressure classification (Pa) ===
  static const double pressureLowMax = 500;
  static const double pressureMediumMax = 1500;
  static const double pressureHighMax = 3000;

  // === ACH reference values ===
  static const Map<String, AchReference> achReferences = {
    'bedroom': AchReference(min: 4, max: 6, description: 'Phòng ngủ'),
    'living_room': AchReference(min: 4, max: 8, description: 'Phòng khách'),
    'kitchen': AchReference(min: 15, max: 25, description: 'Nhà bếp'),
    'bathroom': AchReference(min: 8, max: 12, description: 'Phòng tắm'),
    'server_room': AchReference(min: 15, max: 30, description: 'Phòng server'),
    'office': AchReference(min: 4, max: 8, description: 'Văn phòng'),
    'classroom': AchReference(min: 6, max: 10, description: 'Phòng học'),
    'hospital': AchReference(min: 6, max: 12, description: 'Bệnh viện'),
  };

  // === Fan efficiency by type ===
  static const Map<String, FanEfficiency> fanEfficiencies = {
    'centrifugalForward': FanEfficiency(
      maxEfficiency: 0.75,
      powerFactor: 1.15,
      maxSpeed: 2500,
    ),
    'centrifugalBackward': FanEfficiency(
      maxEfficiency: 0.82,
      powerFactor: 1.10,
      maxSpeed: 3000,
    ),
    'axial': FanEfficiency(
      maxEfficiency: 0.70,
      powerFactor: 1.20,
      maxSpeed: 1800,
    ),
    'vaneAxial': FanEfficiency(
      maxEfficiency: 0.78,
      powerFactor: 1.12,
      maxSpeed: 2000,
    ),
  };

  static String getDuctTypeName(DuctType type) {
    switch (type) {
      case DuctType.supplyMain:
        return 'Cấp chính (Supply Main)';
      case DuctType.supplyBranch:
        return 'Cấp nhánh (Supply Branch)';
      case DuctType.returnMain:
        return 'Hồi chính (Return Main)';
      case DuctType.exhaust:
        return 'Xả (Exhaust)';
      case DuctType.freshAir:
        return 'Gió tươi (Fresh Air)';
      case DuctType.custom:
        return 'Tùy chỉnh (Custom)';
    }
  }

  static String getDuctMaterialName(DuctMaterial material) {
    switch (material) {
      case DuctMaterial.galvanized:
        return 'Tôn mạ kẽm (Galvanized)';
      case DuctMaterial.fiberglass:
        return 'Bông thủy tinh (Fiberglass)';
      case DuctMaterial.flexible:
        return 'Mềm (Flexible)';
      case DuctMaterial.plastic:
        return 'Nhựa (Plastic)';
      case DuctMaterial.aluminum:
        return 'Nhôm (Aluminum)';
      case DuctMaterial.stainless:
        return 'Inox (Stainless)';
    }
  }
}

class DuctVelocityLimit {
  final double min;
  final double max;
  final double recommended;

  const DuctVelocityLimit({
    required this.min,
    required this.max,
    required this.recommended,
  });
}

class AchReference {
  final double min;
  final double max;
  final String description;

  const AchReference({
    required this.min,
    required this.max,
    required this.description,
  });
}

class FanEfficiency {
  final double maxEfficiency;
  final double powerFactor;
  final double maxSpeed;

  const FanEfficiency({
    required this.maxEfficiency,
    required this.powerFactor,
    required this.maxSpeed,
  });
}
