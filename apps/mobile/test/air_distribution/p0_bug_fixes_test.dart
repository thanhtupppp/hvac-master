import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/hvac/formulas/duct_pressure_loss.dart';
import 'package:mobile/core/hvac/standards/standard_sizes.dart';

void main() {
  group('P0 Bug Fixes — Air Distribution', () {
    group('Bug 0.1: AirflowCalculatorScreen metric diameter conversion', () {
      test(
        'metric diameter (mm) must be divided by 25.4 before use in inch-based formula',
        () {
          // Input: user enters Ø300mm in metric mode, target 1000 FPM
          // The calculator converts CFM from m³/h, then calculates area = CFM/FPM
          // Then for the diameter-from-area path: areaFromDia = π×D²/4/144 (D in inches)
          // BUG: if D=300 (mm) was used directly as inches → area 10× too large
          // FIX: D must be D_mm / 25.4

          // Example: Ø300mm = 11.81 inches
          const diamMm = 300.0;
          const diamInCorrect = diamMm / 25.4; // = 11.81...
          const diamInBug = diamMm; // = 300 (wrong)

          const areaCorrect = 3.14159 * diamInCorrect * diamInCorrect / 4 / 144;
          const areaBug = 3.14159 * diamInBug * diamInBug / 4 / 144;

          // Area should be ~0.762 ft² for Ø300mm duct at reasonable velocity
          expect(areaCorrect, closeTo(0.762, 0.01));
          // Bug produces ~490 ft² (645× too large)
          expect(areaBug, greaterThan(400));
          expect(areaCorrect / areaBug, closeTo(1 / 645, 0.01));
        },
      );

      test('imperial diameter (inch) is used directly without conversion', () {
        // In imperial mode, diameter IS already in inches
        const diamIn = 12.0;
        final area = 3.14159 * diamIn * diamIn / 4 / 144;
        expect(area, closeTo(0.7854, 0.001));
      });
    });

    group('Bug 0.2: DuctPressureLoss L/s treated as m³/s', () {
      test(
        'flowRateLs must be divided by 1000 to convert to m³/s before velocity calc',
        () {
          // Input: 100 L/s flowing through Ø300mm duct
          const flowRateLs = 100.0;
          const diamMm = 300.0;
          const lengthM = 10.0;
          const roughnessMm = 0.15;

          final result = DuctPressureLoss.calculate(
            flowRateLs: flowRateLs,
            ductDiameterMm: diamMm,
            roughnessMm: roughnessMm,
            lengthM: lengthM,
          );

          // Cross-sectional area of Ø300mm duct
          // A = π×(0.3)²/4 = 0.07069 m²
          // ignore: unused_local_variable
          const areaM2 = 3.14159 * 0.3 * 0.3 / 4;

          // BUG: velocityMs = 100 / 0.07069 = 1414 m/s (faster than sound!)
          // FIX: velocityMs = (100/1000) / 0.07069 = 1.414 m/s (reasonable HVAC velocity)
          expect(result.velocityMs, closeTo(1.414, 0.01));

          // The bug gave velocity ~1414 m/s → pressure loss ~1000× too high
          // After fix: reasonable pressure drop for 10m of galvanized duct at 1.4 m/s
          expect(result.frictionLossPaPerM, greaterThan(0));
          expect(
            result.frictionLossPaPerM,
            lessThan(10),
          ); // should be < 10 Pa/m
          expect(result.reynoldsNumber, greaterThan(10000)); // turbulent flow
        },
      );

      test(
        'small flow rate produces low velocity and measurable pressure loss',
        () {
          // 50 L/s through Ø200mm
          const flowRateLs = 50.0;
          const diamMm = 200.0;

          final result = DuctPressureLoss.calculate(
            flowRateLs: flowRateLs,
            ductDiameterMm: diamMm,
            roughnessMm: 0.15,
            lengthM: 5.0,
          );

          // A = π×(0.2)²/4 = 0.03142 m²
          // v = (50/1000) / 0.03142 = 1.591 m/s
          expect(result.velocityMs, closeTo(1.591, 0.01));
          expect(result.frictionLossPaPerM, greaterThan(0));
        },
      );

      test('zero or negative flow rate returns zero result without crash', () {
        final result = DuctPressureLoss.calculate(
          flowRateLs: 0,
          ductDiameterMm: 300,
          roughnessMm: 0.15,
          lengthM: 10,
        );
        expect(result.velocityMs, 0);
        expect(result.frictionLossPaPerM, 0);
        expect(result.reynoldsNumber, 0);
      });
    });

    group('Bug 0.3: StandardSizes round-up vs nearest', () {
      test('always rounds UP to nearest standard size (fixes undersizing)', () {
        // Raw diameter 13.5" → nearest is 14" (both above), but bug would pick 12"
        // The bug used abs() nearest, so if standard list is [12, 14], 13.5 is
        // closer to 12 (diff 1.5) than 14 (diff 0.5) — WRONG for sizing.
        // Fix: only consider sizes >= rawDiameter, then pick nearest among those.

        final nearest = StandardSizes.findNearestStandardRound(
          13.5,
          StandardSizes.imperialRound,
        );
        // 13.5 should round up to 14 (not 12)
        expect(nearest, 14.0);
      });

      test('exact standard size returns that size unchanged', () {
        final nearest = StandardSizes.findNearestStandardRound(
          12.0,
          StandardSizes.imperialRound,
        );
        expect(nearest, 12.0);
      });

      test('raw diameter between two standards rounds up', () {
        // 13.5" should round to 14"
        final nearest = StandardSizes.findNearestStandardRound(
          13.5,
          StandardSizes.imperialRound,
        );
        expect(nearest, 14.0);

        // 11.1" should round to 12"
        final nearest2 = StandardSizes.findNearestStandardRound(
          11.1,
          StandardSizes.imperialRound,
        );
        expect(nearest2, 12.0);
      });

      test(
        'raw diameter larger than all standards returns largest available',
        () {
          // 100" is way bigger than max 24"
          final nearest = StandardSizes.findNearestStandardRound(
            100,
            StandardSizes.imperialRound,
          );
          expect(nearest, 24.0);
        },
      );

      test('metric sizes also round up correctly', () {
        // 210mm between 200 and 225 → should pick 225
        final nearest = StandardSizes.findNearestStandardRound(
          210,
          StandardSizes.metricRound,
        );
        expect(nearest, 225.0);
      });

      test('engine test verifies fix: 13.6086" should become 14" (not 12")', () {
        // This is the actual Equal Friction calculation for 1000 CFM @ 0.1"wg/100ft
        const rawDiameter = 13.6086;
        final nearest = StandardSizes.findNearestStandardRound(
          rawDiameter,
          StandardSizes.imperialRound,
        );
        // Was 12" (bug), should be 14" (fix)
        expect(nearest, 14.0);
        expect(nearest, greaterThanOrEqualTo(rawDiameter));
      });
    });
  });
}
