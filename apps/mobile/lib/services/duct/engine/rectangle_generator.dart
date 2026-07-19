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
