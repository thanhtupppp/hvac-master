import '../models/models.dart';
import '../standards/preferred_rect_sizes.dart';

class RectangleRanker {
  static const _wVelocity = 0.40;
  static const _wAspect = 0.30;
  static const _wEquivDiam = 0.20;
  static const _wPreferred = 0.10;

  static double score({
    required RectangleOption option,
    required double targetVelocityFpm,
    required double targetEquivDiamIn,
  }) {
    final velScore = (1.0 - option.velocityError.clamp(0.0, 1.0)) * 100.0;

    final ar = option.aspectRatio;
    double arScore = 0.0;
    if (ar <= 1.5) {
      arScore = 100.0;
    } else if (ar <= 4.0) {
      arScore = 100.0 - ((ar - 1.5) / 2.5) * 60.0;
    }

    final deScore =
        (1.0 - option.equivalentDiameterError.clamp(0.0, 1.0)) * 100.0;

    final preferred = PreferredRectSizes.contains(
      option.width,
      option.height,
      false,
    );
    final prefScore = preferred ? 100.0 : 0.0;

    final raw =
        velScore * _wVelocity +
        arScore * _wAspect +
        deScore * _wEquivDiam +
        prefScore * _wPreferred;
    return raw.clamp(0.0, 100.0);
  }

  static int toStars(double score) {
    if (score >= 90) return 5;
    if (score >= 80) return 4;
    if (score >= 70) return 3;
    if (score >= 60) return 2;
    return 1;
  }
}
