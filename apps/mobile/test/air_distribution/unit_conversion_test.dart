import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/hvac/models/enums.dart';
import 'package:mobile/features/air_distribution/constants/air_distribution_constants.dart';
import 'package:mobile/features/air_distribution/data/diffuser_catalog.dart';
import 'package:mobile/features/air_distribution/data/vav_box_catalog.dart';
import 'package:mobile/features/air_distribution/formulas/diffuser_selection_engine.dart';
import 'package:mobile/features/air_distribution/formulas/grille_selection_engine.dart';
import 'package:mobile/features/air_distribution/formulas/equal_friction_engine.dart';
import 'package:mobile/features/air_distribution/formulas/velocity_reduction_engine.dart';
import 'package:mobile/features/air_distribution/formulas/vav_box_engine.dart';

void main() {
  group('Diffuser Selection — unit conversion (Bug A.1)', () {
    test('roomVolumeFt3 works in metric mode (no zeros)', () {
      final input = DiffuserSelectionInput(
        totalCfm: 800,
        roomLengthFt: 7.32, // 24 ft → 7.32 m
        roomWidthFt: 4.88, // 16 ft → 4.88 m
        ceilingHeightFt: 2.74, // 9 ft → 2.74 m
        ach: 6,
        diffuserCount: 4,
        throwDistanceFt: 0,
        mountingHeightFt: 2.74,
        maxNeckVelocityFpm: 12.7, // 800 FPM → 4.06 m/s → ≈ 12.7
        maxNcRating: 35,
        diffuserType: DiffuserType.ceilingSquare,
        unit: UnitSystem.metric,
        method: DiffuserSizingMethod.byAch,
      );
      expect(input.roomVolumeFt3, greaterThan(0));
      expect(input.roomVolumeM3, closeTo(97.8, 0.5));
      // ft³ should be ~3456
      expect(input.roomVolumeFt3, closeTo(3456, 5));
    });

    test('byAch method computes totalCFM correctly in metric', () {
      // Room 24ft × 16ft × 9ft, ACH=6 → CFM = 3456 * 6 / 60 = 345.6
      final imperialResult = DiffuserSelectionEngine.calculate(
        DiffuserSelectionInput(
          totalCfm: 0,
          roomLengthFt: 24,
          roomWidthFt: 16,
          ceilingHeightFt: 9,
          ach: 6,
          diffuserCount: 4,
          throwDistanceFt: 0,
          mountingHeightFt: 9,
          maxNeckVelocityFpm: 800,
          maxNcRating: 35,
          diffuserType: DiffuserType.ceilingSquare,
          unit: UnitSystem.imperial,
          method: DiffuserSizingMethod.byAch,
        ),
      );
      expect(imperialResult, isNotNull);
      expect(imperialResult!.totalCfm, closeTo(345.6, 0.5));

      // Same room in metric
      final metricResult = DiffuserSelectionEngine.calculate(
        DiffuserSelectionInput(
          totalCfm: 0,
          roomLengthFt: 7.32,
          roomWidthFt: 4.88,
          ceilingHeightFt: 2.74,
          ach: 6,
          diffuserCount: 4,
          throwDistanceFt: 0,
          mountingHeightFt: 2.74,
          maxNeckVelocityFpm: 12.7,
          maxNcRating: 35,
          diffuserType: DiffuserType.ceilingSquare,
          unit: UnitSystem.metric,
          method: DiffuserSizingMethod.byAch,
        ),
      );
      expect(metricResult, isNotNull);
      expect(
        metricResult!.totalCfm,
        closeTo(345.6, 0.5),
        reason: 'Metric mode must produce same CFM as imperial',
      );
    });
  });

  group('Grille Selection — unit conversion (Bug A.2)', () {
    test('roomVolumeFt3 computes correctly in metric mode', () {
      final input = GrilleSelectionInput(
        totalCfm: 800,
        roomAreaSqFt: 35.7, // 384 sqft → 35.7 m²
        ceilingHeightFt: 2.74, // 9 ft → 2.74 m
        grilleCount: 2,
        grilleType: GrilleType.returnGrille,
        application: GrilleApplication.returnAir,
        unit: UnitSystem.metric,
        byRoomArea: true,
        ach: 6,
        maxFaceVelocityFpm: 1.524, // 300 FPM → 1.524 m/s
        maxNcRating: 30,
        mountingHeightFt: 2.74,
      );
      // vol = 35.7 × 2.74 ≈ 97.8 m³ → 3456 ft³
      expect(input.roomVolumeFt3, greaterThan(3000));
    });
  });

  group('Equal Friction — length metric conversion (Bug A.3)', () {
    test('totalFrictionLossInWg correct in metric mode', () {
      // 30 m duct at 0.10 in.wg/100ft = ~30 m → 98.4 ft
      // total loss = 0.10 * 98.4/100 = 0.0984 in.wg
      final result = EqualFrictionEngine.calculate(
        EqualFrictionInput(
          airflowCfm: 1000,
          frictionRateInWg100ft: 0.10,
          lengthFt: 30, // 30 m stored as lengthFt in metric
          ductType: DuctType.supplyMain,
          material: DuctMaterial.galvanized,
          shape: DuctShape.round,
          unit: UnitSystem.metric,
          maxVelocityFpm: 8.0, // 1600 FPM → 8.13 m/s
        ),
      );
      expect(result.totalFrictionLossInWg, closeTo(0.0984, 0.005));
    });
  });

  group('Velocity Reduction — length metric (Bug A.4)', () {
    test('friction loss per section correct in metric', () {
      // 10 m section, friction rate 0.10 in.wg/100ft → 32.8 ft → loss = 0.0328
      final result = VelocityReductionEngine.calculate(
        VelocityReductionInput(
          airflowCfm: 5000,
          initialVelocityFpm: 8.0,
          numberOfSections: 2,
          reductionRatio: 0.8,
          lengthFt: 10, // 10 m
          ductType: DuctType.supplyMain,
          material: DuctMaterial.galvanized,
          shape: DuctShape.round,
          unit: UnitSystem.metric,
          maxFrictionRateInWg100ft: 0.20,
        ),
      );
      expect(result, isNotNull);
      if (result != null) {
        // Each section loss should be roughly friction_rate * lengthFtActual / 100
        for (final s in result.sections) {
          // lengthFtActual for 10m = 32.8 ft
          // expected loss = fricRate * 32.8 / 100 = 0.328 * fricRate
          final expectedMin = s.frictionRateInWg100ft * 32.0 / 100.0;
          final expectedMax = s.frictionRateInWg100ft * 33.5 / 100.0;
          expect(s.frictionLossInWg, greaterThanOrEqualTo(expectedMin));
          expect(s.frictionLossInWg, lessThanOrEqualTo(expectedMax));
        }
      }
    });
  });

  group('VAV — cooling load metric conversion (Bug A.5)', () {
    test('cooling load in Watts produces reasonable CFM', () {
      // 5275 W = 18000 BTU/hr, ΔT 20°F = 11.1K
      // Expected CFM ≈ 18000 / (1.08 × 20) = 833 CFM
      final imperial = VavBoxSizingEngine.calculate(
        VavBoxSizingInput(
          coolingLoadBtuHr: 18000,
          heatingLoadBtuHr: 0,
          supplyAirTempF: 55,
          roomTempF: 75,
          roomTempFHeat: 70,
          minAirflowRatio: 0.30,
          primaryAirTempF: 55,
          boxType: VavBoxType.singleDuctCoolingOnly,
          unit: UnitSystem.imperial,
          method: SizingMethod.byCoolingLoad,
          directAirflowCfm: 0,
        ),
      );
      expect(imperial, isNotNull);
      expect(imperial!.coolingCfm, closeTo(833, 10));

      // Metric: 5275 W, room 24°C, SAT 13°C → ΔT = 11K
      // Correct psychrometric: m³/s = 5275 / (1206 × 11) = 0.3975 m³/s
      // CFM = 0.3975 × 2118.88 ≈ 842 CFM
      final metric = VavBoxSizingEngine.calculate(
        VavBoxSizingInput(
          coolingLoadBtuHr: 5275,
          heatingLoadBtuHr: 0,
          supplyAirTempF: 13,
          roomTempF: 24,
          roomTempFHeat: 21,
          minAirflowRatio: 0.30,
          primaryAirTempF: 13,
          boxType: VavBoxType.singleDuctCoolingOnly,
          unit: UnitSystem.metric,
          method: SizingMethod.byCoolingLoad,
          directAirflowCfm: 0,
        ),
      );
      expect(metric, isNotNull);
      // Should match the imperial case (when converted) within conversion tolerance
      // 5275 W ≈ 18000 Btu/hr → should give same CFM as imperial (833)
      // but actual is ~842 because 1 watt = 3.412 Btu/hr × not exactly equal to 3.413
      expect(metric!.coolingCfm, closeTo(833, 30));
    });
  });
}
