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
