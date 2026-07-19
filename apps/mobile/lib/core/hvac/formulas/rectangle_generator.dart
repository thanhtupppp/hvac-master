import '../../hvac/models/models.dart';
import '../standards/preferred_rect_sizes.dart';
import 'hvac_formulas.dart';
import '../ranking/rectangle_ranker.dart';

class RectangleGenerator {
  static List<RectangleOption> generateOptions({
    required double targetAreaInSqIn,
    required double targetDiameterIn,
    required double targetVelocityFpm,
    required double flowRateCfm,
    required HvacInput input,
    required List<double> standardRectSizesInInches,
  }) {
    final List<RectangleOption> options = [];

    for (int i = 0; i < standardRectSizesInInches.length; i++) {
      final w = standardRectSizesInInches[i];
      for (int j = 0; j < standardRectSizesInInches.length; j++) {
        final h = standardRectSizesInInches[j];
        if (w < h) continue;

        final area = w * h;
        final ar = w / h;
        if (ar > 4.0) continue;

        final velocity = HvacFormulas.velocity(
          cfm: flowRateCfm,
          areaSqFt: area / 144.0,
        );
        final de = HvacFormulas.equivalentDiameter(a: w, b: h);

        final velErr = targetVelocityFpm <= 0
            ? 1.0
            : (velocity - targetVelocityFpm).abs() / targetVelocityFpm;
        final deErr = targetDiameterIn <= 0
            ? 1.0
            : (de - targetDiameterIn).abs() / targetDiameterIn;

        final widthForCheck = input.unitSystem == UnitSystem.metric
            ? w * 25.4
            : w;
        final heightForCheck = input.unitSystem == UnitSystem.metric
            ? h * 25.4
            : h;
        final preferred = PreferredRectSizes.contains(
          widthForCheck,
          heightForCheck,
          input.unitSystem == UnitSystem.metric,
        );

        final mockOption = RectangleOption(
          width: w,
          height: h,
          area: area,
          velocity: velocity,
          equivalentDiameter: de,
          aspectRatio: ar,
          score: 0,
          stars: 0,
          preferred: preferred,
          velocityError: velErr,
          equivalentDiameterError: deErr,
        );

        final finalScore = RectangleRanker.score(
          option: mockOption,
          targetVelocityFpm: targetVelocityFpm,
          targetEquivDiamIn: targetDiameterIn,
        );

        options.add(
          RectangleOption(
            width: w,
            height: h,
            area: area,
            velocity: velocity,
            equivalentDiameter: de,
            aspectRatio: ar,
            score: finalScore,
            stars: RectangleRanker.toStars(finalScore),
            preferred: preferred,
            velocityError: velErr,
            equivalentDiameterError: deErr,
          ),
        );
      }
    }

    options.sort((a, b) => b.score.compareTo(a.score));
    return options;
  }
}
