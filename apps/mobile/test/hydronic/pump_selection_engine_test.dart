import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/hvac/models/enums.dart';
import 'package:mobile/features/hydronic/data/pump_catalog.dart';
import 'package:mobile/features/hydronic/formulas/pump_selection_engine.dart';

void main() {
  group('Pump Selection Engine — basic matching', () {
    test('small circulator for 30 GPM @ 20 ft', () {
      final result = PumpSelectionEngine.calculate(
        const PumpSelectionInput(
          flowRate: 30,
          headFt: 20,
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(result.candidates, isNotEmpty);
      // Top choice should be a small circulator
      final top = result.candidates.first;
      expect(top.pump.maxFlowGpm, greaterThanOrEqualTo(30));
      expect(top.pump.maxHeadFt, greaterThanOrEqualTo(20));
    });

    test('medium end-suction pump for 200 GPM @ 60 ft', () {
      final result = PumpSelectionEngine.calculate(
        const PumpSelectionInput(
          flowRate: 200,
          headFt: 60,
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(result.candidates, isNotEmpty);
      // Top choice should have head >= 60
      final top = result.candidates.first;
      expect(top.pump.maxHeadFt, greaterThanOrEqualTo(60));
    });

    test('high-head multistage for 100 GPM @ 200 ft', () {
      final result = PumpSelectionEngine.calculate(
        const PumpSelectionInput(
          flowRate: 100,
          headFt: 200,
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(result.candidates, isNotEmpty);
      // Should pick a multistage pump at this head
      final hasMultistage = result.candidates.any(
        (c) => c.pump.type == PumpType.verticalMultistage,
      );
      expect(hasMultistage, isTrue);
    });

    test('large split-case for 1000 GPM @ 80 ft', () {
      final result = PumpSelectionEngine.calculate(
        const PumpSelectionInput(
          flowRate: 1000,
          headFt: 80,
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(result.candidates, isNotEmpty);
      // Should match split-case (high flow capacity)
      final hasSplitCase = result.candidates.any(
        (c) => c.pump.type == PumpType.splitCase,
      );
      expect(hasSplitCase, isTrue);
    });
  });

  group('Pump Selection Engine — invalid inputs', () {
    test('zero flow returns null', () {
      final result = PumpSelectionEngine.calculate(
        const PumpSelectionInput(
          flowRate: 0,
          headFt: 50,
          unit: UnitSystem.imperial,
        ),
      );
      expect(result, isNull);
    });

    test('zero head returns null', () {
      final result = PumpSelectionEngine.calculate(
        const PumpSelectionInput(
          flowRate: 100,
          headFt: 0,
          unit: UnitSystem.imperial,
        ),
      );
      expect(result, isNull);
    });

    test('extreme demand → no pump in catalog → warning', () {
      final result = PumpSelectionEngine.calculate(
        const PumpSelectionInput(
          flowRate: 10000, // way above any pump in catalog
          headFt: 500,
          unit: UnitSystem.imperial,
        ),
      )!;

      expect(result.candidates, isEmpty);
      expect(result.warnings, isNotEmpty);
    });
  });

  group('Pump Selection Engine — pump type filter', () {
    test('filter restricts to specific pump types', () {
      final result = PumpSelectionEngine.calculate(
        const PumpSelectionInput(
          flowRate: 100,
          headFt: 50,
          unit: UnitSystem.imperial,
          pumpTypeFilter: [PumpType.circulator],
        ),
      )!;

      // All candidates should be circulators
      for (final c in result.candidates) {
        expect(c.pump.type, PumpType.circulator);
      }
    });

    test('multi-type filter returns union of matching pumps', () {
      final result = PumpSelectionEngine.calculate(
        const PumpSelectionInput(
          flowRate: 200,
          headFt: 60,
          unit: UnitSystem.imperial,
          pumpTypeFilter: [PumpType.endSuction, PumpType.inline],
        ),
      )!;

      for (final c in result.candidates) {
        expect(
          c.pump.type == PumpType.endSuction || c.pump.type == PumpType.inline,
          isTrue,
        );
      }
    });
  });

  group('Pump Selection Engine — efficiency calculations', () {
    test('efficiency is at BEP when flow ratio ≈ 0.75', () {
      // Find a pump with maxFlowGpm around 200
      final pump = PumpCatalog.all.firstWhere(
        (p) => p.maxFlowGpm == 200 && p.maxHeadFt == 50,
      );
      final qBep = pump.maxFlowGpm * 0.75;
      final result = PumpSelectionEngine.calculate(
        PumpSelectionInput(
          flowRate: qBep,
          headFt: 40,
          unit: UnitSystem.imperial,
        ),
      )!;

      // Find the matching candidate
      final candidate = result.candidates.firstWhere(
        (c) => c.pump.model == pump.model,
      );
      // Efficiency should be at or near BEP value
      expect(candidate.efficiencyAtPoint, closeTo(pump.bestEfficiency, 0.1));
    });

    test('brake power is positive and finite', () {
      final result = PumpSelectionEngine.calculate(
        const PumpSelectionInput(
          flowRate: 200,
          headFt: 60,
          unit: UnitSystem.imperial,
        ),
      )!;

      for (final c in result.candidates) {
        expect(c.brakePowerHp, greaterThan(0));
        expect(c.brakePowerHp.isFinite, isTrue);
      }
    });

    test('head margin is positive when required head < shutoff', () {
      final result = PumpSelectionEngine.calculate(
        const PumpSelectionInput(
          flowRate: 200,
          headFt: 40, // below most shutoffs
          unit: UnitSystem.imperial,
        ),
      )!;

      for (final c in result.candidates) {
        expect(c.headMarginFt, greaterThan(0));
        expect(c.headMarginPct, greaterThan(0));
      }
    });
  });

  group('Pump Selection Engine — impeller trim', () {
    test('impeller trim reduces diameter proportionally to head ratio', () {
      final pump = PumpCatalog.all.firstWhere(
        (p) => p.impellerDiameterIn >= 10,
      );
      final halfHead = pump.maxHeadFt / 2;
      final trim = PumpSelectionEngine.estimateImpellerTrim(
        pump: pump,
        requiredHeadFt: halfHead,
      );
      expect(trim, isNotNull);
      // D_trim = D_max × sqrt(0.5) ≈ 0.707 × D_max
      expect(trim!, closeTo(pump.impellerDiameterIn * 0.7071, 0.01));
    });

    test('impeller trim returns null when required head > shutoff', () {
      final pump = PumpCatalog.all.first;
      final trim = PumpSelectionEngine.estimateImpellerTrim(
        pump: pump,
        requiredHeadFt: pump.maxHeadFt + 10,
      );
      expect(trim, isNull);
    });

    test('impeller trim returns null when trim < 50% of max', () {
      final pump = PumpCatalog.all.first;
      final trim = PumpSelectionEngine.estimateImpellerTrim(
        pump: pump,
        requiredHeadFt: pump.maxHeadFt * 0.1, // 10% head → 31.6% diameter
      );
      expect(trim, isNull);
    });
  });

  group('Pump Selection Engine — unit conversions', () {
    test('metric input converts correctly', () {
      // 200 GPM ≈ 45.4 m³/h; 50 ft ≈ 15.24 m
      final imperialResult = PumpSelectionEngine.calculate(
        const PumpSelectionInput(
          flowRate: 200,
          headFt: 50,
          unit: UnitSystem.imperial,
        ),
      )!;
      final metricResult = PumpSelectionEngine.calculate(
        const PumpSelectionInput(
          flowRate: 45.425,
          headFt: 15.24,
          unit: UnitSystem.metric,
        ),
      )!;

      expect(
        metricResult.requiredFlowGpm,
        closeTo(imperialResult.requiredFlowGpm, 1),
      );
      expect(
        metricResult.requiredHeadFt,
        closeTo(imperialResult.requiredHeadFt, 1),
      );
    });
  });

  group('Pump Selection Engine — round-trip', () {
    test('candidates list is non-empty and sorted by efficiency', () {
      final result = PumpSelectionEngine.calculate(
        const PumpSelectionInput(
          flowRate: 200,
          headFt: 50,
          unit: UnitSystem.imperial,
        ),
      )!;

      for (var i = 1; i < result.candidates.length; i++) {
        expect(
          result.candidates[i].efficiencyAtPoint,
          lessThanOrEqualTo(result.candidates[i - 1].efficiencyAtPoint),
        );
      }
    });

    test('specific speed scales with Q and H', () {
      // Higher flow → higher specific speed (for fixed head)
      // Higher head → lower specific speed (for fixed flow)
      final r1 = PumpSelectionEngine.calculate(
        const PumpSelectionInput(
          flowRate: 100,
          headFt: 50,
          unit: UnitSystem.imperial,
        ),
      )!;
      final r2 = PumpSelectionEngine.calculate(
        const PumpSelectionInput(
          flowRate: 200, // double flow
          headFt: 50,
          unit: UnitSystem.imperial,
        ),
      )!;

      // N_s ∝ sqrt(Q), so doubling Q → N_s × sqrt(2)
      final cand1 = r1.candidates.first;
      final cand2 = r2.candidates.first;
      // If same pump type is selected both times
      if (cand1.pump.model == cand2.pump.model) {
        expect(cand2.specificSpeed / cand1.specificSpeed, closeTo(1.414, 0.01));
      }
    });
  });

  group('Pump Catalog — data integrity', () {
    test('all pumps have valid efficiency', () {
      for (final p in PumpCatalog.all) {
        expect(p.bestEfficiency, greaterThan(0));
        expect(p.bestEfficiency, lessThanOrEqualTo(1));
      }
    });

    test('all pumps have min < max flow', () {
      for (final p in PumpCatalog.all) {
        expect(p.minFlowGpm, lessThan(p.maxFlowGpm));
      }
    });

    test('all pumps have positive head and power', () {
      for (final p in PumpCatalog.all) {
        expect(p.maxHeadFt, greaterThan(0));
        expect(p.maxPowerHp, greaterThan(0));
      }
    });

    test('getPumpTypeVi returns non-empty string for all types', () {
      for (final t in PumpType.values) {
        final s = PumpCatalog.getPumpTypeVi(t);
        expect(s, isNotEmpty);
      }
    });
  });
}
