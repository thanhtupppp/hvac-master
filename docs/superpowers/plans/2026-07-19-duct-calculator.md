# Duct Calculator Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign and re-architect the Duct Calculator module in the mobile Flutter app using service-driven architecture, implementing Velocity and Equal Friction methods, ranking algorithms, standard sizing configs, and a premium dashboard UI.

**Architecture:** Clean Architecture pattern: Presentation (Dashboard UI) ↔ State (Riverpod Notifier with Debounce) ↔ Domain/Service (Stateless coordinator/converter) ↔ Engine (Pure Dart HVAC mathematical formulas & weight-based ranker).

**Tech Stack:** Dart, Flutter, Flutter Riverpod, google_fonts, shared_preferences, local_auth, flutter_secure_storage.

## Global Constraints
- Engine must remain 100% pure Dart, zero dependencies on Flutter or Riverpod.
- Engine only calculates in Imperial units internally; unit conversions happen at the Service layer.
- Strictly follow compile-safe, standard Dart classes without code generation (no `freezed` or `build_runner`).
- Ensure all tests pass: `flutter test` in `apps/mobile` must execute cleanly without warnings or errors.

---

### Task 1: Domain Models & Base Formulas (Engine Part 1)

**Files:**
- Create: `apps/mobile/lib/services/duct/models/enums.dart`
- Create: `apps/mobile/lib/services/duct/models/duct_warning.dart`
- Create: `apps/mobile/lib/services/duct/models/duct_input.dart`
- Create: `apps/mobile/lib/services/duct/models/round_result.dart`
- Create: `apps/mobile/lib/services/duct/models/rectangle_option.dart`
- Create: `apps/mobile/lib/services/duct/models/calculation_metadata.dart`
- Create: `apps/mobile/lib/services/duct/models/duct_result.dart`
- Create: `apps/mobile/lib/services/duct/engine/formulas.dart`
- Create: `apps/mobile/test/duct/formulas_test.dart`

**Interfaces:**
- Produces: `CalculationMethod`, `UnitSystem`, `DuctType`, `CalculationStatus`, `WarningType`, `WarningSeverity`, `DuctWarning`, `DuctInput`, `RoundResult`, `RectangleOption`, `CalculationMetadata`, `DuctResult`, `HvacFormulas`.

- [ ] **Step 1: Create the models and enums**
  Write code in `apps/mobile/lib/services/duct/models/enums.dart`:
  ```dart
  enum CalculationMethod { velocity, equalFriction }
  enum UnitSystem { imperial, metric }
  enum DuctType { supplyMain, supplyBranch, returnMain, exhaust, custom }
  enum CalculationStatus { idle, calculating, success, error }
  enum WarningType { highVelocity, lowVelocity, highAspectRatio, invalidInput, frictionOutOfRange }
  enum WarningSeverity { info, warning, danger }
  ```

  Write code in `apps/mobile/lib/services/duct/models/duct_warning.dart`:
  ```dart
  import 'enums.dart';
  class DuctWarning {
    final WarningType type;
    final String message;
    final WarningSeverity severity;
    const DuctWarning({required this.type, required this.message, required this.severity});
  }
  ```

  Write code in `apps/mobile/lib/services/duct/models/duct_input.dart`:
  ```dart
  import 'enums.dart';
  class DuctInput {
    final double flowRate;
    final double targetVelocity;
    final double frictionRate;
    final CalculationMethod method;
    final UnitSystem unitSystem;
    final DuctType ductType;

    const DuctInput({
      required this.flowRate,
      required this.targetVelocity,
      required this.frictionRate,
      required this.method,
      required this.unitSystem,
      required this.ductType,
    });

    bool get isValid {
      if (flowRate <= 0) return false;
      if (method == CalculationMethod.velocity && targetVelocity <= 0) return false;
      if (method == CalculationMethod.equalFriction && frictionRate <= 0) return false;
      return true;
    }
  }
  ```

  Write code in `apps/mobile/lib/services/duct/models/round_result.dart`:
  ```dart
  class RoundResult {
    final double calculatedDiameter;
    final double standardDiameter;
    final double velocity;
    final double frictionRate;
    final double area;

    const RoundResult({
      required this.calculatedDiameter,
      required this.standardDiameter,
      required this.velocity,
      required this.frictionRate,
      required this.area,
    });
  }
  ```

  Write code in `apps/mobile/lib/services/duct/models/rectangle_option.dart`:
  ```dart
  class RectangleOption {
    final double width;
    final double height;
    final double area;
    final double velocity;
    final double equivalentDiameter;
    final double aspectRatio;
    final double score;
    final int stars;
    final bool preferred;
    final double velocityError;
    final double equivalentDiameterError;

    const RectangleOption({
      required this.width,
      required this.height,
      required this.area,
      required this.velocity,
      required this.equivalentDiameter,
      required this.aspectRatio,
      required this.score,
      required this.stars,
      required this.preferred,
      required this.velocityError,
      required this.equivalentDiameterError,
    });
  }
  ```

  Write code in `apps/mobile/lib/services/duct/models/calculation_metadata.dart`:
  ```dart
  class CalculationMetadata {
    final DateTime timestamp;
    final String algorithmVersion;
    final String standard;

    const CalculationMetadata({
      required this.timestamp,
      required this.algorithmVersion,
      required this.standard,
    });
  }
  ```

  Write code in `apps/mobile/lib/services/duct/models/duct_result.dart`:
  ```dart
  import 'round_result.dart';
  import 'rectangle_option.dart';
  import 'duct_warning.dart';
  import 'calculation_metadata.dart';

  class DuctResult {
    final RoundResult roundDuct;
    final List<RectangleOption> rectangleOptions;
    final List<DuctWarning> warnings;
    final CalculationMetadata metadata;

    const DuctResult({
      required this.roundDuct,
      required this.rectangleOptions,
      required this.warnings,
      required this.metadata,
    });
  }
  ```

