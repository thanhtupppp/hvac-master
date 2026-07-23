import '../../../core/hvac/models/enums.dart';
import '../constants/air_distribution_constants.dart';

enum FanType { centrifugalForward, centrifugalBackward, axial, vaneAxial }

enum DriveType { direct, belt }

enum PressureClass { low, medium, high }

class FanSelectionInput {
  final double flowRate;
  final double staticPressure;
  final UnitSystem unit;
  final FanType fanType;
  final DriveType driveType;
  final double density;
  final double altitude;
  final double efficiencyOverride;
  final double motorEfficiency;
  final double safetyFactor;

  const FanSelectionInput({
    required this.flowRate,
    required this.staticPressure,
    required this.unit,
    this.fanType = FanType.centrifugalBackward,
    this.driveType = DriveType.belt,
    this.density = 1.2,
    this.altitude = 0,
    this.efficiencyOverride = 0,
    this.motorEfficiency = 0.85,
    this.safetyFactor = 1.10,
  });

  double get flowRateM3s =>
      unit == UnitSystem.imperial ? flowRate / 2118.88 : flowRate / 3600;

  double get flowRateCfm =>
      unit == UnitSystem.imperial ? flowRate : flowRate * 0.5886;

  double get flowRateM3h =>
      unit == UnitSystem.imperial ? flowRate * 1.699 : flowRate;

  double get staticPressurePa =>
      unit == UnitSystem.imperial ? staticPressure * 248.84 : staticPressure;

  double get staticPressureInWg =>
      unit == UnitSystem.imperial ? staticPressure : staticPressure / 248.84;
}

class FanOperatingPoint {
  final double flowM3s;
  final double flowCfm;
  final double flowM3h;
  final double staticPressurePa;
  final double staticPressureInWg;
  final double densityCorrectedPa;
  final double densityCorrectedInWg;
  final double airPowerW;
  final double airPowerHp;
  final double shaftPowerW;
  final double shaftPowerHp;
  final double shaftPowerKw;
  final double brakePowerW;
  final double brakePowerHp;
  final double brakePowerKw;
  final double motorPowerW;
  final double motorPowerHp;
  final double motorPowerKw;
  final double recommendedMotorHp;
  final double recommendedMotorKw;
  final double fanEfficiency;
  final double motorEfficiency;
  final PressureClass pressureClass;
  final String fanTypeName;
  final String driveTypeName;
  final String? efficiencyWarning;
  final String? altitudeWarning;
  final String? motorSizeWarning;
  final FanSelectionInput input;

  const FanOperatingPoint({
    required this.flowM3s,
    required this.flowCfm,
    required this.flowM3h,
    required this.staticPressurePa,
    required this.staticPressureInWg,
    required this.densityCorrectedPa,
    required this.densityCorrectedInWg,
    required this.airPowerW,
    required this.airPowerHp,
    required this.shaftPowerW,
    required this.shaftPowerHp,
    required this.shaftPowerKw,
    required this.brakePowerW,
    required this.brakePowerHp,
    required this.brakePowerKw,
    required this.motorPowerW,
    required this.motorPowerHp,
    required this.motorPowerKw,
    required this.recommendedMotorHp,
    required this.recommendedMotorKw,
    required this.fanEfficiency,
    required this.motorEfficiency,
    required this.pressureClass,
    required this.fanTypeName,
    required this.driveTypeName,
    this.efficiencyWarning,
    this.altitudeWarning,
    this.motorSizeWarning,
    required this.input,
  });
}

class FanSelectionEngine {
  static const double _hpToW = 745.7;
  static const double _referenceDensity = 1.2;

