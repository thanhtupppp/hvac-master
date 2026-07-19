import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/duct/engine/standard_sizes.dart';
import 'package:mobile/services/duct/engine/preferred_rect_sizes.dart';
import 'package:mobile/services/duct/engine/velocity_table.dart';
import 'package:mobile/services/duct/engine/rectangle_ranker.dart';
import 'package:mobile/services/duct/engine/rectangle_generator.dart';
import 'package:mobile/services/duct/models/rectangle_option.dart';
import 'package:mobile/services/duct/models/duct_input.dart';
import 'package:mobile/services/duct/models/enums.dart';

void main() {
  group('StandardSizes Tests', () {
    test('findNearestStandardRound finds closest standard imperial round diameter', () {
      expect(StandardSizes.findNearestStandardRound(3.8, StandardSizes.imperialRound), 4.0);
      expect(StandardSizes.findNearestStandardRound(10.2, StandardSizes.imperialRound), 10.0);
      expect(StandardSizes.findNearestStandardRound(13.1, StandardSizes.imperialRound), 14.0);
    });

    test('findNearestStandardRound finds closest standard metric round diameter', () {
      expect(StandardSizes.findNearestStandardRound(98, StandardSizes.metricRound), 100.0);
      expect(StandardSizes.findNearestStandardRound(215, StandardSizes.metricRound), 225.0);
    });

    test('findNearestStandardRound returns input if list is empty', () {
      expect(StandardSizes.findNearestStandardRound(10.5, []), 10.5);
    });
  });

  group('PreferredRectSizes Tests', () {
    test('contains returns true for preferred imperial sizes (either orientation)', () {
      expect(PreferredRectSizes.contains(12, 8, false), true);
      expect(PreferredRectSizes.contains(8, 12, false), true);
      expect(PreferredRectSizes.contains(24, 16, false), true);
    });

    test('contains returns true for preferred metric sizes (either orientation)', () {
      expect(PreferredRectSizes.contains(300, 200, true), true);
      expect(PreferredRectSizes.contains(200, 300, true), true);
      expect(PreferredRectSizes.contains(1000, 500, true), true);
    });

    test('contains returns false for non-preferred sizes', () {
      expect(PreferredRectSizes.contains(10, 10, false), false);
      expect(PreferredRectSizes.contains(10, 10, true), false);
    });
  });

  group('VelocityTable Tests', () {
    test('getRecommendedVelocityFpm returns correct recommended velocity', () {
      expect(VelocityTable.getRecommendedVelocityFpm(DuctType.supplyMain), 900.0);
      expect(VelocityTable.getRecommendedVelocityFpm(DuctType.supplyBranch), 600.0);
      expect(VelocityTable.getRecommendedVelocityFpm(DuctType.returnMain), 700.0);
      expect(VelocityTable.getRecommendedVelocityFpm(DuctType.exhaust), 800.0);
      expect(VelocityTable.getRecommendedVelocityFpm(DuctType.custom), 800.0);
    });
  });

  group('RectangleRanker Tests', () {
    test('RectangleRanker score returns 100 for perfect match', () {
      const option = RectangleOption(
        width: 12, height: 8, area: 96, velocity: 800,
        equivalentDiameter: 10.2, aspectRatio: 1.5,
        score: 0, stars: 0, preferred: true,
        velocityError: 0, equivalentDiameterError: 0
      );
      final s = RectangleRanker.score(
        option: option,
        targetVelocityFpm: 800, targetEquivDiamIn: 10.2
      );
      expect(s, closeTo(100.0, 5.0));
    });

    test('toStars returns correct rating based on score', () {
      expect(RectangleRanker.toStars(95.0), 5);
      expect(RectangleRanker.toStars(85.0), 4);
      expect(RectangleRanker.toStars(75.0), 3);
      expect(RectangleRanker.toStars(65.0), 2);
      expect(RectangleRanker.toStars(55.0), 1);
    });
  });

  group('RectangleGenerator Tests', () {
    test('generateOptions returns a sorted list of valid RectangleOptions', () {
      const input = DuctInput(
        flowRate: 1000, targetVelocity: 800, frictionRate: 0.1,
        method: CalculationMethod.velocity, unitSystem: UnitSystem.imperial,
        ductType: DuctType.supplyMain
      );

      final options = RectangleGenerator.generateOptions(
        targetAreaInSqIn: 180,
        targetDiameterIn: 15.0,
        targetVelocityFpm: 800,
        flowRateCfm: 1000,
        input: input,
      );

      expect(options, isNotEmpty);

      // Verify that sorting is descending by score
      for (int i = 0; i < options.length - 1; i++) {
        expect(options[i].score >= options[i + 1].score, true);
      }

      // Verify that filters are respected: width >= height and aspect ratio <= 4.0
      for (final opt in options) {
        expect(opt.width >= opt.height, true);
        expect(opt.aspectRatio <= 4.0, true);
      }
    });
  });
}