- [ ] **Step 2: Write failing unit test for formulas**
  Write code in `apps/mobile/test/duct/formulas_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:mobile/services/duct/engine/formulas.dart';

  void main() {
    test('HvacFormulas velocity calculation matches formula', () {
      final v = HvacFormulas.velocity(cfm: 1000, areaSqFt: 2.0);
      expect(v, 500.0);
    });

    test('HvacFormulas round diameter matches approximation', () {
      final d = HvacFormulas.roundDuctDiameter(cfm: 1000, frictionRateInWgPer100ft: 0.1);
      expect(d, closeTo(13.62, 0.1));
    });
  }
  ```

- [ ] **Step 3: Run formulas test and verify failure**
  Run: `flutter test test/duct/formulas_test.dart`
  Expected: Compile failure (Missing formulas.dart)

- [ ] **Step 4: Implement formulas in engine**
  Write code in `apps/mobile/lib/services/duct/engine/formulas.dart`:
  ```dart
  import 'dart:math';

  class HvacFormulas {
    static double velocity({required double cfm, required double areaSqFt}) {
      assert(areaSqFt > 0, 'Area must be positive');
      return cfm / areaSqFt;
    }

    static double equivalentDiameter({required double a, required double b}) {
      if (a <= 0 || b <= 0) return 0.0;
      return 1.30 * pow(a * b, 0.625) / pow(a + b, 0.25);
    }

    static double roundDuctDiameter({
      required double cfm,
      required double frictionRateInWgPer100ft,
    }) {
      if (cfm <= 0 || frictionRateInWgPer100ft <= 0) return 0.0;
      return 2.42 * pow(cfm, 0.375) / pow(frictionRateInWgPer100ft, 0.1875);
    }
  }
  ```

- [ ] **Step 5: Run tests and verify success**
  Run: `flutter test test/duct/formulas_test.dart`
  Expected: PASS

- [ ] **Step 6: Commit**
  Run:
  ```bash
  git add apps/mobile/lib/services/duct/models/ apps/mobile/lib/services/duct/engine/formulas.dart apps/mobile/test/duct/formulas_test.dart
  git commit -m "feat: implement HVAC domain data models and core physical formulas"
  ```

---

### Task 2: Standard Sizes & Rectangular Generator/Ranker (Engine Part 2)

**Files:**
- Create: `apps/mobile/lib/services/duct/engine/standard_sizes.dart`
- Create: `apps/mobile/lib/services/duct/engine/preferred_rect_sizes.dart`
- Create: `apps/mobile/lib/services/duct/engine/velocity_table.dart`
- Create: `apps/mobile/lib/services/duct/engine/rectangle_generator.dart`
- Create: `apps/mobile/lib/services/duct/engine/rectangle_ranker.dart`
- Create: `apps/mobile/test/duct/ranker_test.dart`

**Interfaces:**
- Consumes: `DuctInput`, `RectangleOption`, `HvacFormulas`, `CalculationMethod`.
- Produces: `StandardSizes`, `PreferredRectSizes`, `VelocityTable`, `RectangleGenerator`, `RectangleRanker`.

- [ ] **Step 1: Implement size lists and config data**
  Write code in `apps/mobile/lib/services/duct/engine/standard_sizes.dart`:
  ```dart
  class StandardSizes {
    static const List<double> imperialRound = [4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 16, 18, 20, 22, 24];
    static const List<double> imperialRect = [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 40, 42, 48, 54, 60];
    static const List<double> metricRound = [100, 125, 150, 175, 200, 225, 250, 300, 350, 400, 450, 500, 600, 700, 800];
    static const List<double> metricRect = [100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500];

    static double findNearestStandardRound(double rawDiameter, List<double> standardList) {
      if (standardList.isEmpty) return rawDiameter;
      return standardList.reduce((a, b) => (a - rawDiameter).abs() < (b - rawDiameter).abs() ? a : b);
    }
  }
  ```

  Write code in `apps/mobile/lib/services/duct/engine/preferred_rect_sizes.dart`:
  ```dart
  import 'dart:math';

  class PreferredRectSizes {
    static const List<Point<double>> preferredImperial = [
      Point(12, 8), Point(14, 7), Point(16, 8), Point(16, 10),
      Point(18, 8), Point(18, 10), Point(20, 10), Point(20, 12),
      Point(24, 12), Point(24, 14), Point(24, 16)
    ];

    static const List<Point<double>> preferredMetric = [
      Point(300, 200), Point(400, 200), Point(500, 250), Point(600, 300),
      Point(600, 400), Point(800, 400), Point(1000, 500)
    ];

    static bool contains(double width, double height, bool isMetric) {
      final list = isMetric ? preferredMetric : preferredImperial;
      for (final p in list) {
        if ((p.x == width && p.y == height) || (p.x == height && p.y == width)) {
          return true;
        }
      }
      return false;
    }
  }
  ```

  Write code in `apps/mobile/lib/services/duct/engine/velocity_table.dart`:
  ```dart
  import '../models/enums.dart';

  class VelocityTable {
    static double getRecommendedVelocityFpm(DuctType type) {
      switch (type) {
        case DuctType.supplyMain:
          return 900.0;
        case DuctType.supplyBranch:
          return 600.0;
        case DuctType.returnMain:
          return 700.0;
        case DuctType.exhaust:
          return 800.0;
        case DuctType.custom:
          return 800.0;
      }
    }
  }
  ```

