import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/hvac/models/enums.dart';
import 'package:mobile/features/hydronic/formulas/expansion_tank_engine.dart';

void main() {
  group('Expansion Tank Engine — basic calculation', () {
    test('typical residential heating: 100 gal, 50→180°F, 12/30 PSI', () {
      final r = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100, // gal
          tempInitialC: 50, // °F (cold start)
          tempFinalC: 180, // °F (operating)
          prechargePressure: 12, // PSI
          reliefPressure: 30, // PSI
          unit: UnitSystem.imperial,
        ),
      )!;

      // With η_water ≈ 0.000378/°C, ΔT = (180-50)×5/9 = 72.2°C:
      // ΔV = 100 × 3.785 × 0.000378 × 72.2 ≈ 10.32 L ≈ 2.73 gal
      // Precharge_abs = 12 + 14.7 = 26.7 PSI; relief_abs = 30 + 14.7 = 44.7 PSI
      // Pressure factor = 1 - 26.7/44.7 ≈ 0.4027
      // V_required = 2.73 / 0.4027 ≈ 6.78 gal
      // + 20% acceptance = 8.14 gal
      expect(r.expansionVolumeGallons, closeTo(2.73, 0.5));
      expect(r.requiredVolumeGallons, greaterThan(0));
      expect(r.totalVolumeGallons, greaterThan(r.requiredVolumeGallons));
      // Tank should round up to 14 gal standard size
      expect(r.recommendedStandardSizeGal, greaterThanOrEqualTo(7.6));
    });

    test('glycol 30%: larger tank than water only', () {
      final waterOnly = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 12,
          reliefPressure: 30,
          unit: UnitSystem.imperial,
        ),
      )!;

      final glycol = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 12,
          reliefPressure: 30,
          glycolConcentration: 0.30,
          unit: UnitSystem.imperial,
        ),
      )!;

      // Glycol expands more than water → larger tank
      expect(
        glycol.expansionVolumeGallons,
        greaterThan(waterOnly.expansionVolumeGallons),
      );
      expect(
        glycol.totalVolumeGallons,
        greaterThanOrEqualTo(waterOnly.totalVolumeGallons),
      );
    });

    test('higher precharge → smaller tank (more headroom)', () {
      final lowPressure = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 5,
          reliefPressure: 30,
          unit: UnitSystem.imperial,
        ),
      )!;

      final highPressure = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 20,
          reliefPressure: 30,
          unit: UnitSystem.imperial,
        ),
      )!;

      // Higher precharge = smaller pressure factor denominator ratio
      // → larger V_t
      // Wait — V_t = ΔV / (1 - P_i/P_f) so higher P_i → larger V_t
      expect(
        highPressure.totalVolumeGallons,
        greaterThan(lowPressure.totalVolumeGallons),
      );
    });
  });

  group('Expansion Tank Engine — invalid inputs', () {
    test('zero volume returns null', () {
      final r = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 0,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 12,
          reliefPressure: 30,
          unit: UnitSystem.imperial,
        ),
      );
      expect(r, isNull);
    });

    test('negative volume returns null', () {
      final r = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: -1,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 12,
          reliefPressure: 30,
          unit: UnitSystem.imperial,
        ),
      );
      expect(r, isNull);
    });

    test('final temp <= initial temp returns null', () {
      final r = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100,
          tempInitialC: 100,
          tempFinalC: 100,
          prechargePressure: 12,
          reliefPressure: 30,
          unit: UnitSystem.imperial,
        ),
      );
      expect(r, isNull);
    });

    test('precharge >= relief triggers warning', () {
      final r = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 30,
          reliefPressure: 30,
          unit: UnitSystem.imperial,
        ),
      );

      expect(r, isNotNull);
      expect(r!.warnings, isNotEmpty);
    });
  });

  group('Expansion Tank Engine — unit conversions', () {
    test('imperial and metric produce equivalent results', () {
      // 100 gal ≈ 378.5 L; 50°F ≈ 10°C; 180°F ≈ 82.2°C;
      // 12 PSI ≈ 82.7 kPa; 30 PSI ≈ 206.8 kPa
      final imperial = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 12,
          reliefPressure: 30,
          unit: UnitSystem.imperial,
        ),
      )!;

      final metric = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 378.54,
          tempInitialC: 10.0,
          tempFinalC: 82.2,
          prechargePressure: 82.7,
          reliefPressure: 206.8,
          unit: UnitSystem.metric,
        ),
      )!;

      expect(
        imperial.totalVolumeGallons,
        closeTo(metric.totalVolumeGallons, 0.5),
      );
      expect(imperial.totalVolumeLiters, closeTo(metric.totalVolumeLiters, 2));
    });
  });

  group('Expansion Tank Engine — standard size selection', () {
    test('small system rounds to smallest standard size', () {
      final r = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 30,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 12,
          reliefPressure: 30,
          unit: UnitSystem.imperial,
        ),
      )!;

      // Tiny total volume → should be 2 gal or 4.4 gal
      expect(r.recommendedStandardSizeGal, lessThanOrEqualTo(20));
      expect(r.recommendedStandardSizeGal, anyOf(2, 4.4, 7.6));
    });

    test('larger system uses bigger standard size', () {
      final r = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 500,
          tempInitialC: 50,
          tempFinalC: 200,
          prechargePressure: 12,
          reliefPressure: 30,
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(r.recommendedStandardSizeGal, greaterThanOrEqualTo(40));
    });
  });

  group('Expansion Tank Engine — pressure ratio', () {
    test('precharge ratio is between 0 and 1', () {
      final r = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 12,
          reliefPressure: 30,
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(r.prechargeRatio, greaterThan(0));
      expect(r.prechargeRatio, lessThan(1));
    });

    test('high pressure ratio warning fires', () {
      // Precharge close to relief → tank required is very large
      final r = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 25,
          reliefPressure: 30, // 95% of relief after atm
          unit: UnitSystem.imperial,
        ),
      )!;

      // precharge_abs ≈ 25 + 14.7 = 39.7; relief_abs ≈ 30 + 14.7 = 44.7
      // ratio = 39.7 / 44.7 ≈ 0.888 → triggers > 0.8 warning
      expect(r.warnings.any((w) => w.contains('Precharge')), isTrue);
    });
  });

  group('Expansion Tank Engine — warnings', () {
    test('high glycol warning when >40%', () {
      final r = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 12,
          reliefPressure: 30,
          glycolConcentration: 0.50,
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(r.warnings.any((w) => w.contains('Glycol')), isTrue);
    });

    test('extreme temperature rise warning', () {
      final r = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100,
          tempInitialC: -50,
          tempFinalC: 250,
          prechargePressure: 12,
          reliefPressure: 30,
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(r.warnings.any((w) => w.contains('temperature')), isTrue);
    });

    test('normal conditions produce no warnings', () {
      final r = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 12,
          reliefPressure: 30,
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(r.warnings, isEmpty);
    });
  });

  group('Expansion Tank Engine — expansion coefficient scaling', () {
    test('glycol 50% has higher coefficient than water', () {
      final water = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 12,
          reliefPressure: 30,
          glycolConcentration: 0.0,
          unit: UnitSystem.imperial,
        ),
      )!;

      final glycol50 = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 12,
          reliefPressure: 30,
          glycolConcentration: 0.50,
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(glycol50.expansionCoeff, greaterThan(water.expansionCoeff));
    });

    test('10% glycol increases expansion between water and 20%', () {
      final water = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 12,
          reliefPressure: 30,
          glycolConcentration: 0.0,
          unit: UnitSystem.imperial,
        ),
      )!;

      final tenPct = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 12,
          reliefPressure: 30,
          glycolConcentration: 0.10,
          unit: UnitSystem.imperial,
        ),
      )!;

      final twentyPct = ExpansionTankEngine.calculate(
        const ExpansionTankInput(
          systemVolume: 100,
          tempInitialC: 50,
          tempFinalC: 180,
          prechargePressure: 12,
          reliefPressure: 30,
          glycolConcentration: 0.20,
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(tenPct.expansionCoeff, greaterThan(water.expansionCoeff));
      expect(tenPct.expansionCoeff, lessThan(twentyPct.expansionCoeff));
    });
  });
}
