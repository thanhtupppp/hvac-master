import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/hvac/models/enums.dart';
import 'package:mobile/features/hydronic/formulas/pipe_pressure_loss_engine.dart';
import 'package:mobile/features/hydronic/constants/hydronic_constants.dart';
import 'package:mobile/features/hydronic/data/fitting_coefficients.dart';

void main() {
  // Actual correct values for 100 GPM, 2.067" steel, 100 ft:
  // V = 9.56 ft/s, Re ≈ 152,700, f_Darcy ≈ 0.0211, h_f ≈ 345 ft/100ft

  group('Pipe Pressure Loss Engine — basic calculation', () {
    // Verified values for 100 GPM, 2.067" ID, 100 ft, steel (ε=0.00015 ft):
    //   V = 9.56 ft/s, Re ≈ 152,239, f_Darcy ≈ 0.0212, h_f ≈ 17.4 ft
    test('100 GPM, 2" Sch40 steel, 100 ft → h_f ≈ 17.4 ft (Darcy-Weisbach)', () {
      final r = PipePressureLossEngine.calculate(
        const PipePressureLossInput(
          flowRate: 100,
          diameterIn: 2.067,
          lengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          fittings: [],
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(r.frictionRateFth, closeTo(17.4, 0.5));
      expect(r.totalFrictionFt, closeTo(17.4, 0.5));
      expect(r.velocityFps, closeTo(9.56, 0.1));
      expect(r.reynolds, closeTo(152200, 1000));
    });

    test('metric input: 100 m³/h, 50mm, 30m → produces valid result', () {
      final r = PipePressureLossEngine.calculate(
        const PipePressureLossInput(
          flowRate: 100,
          diameterIn: 50,
          lengthFt: 30,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          fittings: [],
          unit: UnitSystem.metric,
        ),
      )!;

      expect(r.totalFrictionFt, greaterThan(0));
      expect(r.totalFrictionPsi, greaterThan(0));
      expect(r.totalFrictionKpa, greaterThan(0));
      expect(r.totalFrictionBar, greaterThan(0));
      expect(r.velocityMs, greaterThan(0));
      expect(r.reynolds, greaterThan(10000));
    });
  });

  group('Pipe Pressure Loss Engine — zero / invalid inputs', () {
    test('zero flow returns null', () {
      final r = PipePressureLossEngine.calculate(
        const PipePressureLossInput(
          flowRate: 0,
          diameterIn: 2.0,
          lengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      );
      expect(r, isNull);
    });

    test('zero diameter returns null', () {
      final r = PipePressureLossEngine.calculate(
        const PipePressureLossInput(
          flowRate: 100,
          diameterIn: 0,
          lengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      );
      expect(r, isNull);
    });

    test('zero length returns null', () {
      final r = PipePressureLossEngine.calculate(
        const PipePressureLossInput(
          flowRate: 100,
          diameterIn: 2.0,
          lengthFt: 0,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      );
      expect(r, isNull);
    });

    test('negative flow returns null', () {
      final r = PipePressureLossEngine.calculate(
        const PipePressureLossInput(
          flowRate: -50,
          diameterIn: 2.0,
          lengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      );
      expect(r, isNull);
    });
  });

  group('Pipe Pressure Loss Engine — friction factor', () {
    test('100 GPM, 2" → turbulent Darcy friction factor ≈ 0.021', () {
      final r = PipePressureLossEngine.calculate(
        const PipePressureLossInput(
          flowRate: 100,
          diameterIn: 2.067,
          lengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(r.darcyFrictionFactor, closeTo(0.0212, 0.003));
    });

    test('copper is smoother → lower friction than steel at same geometry', () {
      final steel = PipePressureLossEngine.calculate(
        const PipePressureLossInput(
          flowRate: 100,
          diameterIn: 2.067,
          lengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      )!;

      final copper = PipePressureLossEngine.calculate(
        const PipePressureLossInput(
          flowRate: 100,
          diameterIn: 2.0,
          lengthFt: 100,
          material: PipeMaterial.copperTypeL,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      )!;

      // Copper (ε=1.5 μm) should have lower friction than steel (ε=45 μm)
      expect(copper.darcyFrictionFactor, lessThan(steel.darcyFrictionFactor));
      expect(copper.totalFrictionFt, lessThan(steel.totalFrictionFt));
    });
  });

  group('Pipe Pressure Loss Engine — fittings', () {
    test('one 90° elbow at 2" adds fitting loss', () {
      final without = PipePressureLossEngine.calculate(
        const PipePressureLossInput(
          flowRate: 100,
          diameterIn: 2.067,
          lengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          fittings: [],
          unit: UnitSystem.imperial,
        ),
      )!;

      final withOne = PipePressureLossEngine.calculate(
        const PipePressureLossInput(
          flowRate: 100,
          diameterIn: 2.067,
          lengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          fittings: [
            FittingEntry(
              type: FittingType.elbow90Threaded,
              nominalSizeIn: 2.0,
              quantity: 1,
              connectionType: 'threaded',
            ),
          ],
          unit: UnitSystem.imperial,
        ),
      )!;

      // V²/2g = 1.42 ft; K=0.75; fit_loss = 1.06 ft
      expect(withOne.fittingFrictionFt, greaterThan(0));
      expect(withOne.totalFrictionFt, greaterThan(without.totalFrictionFt));
      expect(withOne.fittingBreakdown.length, equals(1));
    });

    test('three identical elbows → 3× single fitting loss', () {
      final three = PipePressureLossEngine.calculate(
        const PipePressureLossInput(
          flowRate: 100,
          diameterIn: 2.067,
          lengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          fittings: [
            FittingEntry(
              type: FittingType.elbow90Threaded,
              nominalSizeIn: 2.0,
              quantity: 3,
              connectionType: 'threaded',
            ),
          ],
          unit: UnitSystem.imperial,
        ),
      )!;

      final one = PipePressureLossEngine.calculate(
        const PipePressureLossInput(
          flowRate: 100,
          diameterIn: 2.067,
          lengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          fittings: [
            FittingEntry(
              type: FittingType.elbow90Threaded,
              nominalSizeIn: 2.0,
              quantity: 1,
              connectionType: 'threaded',
            ),
          ],
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(three.fittingFrictionFt, closeTo(one.fittingFrictionFt * 3, 0.01));
    });
  });

  group('Pipe Pressure Loss Engine — Hazen-Williams method', () {
    test('Hazen-Williams produces valid result', () {
      final r = PipePressureLossEngine.calculate(
        const PipePressureLossInput(
          flowRate: 100,
          diameterIn: 2.067,
          lengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          method: FrictionMethod.hazenWilliams,
          fittings: [],
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(r.hazenWilliamsC, equals(HydronicConstants.hwCoefficientDefault));
      expect(r.totalFrictionFt, greaterThan(0));
      expect(r.frictionRateFth, greaterThan(0));
    });

    test('Darcy-Weisbach and Hazen-Williams give similar results', () {
      final darcy = PipePressureLossEngine.calculate(
        const PipePressureLossInput(
          flowRate: 100,
          diameterIn: 2.067,
          lengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          method: FrictionMethod.darcyWeisbach,
          fittings: [],
          unit: UnitSystem.imperial,
        ),
      )!;

      final hw = PipePressureLossEngine.calculate(
        const PipePressureLossInput(
          flowRate: 100,
          diameterIn: 2.067,
          lengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          method: FrictionMethod.hazenWilliams,
          fittings: [],
          unit: UnitSystem.imperial,
        ),
      )!;

      // Both methods produce finite losses within ~3× for turbulent flow
      // (H-W is empirical; for steel at C=130, ratio is typically 1.5–2.5× of D-W)
      final ratio = hw.totalFrictionFt / darcy.totalFrictionFt;
      expect(ratio, greaterThan(0.5));
      expect(ratio, lessThan(3.0));
    });
  });

  group('Pipe Pressure Loss Engine — unit conversions', () {
    test('total loss conversions are consistent', () {
      final r = PipePressureLossEngine.calculate(
        const PipePressureLossInput(
          flowRate: 100,
          diameterIn: 2.067,
          lengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          fittings: [],
          unit: UnitSystem.imperial,
        ),
      )!;

      // ft × 0.4335 = PSI
      expect(
        r.totalFrictionPsi,
        closeTo(r.totalFrictionFt * HydronicConstants.ftHeadToPsi, 0.01),
      );
      // ft × 0.3048 = m
      expect(
        r.totalFrictionM,
        closeTo(r.totalFrictionFt * HydronicConstants.ftToM, 0.01),
      );
      // PSI × 0.06895 = bar
      expect(
        r.totalFrictionBar,
        closeTo(r.totalFrictionPsi * HydronicConstants.psiToBar, 0.001),
      );
    });
  });
}