- [ ] **Step 2: Write failing unit test for Ranker**
  Write code in `apps/mobile/test/duct/ranker_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:mobile/services/duct/engine/rectangle_ranker.dart';
  import 'package:mobile/services/duct/models/rectangle_option.dart';
  import 'package:mobile/services/duct/models/duct_input.dart';
  import 'package:mobile/services/duct/models/enums.dart';

  void main() {
    test('RectangleRanker score returns 100 for perfect match', () {
      const option = RectangleOption(
        width: 12, height: 8, area: 96, velocity: 800,
        equivalentDiameter: 10.2, aspectRatio: 1.5,
        score: 0, stars: 0, preferred: true,
        velocityError: 0, equivalentDiameterError: 0
      );
      const input = DuctInput(
        flowRate: 1000, targetVelocity: 800, frictionRate: 0.1,
        method: CalculationMethod.velocity, unitSystem: UnitSystem.imperial,
        ductType: DuctType.supplyMain
      );
      final s = RectangleRanker.score(
        option: option, input: input,
        targetVelocityFpm: 800, targetEquivDiamIn: 10.2
      );
      expect(s, closeTo(100.0, 5.0));
    });
  }
  ```

- [ ] **Step 3: Run ranker test and verify failure**
  Run: `flutter test test/duct/ranker_test.dart`
  Expected: Compile failure

- [ ] **Step 4: Implement generator and ranker in engine**
  Write code in `apps/mobile/lib/services/duct/engine/rectangle_generator.dart`:
  ```dart
  import '../models/enums.dart';
  import '../models/rectangle_option.dart';
  import '../models/duct_input.dart';
  import 'standard_sizes.dart';
  import 'preferred_rect_sizes.dart';
  import 'formulas.dart';
  import 'rectangle_ranker.dart';

  class RectangleGenerator {
    static List<RectangleOption> generateOptions({
      required double targetAreaInSqIn,
      required double targetDiameterIn,
      required double targetVelocityFpm,
      required double flowRateCfm,
      required DuctInput input,
    }) {
      final List<RectangleOption> options = [];
      final list = StandardSizes.imperialRect;

      for (int i = 0; i < list.length; i++) {
        final w = list[i];
        for (int j = 0; j < list.length; j++) {
          final h = list[j];
          if (w < h) continue; // Keep width >= height

          final area = w * h;
          final ar = w / h;
          if (ar > 4.0) continue; // Hard filter on Aspect Ratio

          final velocity = flowRateCfm / (area / 144.0);
          final de = HvacFormulas.equivalentDiameter(a: w, b: h);

          final velErr = (velocity - targetVelocityFpm).abs() / targetVelocityFpm;
          final deErr = (de - targetDiameterIn).abs() / targetDiameterIn;

          final preferred = PreferredRectSizes.contains(w, h, false);

          final mockOption = RectangleOption(
            width: w, height: h, area: area, velocity: velocity,
            equivalentDiameter: de, aspectRatio: ar,
            score: 0, stars: 0, preferred: preferred,
            velocityError: velErr, equivalentDiameterError: deErr
          );

          final finalScore = RectangleRanker.score(
            option: mockOption, input: input,
            targetVelocityFpm: targetVelocityFpm, targetEquivDiamIn: targetDiameterIn
          );

          options.add(RectangleOption(
            width: w, height: h, area: area, velocity: velocity,
            equivalentDiameter: de, aspectRatio: ar,
            score: finalScore, stars: RectangleRanker.toStars(finalScore),
            preferred: preferred, velocityError: velErr, equivalentDiameterError: deErr
          ));
        }
      }

      options.sort((a, b) => b.score.compareTo(a.score));
      return options;
    }
  }
  ```

  Write code in `apps/mobile/lib/services/duct/engine/rectangle_ranker.dart`:
  ```dart
  import '../models/rectangle_option.dart';
  import '../models/duct_input.dart';
  import 'preferred_rect_sizes.dart';

  class RectangleRanker {
    static const _wVelocity = 0.40;
    static const _wAspect = 0.30;
    static const _wEquivDiam = 0.20;
    static const _wPreferred = 0.10;

    static double score({
      required RectangleOption option,
      required DuctInput input,
      required double targetVelocityFpm,
      required double targetEquivDiamIn,
    }) {
      // 1. Velocity Error
      final velScore = (1.0 - option.velocityError.clamp(0.0, 1.0)) * 100.0;

      // 2. Aspect Ratio Penalty
      final ar = option.aspectRatio;
      double arScore = 0.0;
      if (ar <= 1.5) {
        arScore = 100.0;
      } else if (ar <= 4.0) {
        arScore = 100.0 - ((ar - 1.5) / 2.5) * 60.0;
      }

      // 3. Equivalent Diameter Error
      final deScore = (1.0 - option.equivalentDiameterError.clamp(0.0, 1.0)) * 100.0;

      // 4. Preferred Size Bonus
      final preferredBonus = PreferredRectSizes.contains(option.width, option.height, false) ? 10.0 : 0.0;

      final raw = velScore * _wVelocity + arScore * _wAspect + deScore * _wEquivDiam;
      return (raw + preferredBonus).clamp(0.0, 100.0);
    }

    static int toStars(double score) {
      if (score >= 90) return 5;
      if (score >= 80) return 4;
      if (score >= 70) return 3;
      if (score >= 60) return 2;
      return 1;
    }
  }
  ```

