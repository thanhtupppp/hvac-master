import 'dart:math';
import '../models/enums.dart';
import '../models/duct_input.dart';
import '../models/duct_result.dart';
import '../models/round_result.dart';
import '../models/duct_warning.dart';
import '../models/calculation_metadata.dart';
import 'formulas.dart';
import 'standard_sizes.dart';
import 'rectangle_generator.dart';

class DuctEngine {
  static DuctResult calculate(DuctInput imperialInput) {
    assert(imperialInput.unitSystem == UnitSystem.imperial, 'Engine requires imperial system');

    double calculatedDiameter = 0.0;
    double velocity = 0.0;
    double friction = imperialInput.frictionRate;

    if (imperialInput.method == CalculationMethod.velocity) {
      // Target velocity sizing
      velocity = imperialInput.targetVelocity;
      final double areaSqFt = imperialInput.flowRate / velocity;
      calculatedDiameter = sqrt(4.0 * (areaSqFt * 144.0) / pi);
    } else {
      // Equal friction sizing
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
    );

    final warnings = <DuctWarning>[];
    if (velocity > 1200.0) {
      warnings.add(const DuctWarning(
        type: WarningType.highVelocity,
        message: 'Vận tốc gió cao hơn mức khuyến nghị, có thể gây tiếng ồn lớn.',
        severity: WarningSeverity.warning,
      ));
    }

    final res = DuctResult(
      roundDuct: roundRes,
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
