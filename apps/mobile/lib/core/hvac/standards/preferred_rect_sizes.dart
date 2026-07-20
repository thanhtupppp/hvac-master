import 'dart:math';

class PreferredRectSizes {
  static const List<Point<double>> preferredImperial = [
    Point(12, 8),
    Point(14, 7),
    Point(16, 8),
    Point(16, 10),
    Point(18, 8),
    Point(18, 10),
    Point(20, 10),
    Point(20, 12),
    Point(24, 12),
    Point(24, 14),
    Point(24, 16),
  ];

  static const List<Point<double>> preferredMetric = [
    Point(300, 200),
    Point(400, 200),
    Point(500, 250),
    Point(600, 300),
    Point(600, 400),
    Point(800, 400),
    Point(1000, 500),
  ];

  static bool contains(double width, double height, bool isMetric) {
    final list = isMetric ? preferredMetric : preferredImperial;
    for (final p in list) {
      final matchNormal =
          (p.x - width).abs() < 0.01 && (p.y - height).abs() < 0.01;
      final matchRotated =
          (p.x - height).abs() < 0.01 && (p.y - width).abs() < 0.01;
      if (matchNormal || matchRotated) {
        return true;
      }
    }
    return false;
  }
}