- [ ] **Step 5: Run tests and verify success**
  Run: `flutter test test/duct/ranker_test.dart`
  Expected: PASS

- [ ] **Step 6: Commit**
  Run:
  ```bash
  git add apps/mobile/lib/services/duct/engine/ apps/mobile/test/duct/ranker_test.dart
  git commit -m "feat: implement size lists, standard configs, option generator and scoring ranker"
  ```

---

### Task 3: Unit Converter & Core Engine Integrator

**Files:**
- Create: `apps/mobile/lib/services/duct/engine/unit_converter.dart`
- Create: `apps/mobile/lib/services/duct/engine/duct_engine.dart`
- Create: `apps/mobile/test/duct/engine_test.dart`

**Interfaces:**
- Consumes: `DuctInput`, `DuctResult`, `RectangleGenerator`, `StandardSizes`, `HvacFormulas`.
- Produces: `UnitConverter`, `DuctEngine`.

- [ ] **Step 1: Write unit converter**
  Write code in `apps/mobile/lib/services/duct/engine/unit_converter.dart`:
  ```dart
  import '../models/enums.dart';
  import '../models/duct_input.dart';
  import '../models/duct_result.dart';
  import '../models/round_result.dart';
  import '../models/rectangle_option.dart';
  import '../models/calculation_metadata.dart';

  class UnitConverter {
    // Flow Rate: 1 m³/h = 0.5886 CFM, 1 L/s = 2.1189 CFM
    static double toCfm(double flowRate, UnitSystem unit) {
      if (unit == UnitSystem.imperial) return flowRate;
      return flowRate * 0.5886; // assuming m3/h for metric
    }

    static double fromCfm(double cfm, UnitSystem unit) {
      if (unit == UnitSystem.imperial) return cfm;
      return cfm / 0.5886;
    }

    // Velocity: 1 m/s = 196.85 fpm
    static double toFpm(double ms, UnitSystem unit) {
      if (unit == UnitSystem.imperial) return ms;
      return ms * 196.85;
    }

    static double fromFpm(double fpm, UnitSystem unit) {
      if (unit == UnitSystem.imperial) return fpm;
      return fpm / 196.85;
    }

    // Length: 1 mm = 0.03937 inches
    static double toInches(double mm, UnitSystem unit) {
      if (unit == UnitSystem.imperial) return mm;
      return mm * 0.03937;
    }

    static double fromInches(double inches, UnitSystem unit) {
      if (unit == UnitSystem.imperial) return inches;
      return inches / 0.03937;
    }

    // Friction: 1 Pa/m = 0.1225 in.wg/100ft
    static double toInWg(double pa, UnitSystem unit) {
      if (unit == UnitSystem.imperial) return pa;
      return pa * 0.1225;
    }

    static double fromInWg(double inWg, UnitSystem unit) {
      if (unit == UnitSystem.imperial) return inWg;
      return inWg / 0.1225;
    }

    static DuctInput toImperial(DuctInput input) {
      if (input.unitSystem == UnitSystem.imperial) return input;
      return DuctInput(
        flowRate: toCfm(input.flowRate, UnitSystem.metric),
        targetVelocity: toFpm(input.targetVelocity, UnitSystem.metric),
        frictionRate: toInWg(input.frictionRate, UnitSystem.metric),
        method: input.method,
        unitSystem: UnitSystem.imperial,
        ductType: input.ductType,
      );
    }

    static DuctResult resultToMetric(DuctResult imperialResult) {
      final round = imperialResult.roundDuct;
      final convertedRound = RoundResult(
        calculatedDiameter: fromInches(round.calculatedDiameter, UnitSystem.metric),
        standardDiameter: fromInches(round.standardDiameter, UnitSystem.metric),
        velocity: fromFpm(round.velocity, UnitSystem.metric),
        frictionRate: fromInWg(round.frictionRate, UnitSystem.metric),
        area: round.area * 645.16, // in² to mm²
      );

      final convertedOptions = imperialResult.rectangleOptions.map((opt) {
        return RectangleOption(
          width: fromInches(opt.width, UnitSystem.metric),
          height: fromInches(opt.height, UnitSystem.metric),
          area: opt.area * 645.16,
          velocity: fromFpm(opt.velocity, UnitSystem.metric),
          equivalentDiameter: fromInches(opt.equivalentDiameter, UnitSystem.metric),
          aspectRatio: opt.aspectRatio,
          score: opt.score,
          stars: opt.stars,
          preferred: opt.preferred,
          velocityError: opt.velocityError,
          equivalentDiameterError: opt.equivalentDiameterError,
        );
      }).toList();

      return DuctResult(
        roundDuct: convertedRound,
        rectangleOptions: convertedOptions,
        warnings: imperialResult.warnings,
        metadata: imperialResult.metadata,
      );
    }
  }
  ```

