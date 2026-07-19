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
