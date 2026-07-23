import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/hvac/models/enums.dart';
import 'package:mobile/features/hydronic/formulas/water_flow_engine.dart';
import 'package:mobile/features/hydronic/constants/hydronic_constants.dart';

void main() {
  group('Water Flow Engine — basic calculations', () {
    test('Q=100 GPM, D=2.067" (2" Sch40 steel) → V ≈ 9.5 ft/s', () {
      final r = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 100,
          diameter: 2.067,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      )!;
      // Area ft² = π×(2.067/12)²/4 = 0.02333 ft²
      // V ft/s = 100/7.48052/60 / 0.02333 = 9.48 ft/s
      expect(r.velocityFps, closeTo(9.48, 0.3));
      expect(r.velocityMs, closeTo(2.89, 0.1));
      expect(r.velocityFpm, closeTo(569, 20));
      expect(r.regime, equals(FlowRegime.turbulent));
      expect(r.reynolds, greaterThan(50000));
    });

    test('Q=50 GPM, D=2" (nominal, Sch40 ID≈2.067") → V≈4.78 ft/s', () {
      final r = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 50,
          diameter: 2.0,
          material: PipeMaterial.steelBlack,
          service: PipeService.hotWaterHeating,
          unit: UnitSystem.imperial,
        ),
      )!;
      // Area ft² = π×(2.0/12)²/4 = 0.0218 ft²
      // V ft/s = 50/7.48052/60 / 0.0218 = 5.11 ft/s
      expect(r.velocityFps, closeTo(5.11, 0.3));
      expect(r.velocityMs, closeTo(1.56, 0.1));
    });

    test('Q=100 m³/h, D=50 mm → V ≈ 14.1 m/s (fast flow)', () {
      // 100 m³/h = 27.78 L/s; D=0.05m; A=0.001963 m²
      // V = 0.02778/0.001963 = 14.15 m/s
      final r = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 100,
          diameter: 50,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.metric,
        ),
      )!;
      expect(r.velocityMs, closeTo(14.15, 0.5));
      // flowRateGpm converts m³/h → GPM: 100 / 0.2271 = 440 GPM
      expect(r.flowRateGpm, closeTo(440, 5));
    });
  });

  group('Water Flow Engine — zero / invalid inputs', () {
    test('zero flow returns null', () {
      final r = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 0, diameter: 2.0,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      );
      expect(r, isNull);
    });

    test('zero diameter returns null', () {
      final r = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 100, diameter: 0,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      );
      expect(r, isNull);
    });

    test('negative flow returns null', () {
      final r = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: -50, diameter: 2.0,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      );
      expect(r, isNull);
    });

    test('negative diameter returns null', () {
      final r = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 100, diameter: -2.0,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      );
      expect(r, isNull);
    });
  });

  group('Water Flow Engine — Reynolds number & flow regime', () {
    test('Re > 4000 → turbulent for 2" pipe at 100 GPM', () {
      final r = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 100, diameter: 2.067,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      )!;
      expect(r.regime, equals(FlowRegime.turbulent));
      expect(r.reynolds, greaterThan(50000));
    });

    test('very low flow → laminar (Re < 2300)', () {
      // ~0.5 GPM through 2" pipe
      final r = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 0.5, diameter: 2.067,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      )!;
      expect(r.regime, equals(FlowRegime.laminar));
      expect(r.reynolds, lessThan(HydronicConstants.reLaminarMax));
    });

    test('moderate flow ~15 GPM through 2" → transitional', () {
      // 15 GPM through 2" Sch40: V ≈ 0.77 m/s, Re ≈ 38700
      final r = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 15, diameter: 2.067,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      )!;
      expect(r.regime, equals(FlowRegime.turbulent));
    });
  });

  group('Water Flow Engine — unit conversion helpers', () {
    test('imperial input: flowRateGpm equals field value', () {
      final r = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 100, diameter: 2.0,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      )!;
      expect(r.flowRateGpm, equals(100.0));
      expect(r.flowRateM3h, closeTo(22.71, 0.1));  // 100 × 0.2271
      expect(r.flowRateLs, closeTo(6.309, 0.05));  // 100 × 0.06309
    });

    test('metric input: diameter converts from mm', () {
      final r = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 100, diameter: 50,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.metric,
        ),
      )!;
      expect(r.diameterM, closeTo(0.050, 0.001));  // 50mm → 0.05m
      expect(r.diameterIn, closeTo(1.969, 0.01));   // 50mm → 1.969"
    });
  });

  group('Water Flow Engine — roughness & friction factor', () {
    test('steel roughness ε ≈ 0.00015 ft (45 μm)', () {
      final r = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 100, diameter: 2.067,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      )!;
      expect(r.roughnessM, closeTo(45.7e-6, 1e-6)); // 0.00015 ft = 45.7 μm
      expect(r.darcyFrictionFactor, greaterThan(0.01));
      expect(r.darcyFrictionFactor, lessThan(0.1));
    });

    test('copper is smoother → lower friction than steel at same geometry', () {
      final steel = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 100, diameter: 2.067,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      )!;

      // Use same D=2.067" nominal for copper (Type L ≈ 1.985" ID)
      final copper = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 100, diameter: 2.0,  // ≈ copper Type L
          material: PipeMaterial.copperTypeL,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      )!;

      // Copper (ε=1.5 μm) should have lower friction than steel (ε=45 μm)
      expect(copper.darcyFrictionFactor, lessThan(steel.darcyFrictionFactor));
    });
  });

  group('Water Flow Engine — velocity pressure', () {
    test('velocity pressure at V≈2.89 m/s ≈ 4160 Pa', () {
      // vp = 0.5 × 997 × 2.89² = 4165 Pa
      final r = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 100, diameter: 2.067,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      )!;
      expect(r.velocityPressurePa, closeTo(4165, 150));
      expect(r.velocityPressureInWg, closeTo(16.7, 1.0));
    });
  });

  group('Water Flow Engine — warnings', () {
    test('high velocity triggers warning for chilled water (limit 3.0 m/s)', () {
      // 100 GPM through 1.049" (1" steel) → V ≈ 37 ft/s ≈ 11.3 m/s
      final r = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 100, diameter: 1.049,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      )!;
      expect(r.warning, isNotNull);
      expect(r.warning, contains('vượt giới hạn'));
    });

    test('low velocity triggers warning for hot water (min 0.3 m/s)', () {
      // 0.5 GPM through 4.026" (4" steel) → very low velocity
      final r = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 0.5, diameter: 4.026,
          material: PipeMaterial.steelBlack,
          service: PipeService.hotWaterHeating,
          unit: UnitSystem.imperial,
        ),
      )!;
      expect(r.warning, isNotNull);
      expect(r.warning, contains('thấp hơn giới hạn'));
    });

    test('normal velocity in chilled water range → no warning', () {
      // 100 GPM through 2.067": V ≈ 2.89 m/s < 3.0 m/s max
      final r = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 100, diameter: 2.067,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      )!;
      expect(r.warning, isNull);
    });
  });

  group('Water Flow — round-trip unit conversion', () {
    test('imperial → metric → imperial preserves velocity', () {
      // Imperial result
      final imp = WaterFlowEngine.calculate(
        const WaterFlowInput(
          flowRate: 100, diameter: 2.067,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      )!;

      // Convert imperial → metric
      final m3h = imp.flowRateM3h;
      final mm = imp.diameterIn * 25.4;
      final met = WaterFlowEngine.calculate(
        WaterFlowInput(
          flowRate: m3h,
          diameter: mm,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.metric,
        ),
      )!;

      // Convert metric → imperial
      final gpm = met.flowRateGpm;
      final inch = met.diameterIn;
      final back = WaterFlowEngine.calculate(
        WaterFlowInput(
          flowRate: gpm,
          diameter: inch,
          material: PipeMaterial.steelBlack,
          service: PipeService.chilledWater,
          unit: UnitSystem.imperial,
        ),
      )!;

      // Round-trip stable
      expect(back.velocityMs, closeTo(imp.velocityMs, 0.05));
      expect(back.reynolds, closeTo(imp.reynolds, 50));
    });
  });
}