- [ ] **Step 2: Write failing unit test for Engine**
  Write code in `apps/mobile/test/duct/engine_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:mobile/services/duct/engine/duct_engine.dart';
  import 'package:mobile/services/duct/models/duct_input.dart';
  import 'package:mobile/services/duct/models/enums.dart';

  void main() {
    test('DuctEngine calculates correctly for Velocity Method', () {
      const input = DuctInput(
        flowRate: 1000, targetVelocity: 800, frictionRate: 0.1,
        method: CalculationMethod.velocity, unitSystem: UnitSystem.imperial,
        ductType: DuctType.supplyMain
      );
      final res = DuctEngine.calculate(input);
      expect(res.roundDuct.calculatedDiameter, greaterThan(0));
      expect(res.rectangleOptions.isNotEmpty, isTrue);
    });
  }
  ```

- [ ] **Step 3: Run engine test and verify failure**
  Run: `flutter test test/duct/engine_test.dart`
  Expected: Compile failure

- [ ] **Step 4: Implement DuctEngine**
  Write code in `apps/mobile/lib/services/duct/engine/duct_engine.dart`:
  ```dart
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

      final stdRoundDiam = StandardSizes.findNearestStandardRound(calculatedDiameter, StandardSizes.imperialRound);
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
  ```

- [ ] **Step 5: Run tests and verify success**
  Run: `flutter test test/duct/engine_test.dart`
  Expected: PASS

- [ ] **Step 6: Commit**
  Run:
  ```bash
  git add apps/mobile/lib/services/duct/engine/duct_engine.dart apps/mobile/lib/services/duct/engine/unit_converter.dart apps/mobile/test/duct/engine_test.dart
  git commit -m "feat: implement unit converter and core duct engine layout"
  ```

---

### Task 4: Service & State Layer (DuctCalculatorService & Riverpod Notifier)

**Files:**
- Create: `apps/mobile/lib/services/duct/services/duct_calculator_service.dart`
- Create: `apps/mobile/lib/services/duct/models/duct_calculator_state.dart`
- Create: `apps/mobile/lib/services/duct/providers/duct_calculator_notifier.dart`
- Create: `apps/mobile/test/duct/service_test.dart`

**Interfaces:**
- Consumes: `DuctInput`, `DuctResult`, `DuctEngine`, `UnitConverter`, `CalculationStatus`.
- Produces: `DuctCalculatorService`, `DuctCalculatorState`, `DuctCalculatorNotifier`, `ductCalculatorServiceProvider`, `ductCalculatorProvider`.

- [ ] **Step 1: Write DuctCalculatorService**
  Write code in `apps/mobile/lib/services/duct/services/duct_calculator_service.dart`:
  ```dart
  import '../models/duct_input.dart';
  import '../models/duct_result.dart';
  import '../models/enums.dart';
  import '../engine/duct_engine.dart';
  import '../engine/unit_converter.dart';

  class DuctCalculatorService {
    DuctResult calculate(DuctInput input) {
      if (!input.isValid) {
        throw ArgumentError('DuctInput is invalid.');
      }
      
      // 1. Convert to Imperial
      final imperialInput = UnitConverter.toImperial(input);

      // 2. Compute via Engine
      final imperialResult = DuctEngine.calculate(imperialInput);

      // 3. Convert back to Metric if input was Metric
      if (input.unitSystem == UnitSystem.metric) {
        return UnitConverter.resultToMetric(imperialResult);
      }
      return imperialResult;
    }
  }
  ```

- [ ] **Step 2: Write failing unit test for Service**
  Write code in `apps/mobile/test/duct/service_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:mobile/services/duct/services/duct_calculator_service.dart';
  import 'package:mobile/services/duct/models/duct_input.dart';
  import 'package:mobile/services/duct/models/enums.dart';

  void main() {
    test('DuctCalculatorService performs conversion and returns result', () {
      final service = DuctCalculatorService();
      const input = DuctInput(
        flowRate: 1700, targetVelocity: 4.5, frictionRate: 0.8,
        method: CalculationMethod.velocity, unitSystem: UnitSystem.metric,
        ductType: DuctType.supplyMain
      );
      final res = service.calculate(input);
      expect(res.roundDuct.calculatedDiameter, closeTo(250.0, 30.0)); // around 239mm
    });
  }
  ```

- [ ] **Step 3: Run service test and verify failure**
  Run: `flutter test test/duct/service_test.dart`
  Expected: Compile failure (Missing provider definitions/imports)