  /// Calculate fan operating point with brake power, motor size, etc.
  /// Density correction: at higher altitude, air is less dense so fan must
  /// produce more volume to deliver same mass flow, but pressure also drops.
  /// We correct pressure for the actual air density.
  static FanOperatingPoint? calculate(FanSelectionInput input) {
    if (input.flowRate <= 0 || input.staticPressure <= 0) return null;

    final flowM3s = input.flowRateM3s;
    final flowCfm = input.flowRateCfm;
    final flowM3h = input.flowRateM3h;
    final pressurePa = input.staticPressurePa;
    final pressureInWg = input.staticPressureInWg;

    // Density ratio (actual vs standard 1.2 kg/m³)
    final densityRatio = input.density / _referenceDensity;

    // Density-corrected pressure.
    // Fan Law: P ∝ ρ for same fan geometry and RPM.
    // At lower density (high altitude), fan produces LESS pressure for same RPM.
    // Since user specifies volumetric flow (CFM/m³h) at actual conditions,
    // the pressure needed scales linearly with density.
    // P_corrected = P_required × (ρ_actual/ρ_reference) = P_required × densityRatio
    final correctedPa = pressurePa * densityRatio;
    final correctedInWg = pressureInWg * densityRatio;

    // Fan efficiency lookup
    final fanKey = _fanKey(input.fanType);
    final fanDef = AirDistributionConstants.fanEfficiencies[fanKey]!;
    final efficiency = input.efficiencyOverride > 0
        ? input.efficiencyOverride.clamp(0.0, 0.95)
        : fanDef.maxEfficiency * 0.85; // operating point typically 85% of peak

    // Air power (theoretical, no losses)
    // P_air = Q × ΔP  (W = m³/s × Pa)
    final airPowerW = flowM3s * correctedPa;
    final airPowerHp = airPowerW / _hpToW;

    // Shaft power = air power / fan efficiency
    final shaftPowerW = airPowerW / efficiency;
    final shaftPowerHp = shaftPowerW / _hpToW;
    final shaftPowerKw = shaftPowerW / 1000;

    // Brake power (after drive losses)
    // Belt drive ~5% loss; direct drive ~2% loss
    final driveLoss = input.driveType == DriveType.belt ? 0.95 : 0.98;
    final brakePowerW = shaftPowerW / driveLoss;
    final brakePowerHp = brakePowerW / _hpToW;
    final brakePowerKw = brakePowerW / 1000;

    // Motor power (input to motor)
    final motorEff = input.motorEfficiency.clamp(0.5, 0.98);
    final motorPowerW = brakePowerW / motorEff;
    final motorPowerHp = motorPowerW / _hpToW;
    final motorPowerKw = motorPowerW / 1000;

    // Recommended motor (next standard size up with safety factor)
    final safePowerHp = brakePowerHp * input.safetyFactor;
    final safePowerKw = brakePowerKw * input.safetyFactor;
    final recommendedMotorHp = _nextStandardMotorHp(safePowerHp);
    final recommendedMotorKw = _nextStandardMotorKw(safePowerKw);

    // Pressure classification
    final pressureClass = _classifyPressure(correctedPa);

    // Warnings
    String? efficiencyWarning;
    if (efficiency > 0.90) {
      efficiencyWarning =
          'Hiệu suất $efficiency rất cao — kiểm tra điều kiện vận hành.';
    } else if (efficiency < 0.50) {
      efficiencyWarning =
          'Hiệu suất $efficiency thấp — có thể ngoài vùng làm việc tối ưu.';
    }

    String? altitudeWarning;
    if (input.altitude > 1500) {
      altitudeWarning =
          'Độ cao ${input.altitude.toStringAsFixed(0)}m — mật độ không khí giảm ${((1 - densityRatio) * 100).toStringAsFixed(0)}%.';
    }

    String? motorSizeWarning;
    if (recommendedMotorHp >= 50) {
      motorSizeWarning =
          'Motor lớn (≥50 HP) — nên dùng VFD và kiểm tra khởi động Y-Δ.';
    }

    return FanOperatingPoint(
      flowM3s: flowM3s,
      flowCfm: flowCfm,
      flowM3h: flowM3h,
      staticPressurePa: pressurePa,
      staticPressureInWg: pressureInWg,
      densityCorrectedPa: correctedPa,
      densityCorrectedInWg: correctedInWg,
      airPowerW: airPowerW,
      airPowerHp: airPowerHp,
      shaftPowerW: shaftPowerW,
      shaftPowerHp: shaftPowerHp,
      shaftPowerKw: shaftPowerKw,
      brakePowerW: brakePowerW,
      brakePowerHp: brakePowerHp,
      brakePowerKw: brakePowerKw,
      motorPowerW: motorPowerW,
      motorPowerHp: motorPowerHp,
      motorPowerKw: motorPowerKw,
      recommendedMotorHp: recommendedMotorHp,
      recommendedMotorKw: recommendedMotorKw,
      fanEfficiency: efficiency,
      motorEfficiency: motorEff,
      pressureClass: pressureClass,
      fanTypeName: _fanTypeName(input.fanType),
      driveTypeName: _driveTypeName(input.driveType),
      efficiencyWarning: efficiencyWarning,
      altitudeWarning: altitudeWarning,
      motorSizeWarning: motorSizeWarning,
      input: input,
    );
  }

