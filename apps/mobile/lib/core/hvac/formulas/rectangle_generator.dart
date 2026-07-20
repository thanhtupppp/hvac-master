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
    final options = <RectangleOption>[];
    final isMetric = input.unitSystem == UnitSystem.metric;
    final targetVel = targetVelocityFpm;
    final targetDiam = targetDiameterIn;
    final cfm = flowRateCfm;

    for (int i = 0; i < standardRectSizesInInches.length; i++) {
      final w = standardRectSizesInInches[i];
      for (int j = 0; j < standardRectSizesInInches.length; j++) {
        final h = standardRectSizesInInches[j];
        if (w <= h) continue;

        final ar = w / h;
        if (ar > 4.0) continue;

        final area = w * h;
        final velocity = HvacFormulas.velocity(
          cfm: cfm,
          areaSqFt: area / 144.0,
        );
        final de = HvacFormulas.equivalentDiameter(a: w, b: h);

        final velErr = targetVel <= 0
            ? 1.0
            : (velocity - targetVel).abs() / targetVel;
        final deErr = targetDiam <= 0
            ? 1.0
            : (de - targetDiam).abs() / targetDiam;

        final wForPreferred = isMetric ? w * 25.4 : w;
        final hForPreferred = isMetric ? h * 25.4 : h;
        final preferred = _isPreferred(wForPreferred, hForPreferred, isMetric);

        final score = RectangleRanker.score(
          option: RectangleOption(
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
          ),
          targetVelocityFpm: targetVel,
          targetEquivDiamIn: targetDiam,
        );

        options.add(
          RectangleOption(
            width: w,
            height: h,
            area: area,
            velocity: velocity,
            equivalentDiameter: de,
            aspectRatio: ar,
            score: score,
            stars: RectangleRanker.toStars(score),
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

  static bool _isPreferred(double w, double h, bool isMetric) {
    return PreferredRectSizes.contains(w, h, isMetric);
  }
}
