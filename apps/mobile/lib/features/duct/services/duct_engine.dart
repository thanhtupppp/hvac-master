import 'dart:math';
import '../../../core/hvac/models/models.dart';
import '../../../core/hvac/formulas/hvac_formulas.dart';
import '../../../core/hvac/standards/standard_sizes.dart';
import '../../../core/hvac/formulas/rectangle_generator.dart';
import '../../../core/hvac/validation/input_validator.dart';
import '../../../core/hvac/warnings/warning_builder.dart';

class DuctEngine {
  static HvacResult calculate(HvacInput imperialInput, List<double> standardRectSizesInInches) {
    if (imperialInput.unitSystem != UnitSystem.imperial) {
      throw ArgumentError('DuctEngine calculations require imperial input system.');
    }

    final validationError = InputValidator.validateInput(imperialInput);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    double calculatedDiameter = 0.0;
    double velocity = 0.0;
    double friction = imperialInput.frictionRate;

    if (imperialInput.method == CalculationMethod.velocity) {
      velocity = imperialInput.targetVelocity;
      final double areaSqFt = imperialInput.flowRate / velocity;
      calculatedDiameter = sqrt(4.0 * (areaSqFt * 144.0) / pi);
    } else {
      calculatedDiameter = HvacFormulas.roundDuctDiameter(
        cfm: imperialInput.flowRate,
        frictionRateInWgPer100ft: imperialInput.frictionRate,
      );
      final double areaSqIn = pi * pow(calculatedDiameter / 2.0, 2);
      velocity = imperialInput.flowRate / (areaSqIn / 144.0);
    }

    final stdRoundDiam = StandardSizes.findNearestStandardRound(
      calculatedDiameter,
      StandardSizes.imperialRound,
    );
    final stdRoundArea = pi * pow(stdRoundDiam / 2.0, 2);
    final actualRoundVelocity = imperialInput.flowRate / (stdRoundArea / 144.0);

    final roundRes = RoundResult(
      calculatedDiameter: calculatedDiameter,
      standardDiameter: stdRoundDiam,
      velocity: actualRoundVelocity,
      frictionRate: friction,
      area: stdRoundArea,
    );

    final options = RectangleGenerator.generateOptions(
      targetAreaInSqIn: stdRoundArea,
      targetDiameterIn: stdRoundDiam,
      targetVelocityFpm: velocity,
      flowRateCfm: imperialInput.flowRate,
      input: imperialInput,
      standardRectSizesInInches: standardRectSizesInInches,
    );

    final warnings = WarningBuilder.buildWarnings(
      actualVelocityFpm: actualRoundVelocity,
      frictionRate: friction,
      unitSystem: imperialInput.unitSystem,
    );

    final res = HvacResult(
      roundResult: roundRes,
      rectangleOptions: options,
      warnings: warnings,
      metadata: CalculationMetadata(
        timestamp: DateTime.now(),
        algorithmVersion: '1.2.0',
        standard: 'SMACNA / ASHRAE',
      ),
    );

    return res;
  }
}