- [ ] **Step 4: Implement state, notifier, and providers**
  Write code in `apps/mobile/lib/services/duct/models/duct_calculator_state.dart`:
  ```dart
  import 'enums.dart';
  import 'duct_input.dart';
  import 'duct_result.dart';

  class DuctCalculatorState {
    final DuctInput input;
    final DuctResult? result;
    final CalculationStatus status;
    final String? errorMessage;

    const DuctCalculatorState({
      required this.input,
      this.result,
      required this.status,
      this.errorMessage,
    });

    DuctCalculatorState copyWith({
      DuctInput? input,
      DuctResult? result,
      CalculationStatus? status,
      String? errorMessage,
    }) {
      return DuctCalculatorState(
        input: input ?? this.input,
        result: result ?? this.result,
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );
    }
  }
  ```

  Write code in `apps/mobile/lib/services/duct/providers/duct_calculator_notifier.dart`:
  ```dart
  import 'dart:async';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../models/enums.dart';
  import '../models/duct_input.dart';
  import '../models/duct_calculator_state.dart';
  import '../services/duct_calculator_service.dart';

  final ductCalculatorServiceProvider = Provider<DuctCalculatorService>((ref) {
    return DuctCalculatorService();
  });

  final ductCalculatorProvider = StateNotifierProvider<DuctCalculatorNotifier, DuctCalculatorState>((ref) {
    return DuctCalculatorNotifier(ref);
  });

  class DuctCalculatorNotifier extends StateNotifier<DuctCalculatorState> {
    final Ref _ref;
    Timer? _debounceTimer;

    DuctCalculatorNotifier(this._ref)
        : super(const DuctCalculatorState(
            input: DuctInput(
              flowRate: 1700.0,
              targetVelocity: 4.5,
              frictionRate: 0.1,
              method: CalculationMethod.velocity,
              unitSystem: UnitSystem.metric,
              ductType: DuctType.supplyMain,
            ),
            status: CalculationStatus.idle,
          )) {
      _triggerCalculation();
    }

    void onFlowRateChanged(double value) {
      state = state.copyWith(input: _updateInput(flowRate: value));
      _debounceCalculate();
    }

    void onTargetVelocityChanged(double value) {
      state = state.copyWith(input: _updateInput(targetVelocity: value));
      _debounceCalculate();
    }

    void onFrictionRateChanged(double value) {
      state = state.copyWith(input: _updateInput(frictionRate: value));
      _debounceCalculate();
    }

    void onMethodChanged(CalculationMethod method) {
      state = state.copyWith(input: _updateInput(method: method));
      _triggerCalculation();
    }

    void onUnitSystemChanged(UnitSystem system) {
      // Direct immediate conversion
      final currentInput = state.input;
      double newFlow = currentInput.flowRate;
      double newVelocity = currentInput.targetVelocity;
      double newFriction = currentInput.frictionRate;

      if (system == UnitSystem.imperial) {
        newFlow = currentInput.flowRate * 0.5886;
        newVelocity = currentInput.targetVelocity * 196.85;
        newFriction = currentInput.frictionRate * 0.1225;
      } else {
        newFlow = currentInput.flowRate / 0.5886;
        newVelocity = currentInput.targetVelocity / 196.85;
        newFriction = currentInput.frictionRate / 0.1225;
      }

      state = state.copyWith(
        input: DuctInput(
          flowRate: newFlow,
          targetVelocity: newVelocity,
          frictionRate: newFriction,
          method: currentInput.method,
          unitSystem: system,
          ductType: currentInput.ductType,
        ),
      );
      _triggerCalculation();
    }

    void onDuctTypeChanged(DuctType type) {
      double suggestedVelocity = state.input.targetVelocity;
      if (state.input.unitSystem == UnitSystem.imperial) {
        if (type == DuctType.supplyMain) suggestedVelocity = 900;
        if (type == DuctType.supplyBranch) suggestedVelocity = 600;
        if (type == DuctType.returnMain) suggestedVelocity = 700;
        if (type == DuctType.exhaust) suggestedVelocity = 800;
      } else {
        if (type == DuctType.supplyMain) suggestedVelocity = 4.5;
        if (type == DuctType.supplyBranch) suggestedVelocity = 3.0;
        if (type == DuctType.returnMain) suggestedVelocity = 3.5;
        if (type == DuctType.exhaust) suggestedVelocity = 4.0;
      }

      state = state.copyWith(
        input: DuctInput(
          flowRate: state.input.flowRate,
          targetVelocity: suggestedVelocity,
          frictionRate: state.input.frictionRate,
          method: state.input.method,
          unitSystem: state.input.unitSystem,
          ductType: type,
        ),
      );
      _triggerCalculation();
    }

    DuctInput _updateInput({
      double? flowRate,
      double? targetVelocity,
      double? frictionRate,
      CalculationMethod? method,
      UnitSystem? unitSystem,
      DuctType? ductType,
    }) {
      return DuctInput(
        flowRate: flowRate ?? state.input.flowRate,
        targetVelocity: targetVelocity ?? state.input.targetVelocity,
        frictionRate: frictionRate ?? state.input.frictionRate,
        method: method ?? state.input.method,
        unitSystem: unitSystem ?? state.input.unitSystem,
        ductType: ductType ?? state.input.ductType,
      );
    }

    void _debounceCalculate() {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 250), _triggerCalculation);
    }

    void _triggerCalculation() {
      if (!state.input.isValid) {
        state = state.copyWith(status: CalculationStatus.idle);
        return;
      }
      state = state.copyWith(status: CalculationStatus.calculating);
      try {
        final service = _ref.read(ductCalculatorServiceProvider);
        final result = service.calculate(state.input);
        state = state.copyWith(
          status: CalculationStatus.success,
          result: result,
        );
      } catch (e) {
        state = state.copyWith(
          status: CalculationStatus.error,
          errorMessage: 'Lỗi tính toán: ${e.toString()}',
        );
      }
    }

    @override
    void dispose() {
      _debounceTimer?.cancel();
      super.dispose();
    }
  }
  ```

- [ ] **Step 5: Run tests and verify success**
  Run: `flutter test test/duct/service_test.dart`
  Expected: PASS

