import '../models/models.dart';

class UnitConverter {
  static double toCfm(double flowRate, UnitSystem unit) {
    if (unit == UnitSystem.imperial) return flowRate;
    return flowRate * 0.5886;
  }

  static double fromCfm(double cfm, UnitSystem unit) {
    if (unit == UnitSystem.imperial) return cfm;
    return cfm / 0.5886;
  }

  static double toFpm(double ms, UnitSystem unit) {
    if (unit == UnitSystem.imperial) return ms;
    return ms * 196.85;
  }

  static double fromFpm(double fpm, UnitSystem unit) {
    if (unit == UnitSystem.imperial) return fpm;
    return fpm / 196.85;
  }

  static double toInches(double mm, UnitSystem unit) {
    if (unit == UnitSystem.imperial) return mm;
    return mm / 25.4;
  }

  static double fromInches(double inches, UnitSystem unit) {
    if (unit == UnitSystem.imperial) return inches;
    return inches * 25.4;
  }

  static double toInWg(double pa, UnitSystem unit) {
    if (unit == UnitSystem.imperial) return pa;
    return pa * 0.1225;
  }

  static double fromInWg(double inWg, UnitSystem unit) {
    if (unit == UnitSystem.imperial) return inWg;
    return inWg / 0.1225;
  }

  static HvacInput toImperial(HvacInput input) {
    if (input.unitSystem == UnitSystem.imperial) return input;
    return HvacInput(
      flowRate: toCfm(input.flowRate, UnitSystem.metric),
      targetVelocity: toFpm(input.targetVelocity, UnitSystem.metric),
      frictionRate: toInWg(input.frictionRate, UnitSystem.metric),
      method: input.method,
      unitSystem: UnitSystem.imperial,
      systemType: input.systemType,
    );
  }

  static HvacResult resultToMetric(HvacResult imperialResult) {
    final round = imperialResult.roundResult;
    final convertedRound = RoundResult(
      calculatedDiameter: fromInches(
        round.calculatedDiameter,
        UnitSystem.metric,
      ),
      standardDiameter: fromInches(round.standardDiameter, UnitSystem.metric),
      velocity: fromFpm(round.velocity, UnitSystem.metric),
      frictionRate: fromInWg(round.frictionRate, UnitSystem.metric),
      area: round.area * 645.16,
    );

    final convertedOptions = imperialResult.rectangleOptions.map((opt) {
      return RectangleOption(
        width: fromInches(opt.width, UnitSystem.metric),
        height: fromInches(opt.height, UnitSystem.metric),
        area: opt.area * 645.16,
        velocity: fromFpm(opt.velocity, UnitSystem.metric),
        equivalentDiameter: fromInches(
          opt.equivalentDiameter,
          UnitSystem.metric,
        ),
        aspectRatio: opt.aspectRatio,
        score: opt.score,
        stars: opt.stars,
        preferred: opt.preferred,
        velocityError: opt.velocityError,
        equivalentDiameterError: opt.equivalentDiameterError,
      );
    }).toList();

    return HvacResult(
      roundResult: convertedRound,
      rectangleOptions: convertedOptions,
      warnings: imperialResult.warnings,
      metadata: imperialResult.metadata,
    );
  }
}