  static String _fanKey(FanType type) {
    switch (type) {
      case FanType.centrifugalForward:
        return 'centrifugalForward';
      case FanType.centrifugalBackward:
        return 'centrifugalBackward';
      case FanType.axial:
        return 'axial';
      case FanType.vaneAxial:
        return 'vaneAxial';
    }
  }

  static String _fanTypeName(FanType type) {
    switch (type) {
      case FanType.centrifugalForward:
        return 'Centrifugal Forward Curved';
      case FanType.centrifugalBackward:
        return 'Centrifugal Backward Inclined';
      case FanType.axial:
        return 'Axial (Tube)';
      case FanType.vaneAxial:
        return 'Vane Axial';
    }
  }

  static String _driveTypeName(DriveType type) {
    switch (type) {
      case DriveType.direct:
        return 'Trực tiếp (Direct)';
      case DriveType.belt:
        return 'Dây đai (Belt)';
    }
  }

  static PressureClass _classifyPressure(double pressurePa) {
    if (pressurePa < AirDistributionConstants.pressureLowMax) {
      return PressureClass.low;
    } else if (pressurePa < AirDistributionConstants.pressureMediumMax) {
      return PressureClass.medium;
    } else {
      return PressureClass.high;
    }
  }

  /// Next standard NEMA motor HP (1/4, 1/3, 1/2, 3/4, 1, 1.5, 2, 3, 5, ...)
  static double _nextStandardMotorHp(double hp) {
    const sizes = [
      0.25,
      0.33,
      0.5,
      0.75,
      1.0,
      1.5,
      2.0,
      3.0,
      5.0,
      7.5,
      10.0,
      15.0,
      20.0,
      25.0,
      30.0,
      40.0,
      50.0,
      60.0,
      75.0,
      100.0,
      125.0,
      150.0,
      200.0,
      250.0,
      300.0,
      350.0,
      400.0,
      500.0,
    ];
    for (final size in sizes) {
      if (size >= hp) return size;
    }
    return hp; // oversized — manual selection needed
  }

  /// Next standard IEC motor kW
  static double _nextStandardMotorKw(double kw) {
    const sizes = [
      0.18,
      0.25,
      0.37,
      0.55,
      0.75,
      1.1,
      1.5,
      2.2,
      3.0,
      4.0,
      5.5,
      7.5,
      11.0,
      15.0,
      18.5,
      22.0,
      30.0,
      37.0,
      45.0,
      55.0,
      75.0,
      90.0,
      110.0,
      132.0,
      160.0,
      200.0,
      250.0,
      315.0,
      355.0,
      400.0,
      500.0,
    ];
    for (final size in sizes) {
      if (size >= kw) return size;
    }
    return kw;
  }

  /// Get standard motor sizes list (for UI display)
  static List<double> get motorHpSizes => const [
    0.5,
    0.75,
    1.0,
    1.5,
    2.0,
    3.0,
    5.0,
    7.5,
    10.0,
    15.0,
    20.0,
    25.0,
    30.0,
    40.0,
    50.0,
    60.0,
    75.0,
    100.0,
  ];

  /// Get fan max efficiency for UI
  static double getMaxEfficiency(FanType type) {
    final key = _fanKey(type);
    return AirDistributionConstants.fanEfficiencies[key]!.maxEfficiency;
  }
}
