import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/hvac/models/models.dart';
import 'package:mobile/core/hvac/units/unit_converter.dart';
import 'package:mobile/core/hvac/standards/standard_sizes.dart';
import 'package:mobile/features/duct/services/duct_engine.dart';

void main() {
  group('UnitConverter Tests', () {
    test('Flow rate conversions (CFM <-> m3/h)', () {
      expect(UnitConverter.toCfm(100, UnitSystem.imperial), closeTo(100, 0.001));
      expect(UnitConverter.toCfm(100, UnitSystem.metric), closeTo(58.86, 0.001));

      expect(UnitConverter.fromCfm(58.86, UnitSystem.imperial), closeTo(58.86, 0.001));
      expect(UnitConverter.fromCfm(58.86, UnitSystem.metric), closeTo(100, 0.001));
    });

    test('Velocity conversions (fpm <-> m/s)', () {
      expect(UnitConverter.toFpm(10, UnitSystem.imperial), closeTo(10, 0.001));
      expect(UnitConverter.toFpm(10, UnitSystem.metric), closeTo(1968.5, 0.001));

      expect(UnitConverter.fromFpm(1968.5, UnitSystem.imperial), closeTo(1968.5, 0.001));
      expect(UnitConverter.fromFpm(1968.5, UnitSystem.metric), closeTo(10, 0.001));
    });

    test('Length conversions (inches <-> mm)', () {
      expect(UnitConverter.toInches(254, UnitSystem.imperial), closeTo(254, 0.001));
      expect(UnitConverter.toInches(254, UnitSystem.metric), closeTo(10, 0.001));

      expect(UnitConverter.fromInches(10, UnitSystem.imperial), closeTo(10, 0.001));
      expect(UnitConverter.fromInches(10, UnitSystem.metric), closeTo(254, 0.001));
    });

    test('Friction conversions (in.wg/100ft <-> Pa/m)', () {
      expect(UnitConverter.toInWg(8, UnitSystem.imperial), closeTo(8, 0.001));
      expect(UnitConverter.toInWg(8, UnitSystem.metric), closeTo(0.98, 0.001));

      expect(UnitConverter.fromInWg(0.98, UnitSystem.imperial), closeTo(0.98, 0.001));
      expect(UnitConverter.fromInWg(0.98, UnitSystem.metric), closeTo(8, 0.001));
    });

    test('toImperial input conversion', () {
      final metricInput = HvacInput(
        flowRate: 1000,
        targetVelocity: 5,
        frictionRate: 1.5,
        method: CalculationMethod.velocity,
        unitSystem: UnitSystem.metric,
        systemType: SystemType.supplyMain,
      );

      final imperialInput = UnitConverter.toImperial(metricInput);

      expect(imperialInput.unitSystem, UnitSystem.imperial);
      expect(imperialInput.flowRate, closeTo(588.6, 0.01));
      expect(imperialInput.targetVelocity, closeTo(984.25, 0.01));
      expect(imperialInput.frictionRate, closeTo(0.18375, 0.01));
      expect(imperialInput.method, CalculationMethod.velocity);
      expect(imperialInput.systemType, SystemType.supplyMain);
    });

    test('toImperial returns same for imperial input', () {
      final imperialInput = HvacInput(
        flowRate: 1000,
        targetVelocity: 800,
        frictionRate: 0.1,
        method: CalculationMethod.velocity,
        unitSystem: UnitSystem.imperial,
        systemType: SystemType.supplyMain,
      );
      final result = UnitConverter.toImperial(imperialInput);
      expect(result, same(imperialInput));
    });

    test('resultToMetric converts output correctly', () {
      final imperialResult = HvacResult(
        roundResult: const RoundResult(
          calculatedDiameter: 10.0,
          standardDiameter: 10.0,
          velocity: 800.0,
          frictionRate: 0.1,
          area: 78.54,
        ),
        rectangleOptions: [
          const RectangleOption(
            width: 12.0,
            height: 8.0,
            area: 96.0,
            velocity: 750.0,
            equivalentDiameter: 10.5,
            aspectRatio: 1.5,
            score: 85.0,
            stars: 4,
            preferred: true,
            velocityError: 0.05,
            equivalentDiameterError: 0.05,
          ),
        ],
        warnings: [
          const HvacWarning(
            type: WarningType.highVelocity,
            message: 'Vận tốc gió cao hơn mức khuyến nghị, có thể gây tiếng ồn lớn.',
            severity: WarningSeverity.warning,
          ),
        ],
        metadata: CalculationMetadata(
          timestamp: DateTime.now(),
          algorithmVersion: '1.2.0',
          standard: 'SMACNA / ASHRAE',
        ),
      );

      final metricResult = UnitConverter.resultToMetric(imperialResult);

      expect(metricResult.roundResult.calculatedDiameter, closeTo(10.0 * 25.4, 0.01));
      expect(metricResult.roundResult.standardDiameter, closeTo(10.0 * 25.4, 0.01));
      expect(metricResult.roundResult.velocity, closeTo(800.0 / 196.85, 0.01));
      expect(metricResult.roundResult.frictionRate, closeTo(0.1 / 0.1225, 0.01));
      expect(metricResult.roundResult.area, closeTo(78.54 * 645.16, 0.01));

      expect(metricResult.rectangleOptions.length, 1);
      final opt = metricResult.rectangleOptions.first;
      expect(opt.width, closeTo(12.0 * 25.4, 0.01));
      expect(opt.height, closeTo(8.0 * 25.4, 0.01));
      expect(opt.area, closeTo(96.0 * 645.16, 0.01));
      expect(opt.velocity, closeTo(750.0 / 196.85, 0.01));
      expect(opt.equivalentDiameter, closeTo(10.5 * 25.4, 0.01));
      expect(opt.aspectRatio, 1.5);
      expect(opt.score, 85.0);
      expect(opt.stars, 4);
      expect(opt.preferred, true);
      expect(opt.velocityError, 0.05);
      expect(opt.equivalentDiameterError, 0.05);

      expect(metricResult.warnings.first.type, WarningType.highVelocity);
      expect(metricResult.warnings.first.message, 'Vận tốc gió cao hơn mức khuyến nghị, có thể gây tiếng ồn lớn.');
      expect(metricResult.metadata.algorithmVersion, '1.2.0');
    });
  });

  group('DuctEngine Tests', () {
    test('DuctEngine throws ArgumentError for metric system', () {
      final metricInput = HvacInput(
        flowRate: 1000,
        targetVelocity: 800,
        frictionRate: 0.1,
        method: CalculationMethod.velocity,
        unitSystem: UnitSystem.metric,
        systemType: SystemType.supplyMain,
      );
      expect(() => DuctEngine.calculate(metricInput, StandardSizes.imperialRect), throwsA(isA<ArgumentError>()));
    });

    test('DuctEngine calculates correctly for Velocity Method', () {
      final input = HvacInput(
        flowRate: 1000,
        targetVelocity: 800,
        frictionRate: 0.1,
        method: CalculationMethod.velocity,
        unitSystem: UnitSystem.imperial,
        systemType: SystemType.supplyMain,
      );
      final res = DuctEngine.calculate(input, StandardSizes.imperialRect);

      expect(res.roundResult.calculatedDiameter, closeTo(15.1378, 0.01));
      expect(res.roundResult.standardDiameter, 16.0);
      expect(res.roundResult.velocity, closeTo(716.197, 0.01));
      expect(res.roundResult.frictionRate, 0.1);
      expect(res.roundResult.area, closeTo(201.061, 0.01));

      expect(res.rectangleOptions.isNotEmpty, isTrue);
      for (int i = 0; i < res.rectangleOptions.length - 1; i++) {
        expect(res.rectangleOptions[i].score, greaterThanOrEqualTo(res.rectangleOptions[i + 1].score));
      }
    });

    test('DuctEngine calculates correctly for Equal Friction Method', () {
      final input = HvacInput(
        flowRate: 1000,
        targetVelocity: 800,
        frictionRate: 0.1,
        method: CalculationMethod.equalFriction,
        unitSystem: UnitSystem.imperial,
        systemType: SystemType.supplyMain,
      );
      final res = DuctEngine.calculate(input, StandardSizes.imperialRect);

      expect(res.roundResult.calculatedDiameter, closeTo(13.6086, 0.01));
      expect(res.roundResult.standardDiameter, 14.0);
      expect(res.roundResult.velocity, closeTo(935.44, 0.01));
      expect(res.roundResult.frictionRate, 0.1);
      expect(res.roundResult.area, closeTo(153.938, 0.01));

      expect(res.rectangleOptions.isNotEmpty, isTrue);
    });

    test('DuctEngine adds warning for velocity > 1200 fpm', () {
      final highVelocityInput = HvacInput(
        flowRate: 2000,
        targetVelocity: 1500,
        frictionRate: 0.1,
        method: CalculationMethod.velocity,
        unitSystem: UnitSystem.imperial,
        systemType: SystemType.supplyMain,
      );
      final res = DuctEngine.calculate(highVelocityInput, StandardSizes.imperialRect);
      expect(res.warnings.length, 1);
      expect(res.warnings.first.type, WarningType.highVelocity);
      expect(res.warnings.first.message, 'Vận tốc gió cao hơn mức khuyến nghị, có thể gây tiếng ồn lớn.');
      expect(res.warnings.first.severity, WarningSeverity.warning);
    });

    test('DuctEngine does not add warning for velocity <= 1200 fpm', () {
      final normalVelocityInput = HvacInput(
        flowRate: 1000,
        targetVelocity: 1000,
        frictionRate: 0.1,
        method: CalculationMethod.velocity,
        unitSystem: UnitSystem.imperial,
        systemType: SystemType.supplyMain,
      );
      final res = DuctEngine.calculate(normalVelocityInput, StandardSizes.imperialRect);
      expect(res.warnings.isEmpty, isTrue);
    });

    test('DuctEngine evaluates actualRoundVelocity instead of targetVelocity for high velocity warning', () {
      final input = HvacInput(
        flowRate: 940,
        targetVelocity: 1250,
        frictionRate: 0.1,
        method: CalculationMethod.velocity,
        unitSystem: UnitSystem.imperial,
        systemType: SystemType.supplyMain,
      );
      final res = DuctEngine.calculate(input, StandardSizes.imperialRect);
      expect(res.warnings.isEmpty, isTrue);
    });
  });
}
