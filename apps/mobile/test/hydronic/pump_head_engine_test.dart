import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/hvac/models/enums.dart';
import 'package:mobile/features/hydronic/constants/hydronic_constants.dart';
import 'package:mobile/features/hydronic/data/fitting_coefficients.dart';
import 'package:mobile/features/hydronic/formulas/pipe_pressure_loss_engine.dart';
import 'package:mobile/features/hydronic/formulas/pump_head_engine.dart';

void main() {
  group('Pump Head Engine — basic calculation', () {
    test('static head only (no friction): TDH ≈ elevation', () {
      final r = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 50, // GPM (won't matter — pipe length = 0)
          pipeDiameterIn: 2.067,
          pipeLengthFt: 0, // no pipe → no friction
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          staticHeadFt: 30, // 30 ft elevation
          unit: UnitSystem.imperial,
        ),
      )!;

      // TDH should be approximately 30 ft + small velocity head (≈0)
      expect(r.staticHeadFt, closeTo(30.0, 0.1));
      expect(r.totalHeadFt, closeTo(30.0, 1.0));
      expect(r.frictionHeadFt, closeTo(0.0, 0.01));
    });

    test('with friction: 100 GPM, 2" Sch40 steel, 100 ft, 30 ft elev', () {
      final r = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 100,
          pipeDiameterIn: 2.067,
          pipeLengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          staticHeadFt: 30,
          unit: UnitSystem.imperial,
        ),
      )!;

      // Static ≈ 30 ft; friction ≈ 17.4 ft (per pipe pressure loss engine);
      // velocity head small. TDH ≈ 47.5 ft
      expect(r.staticHeadFt, closeTo(30.0, 0.1));
      expect(r.frictionHeadFt, closeTo(17.4, 1.0));
      expect(r.totalHeadFt, greaterThan(45));
      expect(r.totalHeadFt, lessThan(50));
    });

    test('pressure differential reduces static head', () {
      // If discharge pressure > suction pressure, pump does less work
      // on the pressure side (head is partially recovered).
      // suction = 5 PSI, discharge = 0 PSI (atmospheric)
      // ΔP = 0 - 5 = -5 PSI  →  pressureHead = -5 / (ρg) ≈ -11.55 ft
      // H_static = 30 + (-11.55) ≈ 18.45 ft
      final r = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 100,
          pipeDiameterIn: 2.067,
          pipeLengthFt: 0,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          staticHeadFt: 30,
          suctionPressurePsi: 5.0,
          dischargePressurePsi: 0.0,
          unit: UnitSystem.imperial,
        ),
      )!;

      // 5 PSI = 11.55 ft of water head
      expect(r.staticHeadFt, closeTo(30.0 - 11.55, 0.5));
    });

    test('pressure differential adds to static head', () {
      // suction = 0 (atmospheric), discharge = 5 PSI (pressurized tank)
      // → pump must overcome this pressure plus elevation
      final r = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 100,
          pipeDiameterIn: 2.067,
          pipeLengthFt: 0,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          staticHeadFt: 30,
          suctionPressurePsi: 0.0,
          dischargePressurePsi: 5.0,
          unit: UnitSystem.imperial,
        ),
      )!;

      // 5 PSI = +11.55 ft of water head
      expect(r.staticHeadFt, closeTo(30.0 + 11.55, 0.5));
    });
  });

  group('Pump Head Engine — power calculations', () {
    test('hydraulic power scales linearly with Q and H', () {
      // Same head, double flow → double water power
      final r1 = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 50,
          pipeDiameterIn: 2.067,
          pipeLengthFt: 0,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          staticHeadFt: 50,
          unit: UnitSystem.imperial,
        ),
      )!;

      final r2 = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 100,
          pipeDiameterIn: 2.067,
          pipeLengthFt: 0,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          staticHeadFt: 50,
          unit: UnitSystem.imperial,
        ),
      )!;

      // For same H, P ∝ Q. So P(100)/P(50) ≈ 2.
      expect(r2.waterPowerHp / r1.waterPowerHp, closeTo(2.0, 0.05));
    });

    test('brake power > water power (motor efficiency < 1)', () {
      final r = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 100,
          pipeDiameterIn: 2.067,
          pipeLengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          staticHeadFt: 30,
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(r.brakePowerHp, greaterThan(r.waterPowerHp));
      expect(r.brakePowerHp, lessThan(r.waterPowerHp * 2));
      expect(r.motorEfficiency, greaterThan(0));
      expect(r.motorEfficiency, lessThanOrEqualTo(1.0));
    });

    test('motor efficiency tier lookup', () {
      // For typical hydronic pump (small to medium): 0.7–0.95 range
      final r = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 200,
          pipeDiameterIn: 3.068,
          pipeLengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          staticHeadFt: 60,
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(r.motorEfficiency, greaterThan(0.5));
      expect(r.motorEfficiency, lessThanOrEqualTo(0.95));
    });
  });

  group('Pump Head Engine — fittings', () {
    test('fittings add to friction head', () {
      final noFittings = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 100,
          pipeDiameterIn: 2.067,
          pipeLengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          staticHeadFt: 0,
          unit: UnitSystem.imperial,
        ),
      )!;

      final withFittings = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 100,
          pipeDiameterIn: 2.067,
          pipeLengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          staticHeadFt: 0,
          fittings: [
            FittingEntry(
              type: FittingType.elbow90Threaded,
              nominalSizeIn: 2.0,
              quantity: 4,
            ),
          ],
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(
        withFittings.frictionHeadFt,
        greaterThan(noFittings.frictionHeadFt),
      );
    });
  });

  group('Pump Head Engine — unit conversions', () {
    test(
      'metric input: 100 m³/h, 50mm, 30m, 10m elev → produces valid TDH',
      () {
        final r = PumpHeadEngine.calculate(
          const PumpHeadInput(
            flowRate: 100,
            pipeDiameterIn: 50, // mm
            pipeLengthFt: 30, // m (unit is metric)
            material: PipeMaterial.steelBlack,
            service: PipeService.chilledWater,
            staticHeadFt: 10, // m
            unit: UnitSystem.metric,
          ),
        )!;

        // 10 m static + friction + velocity head
        expect(r.totalHeadM, greaterThan(10.0));
        expect(r.totalHeadFt, greaterThan(r.totalHeadM)); // ft > m numerically
      },
    );

    test(
      'metric and imperial produce identical results for same conditions',
      () {
        // 100 GPM, 2" steel, 100 ft, 30 ft elev  ≈  6.31 L/s, 50.8mm steel,
        // 30.48m, 9.14m elev (equivalent after rounding)
        final imperial = PumpHeadEngine.calculate(
          const PumpHeadInput(
            flowRate: 100,
            pipeDiameterIn: 2.067,
            pipeLengthFt: 100,
            material: PipeMaterial.steelBlack,
            service: PipeService.chilledWater,
            staticHeadFt: 30,
            unit: UnitSystem.imperial,
          ),
        )!;

        final metric = PumpHeadEngine.calculate(
          const PumpHeadInput(
            flowRate: 22.7125, // 100 GPM ≈ 22.71 m³/h
            pipeDiameterIn: 52.5, // 2.067" ≈ 52.5mm
            pipeLengthFt: 30.48, // 100 ft
            material: PipeMaterial.steelBlack,
            service: PipeService.chilledWater,
            staticHeadFt: 9.144, // 30 ft
            unit: UnitSystem.metric,
          ),
        )!;

        expect(imperial.totalHeadFt, closeTo(metric.totalHeadFt, 2.0));
        expect(imperial.totalHeadM, closeTo(metric.totalHeadM, 0.5));
      },
    );
  });

  group('Pump Head Engine — pressure equivalents', () {
    test('head to PSI conversion is consistent', () {
      final r = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 100,
          pipeDiameterIn: 2.067,
          pipeLengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          staticHeadFt: 100, // 100 ft → ~43.35 PSI
          unit: UnitSystem.imperial,
        ),
      )!;

      // 100 ft of water ≈ 43.35 PSI
      expect(r.staticHeadPsi, closeTo(43.35, 0.5));
    });

    test('head to kPa conversion is consistent', () {
      // 1 m of water ≈ 9.806 kPa
      final r = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 0.001,
          pipeDiameterIn: 100,
          pipeLengthFt: 0,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          staticHeadFt: 1.0, // 1 m
          unit: UnitSystem.metric,
        ),
      )!;

      // 1 m of water ≈ 9.806 kPa (use small flow so velocity head is negligible)
      expect(r.totalHeadKpa, closeTo(9.806, 0.5));
    });
  });

  group('Pump Head Engine — invalid inputs', () {
    test('zero flow returns null', () {
      final r = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 0,
          pipeDiameterIn: 2.067,
          pipeLengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      );
      expect(r, isNull);
    });

    test('zero diameter returns null', () {
      final r = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 100,
          pipeDiameterIn: 0,
          pipeLengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      );
      expect(r, isNull);
    });

    test('negative flow returns null', () {
      final r = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: -10,
          pipeDiameterIn: 2.067,
          pipeLengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      );
      expect(r, isNull);
    });
  });

  group('Pump Head Engine — warnings', () {
    test('excessive velocity triggers warning', () {
      // ignore: unused_local_variable
      final r = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 500,
          pipeDiameterIn: 1.049, // small pipe → high velocity
          pipeLengthFt: 50,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          staticHeadFt: 30,
          unit: UnitSystem.imperial,
        ),
      );

      expect(r!.warnings, isNotEmpty);
      expect(r.warnings.any((w) => w.contains('m/s vuot')), isTrue);
    });

    test('normal conditions produce no warnings', () {
      final r = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 100,
          pipeDiameterIn: 2.067,
          pipeLengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          staticHeadFt: 30,
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(r.warnings, isEmpty);
    });
  });

  group('Pump Head Engine — Hazen-Williams method', () {
    test('H-W method produces valid result', () {
      final r = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 100,
          pipeDiameterIn: 2.067,
          pipeLengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          staticHeadFt: 30,
          method: FrictionMethod.hazenWilliams,
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(r.frictionHeadFt, greaterThan(0));
      expect(r.totalHeadFt, greaterThan(30));
    });
  });

  group('Pump Head Engine — round-trip conversions', () {
    test('imperial → metric → imperial preserves TDH', () {
      final imperial = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 100,
          pipeDiameterIn: 2.067,
          pipeLengthFt: 100,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          staticHeadFt: 30,
          unit: UnitSystem.imperial,
        ),
      )!;

      // Convert to metric: 100 GPM ≈ 22.7125 m³/h, 2.067" ≈ 52.5mm,
      // 100 ft ≈ 30.48m, 30 ft ≈ 9.144m
      final metric = PumpHeadEngine.calculate(
        const PumpHeadInput(
          flowRate: 22.7125,
          pipeDiameterIn: 52.5,
          pipeLengthFt: 30.48,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          staticHeadFt: 9.144,
          unit: UnitSystem.metric,
        ),
      )!;

      // Head values should match within rounding
      expect(metric.totalHeadFt, closeTo(imperial.totalHeadFt, 2.0));
    });
  });
}