- [ ] **Step 6: Commit**
  Run:
  ```bash
  git add apps/mobile/lib/services/duct/services/ apps/mobile/lib/services/duct/models/duct_calculator_state.dart apps/mobile/lib/services/duct/providers/ apps/mobile/test/duct/service_test.dart
  git commit -m "feat: implement Riverpod notifier state, validator constraints and service providers"
  ```

---

### Task 5: Presentation Layer & Dashboard UI (DuctCalculatorScreen)

**Files:**
- Modify: `apps/mobile/lib/screens/tools/duct_calculator_screen.dart`
- Create: `apps/mobile/test/duct/ui_test.dart`

**Interfaces:**
- Consumes: `ductCalculatorProvider`, `DuctCalculatorNotifier`, `DuctCalculatorState`.
- Produces: Redesigned `DuctCalculatorScreen` UI component.

- [ ] **Step 1: Write failing UI widget test**
  Write code in `apps/mobile/test/duct/ui_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:mobile/screens/tools/duct_calculator_screen.dart';

  void main() {
    testWidgets('DuctCalculatorScreen renders segment controls and form', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DuctCalculatorScreen(),
          ),
        ),
      );
      expect(find.byType(DuctCalculatorScreen), findsOneWidget);
    });
  }
  ```

- [ ] **Step 2: Run UI test and verify failure**
  Run: `flutter test test/duct/ui_test.dart`
  Expected: FAIL (Compile error or element search fails on old UI items)

- [ ] **Step 3: Implement Dashboard UI in screen**
  Write code in `apps/mobile/lib/screens/tools/duct_calculator_screen.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:google_fonts/google_fonts.dart';
  import '../../core/theme/app_colors.dart';
  import '../../services/duct/models/enums.dart';
  import '../../services/duct/models/rectangle_option.dart';
  import '../../services/duct/providers/duct_calculator_notifier.dart';

  class DuctCalculatorScreen extends ConsumerStatefulWidget {
    const DuctCalculatorScreen({super.key});

    @override
    ConsumerState<DuctCalculatorScreen> createState() => _DuctCalculatorScreenState();
  }

  class _DuctCalculatorScreenState extends ConsumerState<DuctCalculatorScreen> {
    final _flowController = TextEditingController(text: '1700');
    final _velocityController = TextEditingController(text: '4.5');
    final _frictionController = TextEditingController(text: '0.1');

    @override
    void dispose() {
      _flowController.dispose();
      _velocityController.dispose();
      _frictionController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      final state = ref.watch(ductCalculatorProvider);
      final notifier = ref.read(ductCalculatorProvider.notifier);

      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Tính Toán Thiết Kế Ống Gió',
            style: GoogleFonts.firaCode(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented controls
              _buildSegmentControls(state, notifier),
              const SizedBox(height: 20),

              // Inputs card
              _buildInputCard(state, notifier),
              const SizedBox(height: 20),

              // Results layout
              if (state.status == CalculationStatus.success && state.result != null) ...[
                _buildRoundHeroCard(state),
                const SizedBox(height: 20),
                _buildRectangleSection(state),
              ] else if (state.status == CalculationStatus.calculating) ...[
                const Center(child: CircularProgressIndicator())
              ] else if (state.status == CalculationStatus.error) ...[
                Text(
                  state.errorMessage ?? 'Lỗi tính toán',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                )
              ]
            ],
          ),
        ),
      );
    }

    Widget _buildSegmentControls(dynamic state, dynamic notifier) {
      final isMetric = state.input.unitSystem == UnitSystem.metric;
      final isVelocity = state.input.method == CalculationMethod.velocity;

      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => notifier.onUnitSystemChanged(isMetric ? UnitSystem.imperial : UnitSystem.metric),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isMetric ? 'Metric (m³/h, m/s)' : 'Imperial (CFM, fpm)',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => notifier.onMethodChanged(isVelocity ? CalculationMethod.equalFriction : CalculationMethod.velocity),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isVelocity ? 'Velocity' : 'Equal Friction',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildInputCard(dynamic state, dynamic notifier) {
      final isMetric = state.input.unitSystem == UnitSystem.metric;
      final isVelocity = state.input.method == CalculationMethod.velocity;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<DuctType>(
              value: state.input.ductType,
              dropdownColor: AppColors.bgCard,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                labelText: 'Loại đường ống',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
              ),
              items: DuctType.values.map((t) {
                return DropdownMenuItem(value: t, child: Text(t.toString().split('.').last));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  notifier.onDuctTypeChanged(val);
                  _velocityController.text = state.input.targetVelocity.toStringAsFixed(1);
                }
              },
            ),
            const Divider(color: AppColors.divider),
            _buildField(
              label: 'Lưu lượng gió',
              suffix: isMetric ? 'm³/h' : 'CFM',
              controller: _flowController,
              onChanged: (val) {
                final d = double.tryParse(val);
                if (d != null) notifier.onFlowRateChanged(d);
              },
            ),
            if (isVelocity) ...[
              const Divider(color: AppColors.divider),
              _buildField(
                label: 'Vận tốc thiết kế',
                suffix: isMetric ? 'm/s' : 'fpm',
                controller: _velocityController,
                onChanged: (val) {
                  final d = double.tryParse(val);
                  if (d != null) notifier.onTargetVelocityChanged(d);
                },
              ),
            ] else ...[
              const Divider(color: AppColors.divider),
              _buildField(
                label: 'Độ tổn thất ma sát',
                suffix: isMetric ? 'Pa/m' : 'in.wg/100ft',
                controller: _frictionController,
                onChanged: (val) {
                  final d = double.tryParse(val);
                  if (d != null) notifier.onFrictionRateChanged(d);
                },
              ),
            ],
          ],
        ),
      );
    }

    Widget _buildField({
      required String label,
      required String suffix,
      required TextEditingController controller,
      required ValueChanged<String> onChanged,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                ),
                onChanged: onChanged,
              ),
            ),
            Text(
              suffix,
              style: const TextStyle(color: AppColors.accentPrimary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    Widget _buildRoundHeroCard(dynamic state) {
      final round = state.result!.roundDuct;
      final isMetric = state.input.unitSystem == UnitSystem.metric;
      final suffix = isMetric ? 'mm' : '"';

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.bgSecondary, AppColors.bgCard],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Text(
              'ỐNG TRÒN GỢI Ý (HERO)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Ø ${round.standardDiameter.toStringAsFixed(0)} $suffix',
              style: GoogleFonts.firaCode(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '(Tính toán: ${round.calculatedDiameter.toStringAsFixed(1)} $suffix)',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSpecItem('Vận tốc', '${round.velocity.toStringAsFixed(1)} ${isMetric ? 'm/s' : 'fpm'}'),
                _buildSpecItem('Ma sát', '${round.frictionRate.toStringAsFixed(2)} ${isMetric ? 'Pa/m' : 'in/100ft'}'),
              ],
            )
          ],
        ),
      );
    }

    Widget _buildSpecItem(String label, String val) {
      return Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      );
    }

    Widget _buildRectangleSection(dynamic state) {
      final List<RectangleOption> options = state.result!.rectangleOptions;
      if (options.isEmpty) return const SizedBox();

      final top = options.first;
      final others = options.skip(1).take(5).toList();
      final isMetric = state.input.unitSystem == UnitSystem.metric;
      final suffix = isMetric ? 'mm' : '"';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ỐNG CHỮ NHẬT ĐỀ XUẤT (BEST)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${top.width.toStringAsFixed(0)} × ${top.height.toStringAsFixed(0)} $suffix',
                      style: GoogleFonts.firaCode(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < top.stars ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Vận tốc: ${top.velocity.toStringAsFixed(1)} ${isMetric ? 'm/s' : 'fpm'}', style: const TextStyle(color: AppColors.textSecondary)),
                    const Text('✓ RECOMMENDED SIZE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'PHƯƠNG ÁN KHÁC (MORE OPTIONS)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...others.map((opt) {
            return Card(
              color: AppColors.bgSecondary,
              child: ListTile(
                title: Text(
                  '${opt.width.toStringAsFixed(0)} × ${opt.height.toStringAsFixed(0)} $suffix',
                  style: GoogleFonts.firaCode(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Vận tốc: ${opt.velocity.toStringAsFixed(1)} ${isMetric ? 'm/s' : 'fpm'}'),
                trailing: Text('${opt.stars} Sao', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ),
            );
          }),
        ],
      );
    }
  }
  ```

