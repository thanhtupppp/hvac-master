import '../models/enums.dart';
import '../models/duct_input.dart';
import '../models/duct_result.dart';
import '../models/round_result.dart';
import '../models/rectangle_option.dart';

class UnitConverter {
  // Flow Rate: 1 m³/h = 0.5886 CFM, 1 L/s = 2.1189 CFM
  static double toCfm(double flowRate, UnitSystem unit) {
    if (unit == UnitSystem.imperial) return flowRate;
    return flowRate * 0.5886; // assuming m3/h for metric
  }

  static double fromCfm(double cfm, UnitSystem unit) {
    if (unit == UnitSystem.imperial) return cfm;
    return cfm / 0.5886;
  }

  // Velocity: 1 m/s = 196.85 fpm
  static double toFpm(double ms, UnitSystem unit) {
    if (unit == UnitSystem.imperial) return ms;
    return ms * 196.85;
  }

  static double fromFpm(double fpm, UnitSystem unit) {
    if (unit == UnitSystem.imperial) return fpm;
    return fpm / 196.85;
  }

  // Length: 1 mm = 0.03937 inches
  static double toInches(double mm, UnitSystem unit) {
    if (unit == UnitSystem.imperial) return mm;
    return mm * 0.03937;
  }

  static double fromInches(double inches, UnitSystem unit) {
    if (unit == UnitSystem.imperial) return inches;
    return inches / 0.03937;
  }

  // Friction: 1 Pa/m = 0.1225 in.wg/100ft
  static double toInWg(double pa, UnitSystem unit) {
    if (unit == UnitSystem.imperial) return pa;
    return pa * 0.1225;
  }

  static double fromInWg(double inWg, UnitSystem unit) {
    if (unit == UnitSystem.imperial) return inWg;
    return inWg / 0.1225;
  }

  static DuctInput toImperial(DuctInput input) {
    if (input.unitSystem == UnitSystem.imperial) return input;
    return DuctInput(
      flowRate: toCfm(input.flowRate, UnitSystem.metric),
      targetVelocity: toFpm(input.targetVelocity, UnitSystem.metric),
      frictionRate: toInWg(input.frictionRate, UnitSystem.metric),
      method: input.method,
      unitSystem: UnitSystem.imperial,
      ductType: input.ductType,
    );
  }

  static DuctResult resultToMetric(DuctResult imperialResult) {
    final round = imperialResult.roundDuct;
    final convertedRound = RoundResult(
      calculatedDiameter: fromInches(round.calculatedDiameter, UnitSystem.metric),
      standardDiameter: fromInches(round.standardDiameter, UnitSystem.metric),
      velocity: fromFpm(round.velocity, UnitSystem.metric),
      frictionRate: fromInWg(round.frictionRate, UnitSystem.metric),
      area: round.area * 645.16, // in² to mm²
    );

    final convertedOptions = imperialResult.rectangleOptions.map((opt) {
      return RectangleOption(
        width: fromInches(opt.width, UnitSystem.metric),
        height: fromInches(opt.height, UnitSystem.metric),
        area: opt.area * 645.16,
        velocity: fromFpm(opt.velocity, UnitSystem.metric),
        equivalentDiameter: fromInches(opt.equivalentDiameter, UnitSystem.metric),
        aspectRatio: opt.aspectRatio,
        score: opt.score,
        stars: opt.stars,
        preferred: opt.preferred,
        velocityError: opt.velocityError,
        equivalentDiameterError: opt.equivalentDiameterError,
      );
    }).toList();

    return DuctResult(
      roundDuct: convertedRound,
      rectangleOptions: convertedOptions,
      warnings: imperialResult.warnings,
      metadata: imperialResult.metadata,
    );
  }
}