- [ ] **Step 4: Run tests and verify success**
  Run: `flutter test test/duct/ui_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit**
  Run:
  ```bash
  git add apps/mobile/lib/screens/tools/duct_calculator_screen.dart apps/mobile/test/duct/ui_test.dart
  git commit -m "feat: complete Presentation Layer of DuctCalculator with Dashboard layout and Hero Card"
  ```

---

### Task 6: Routing Verification & End-to-End Testing

**Files:**
- Modify: `apps/mobile/lib/core/routes/app_routes.dart`
- Create: `apps/mobile/test/duct/e2e_test.dart`

**Interfaces:**
- Consumes: Named route `AppRoutes.ductSizer` and `DuctCalculatorScreen`.
- Produces: Integrated routes and verified E2E tests.

- [ ] **Step 1: Check routes configuration**
  Verify named route exists in `apps/mobile/lib/core/routes/app_routes.dart` (which maps to `DuctCalculatorScreen` as seen in file verification).

- [ ] **Step 2: Write failing E2E simulation test**
  Write code in `apps/mobile/test/duct/e2e_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:mobile/core/routes/app_routes.dart';
  import 'package:mobile/screens/tools/duct_calculator_screen.dart';

  void main() {
    testWidgets('E2E: Routing opens DuctSizer and updates state on inputs', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            onGenerateRoute: AppRoutes.onGenerateRoute,
            initialRoute: AppRoutes.ductSizer,
          ),
        ),
      );
      expect(find.byType(DuctCalculatorScreen), findsOneWidget);
    });
  }
  ```

- [ ] **Step 3: Run E2E test and verify failure**
  Run: `flutter test test/duct/e2e_test.dart`
  Expected: FAIL or passes immediately if imports are wrong

- [ ] **Step 4: Verify all mobile app tests pass**
  Run: `flutter test` in `apps/mobile/`
  Expected: All tests pass (formulas_test, ranker_test, engine_test, service_test, ui_test, e2e_test).

- [ ] **Step 5: Run static analysis check**
  Run: `flutter analyze` in `apps/mobile/`
  Expected: No issues found!

- [ ] **Step 6: Commit**
  Run:
  ```bash
  git add apps/mobile/test/duct/e2e_test.dart
  git commit -m "test: verify routing and complete end-to-end simulation of Duct Calculator"
  ```
