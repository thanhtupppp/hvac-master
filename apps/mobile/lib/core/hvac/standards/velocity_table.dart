import '../models/models.dart';

class VelocityTable {
  static double getRecommendedVelocityFpm(SystemType type) {
    switch (type) {
      case SystemType.supplyMain:
        return 900.0;
      case SystemType.supplyBranch:
        return 600.0;
      case SystemType.returnMain:
        return 700.0;
      case SystemType.exhaust:
        return 800.0;
      case SystemType.custom:
        return 800.0;
      case SystemType.hotWaterPipe:
      case SystemType.chilledWaterPipe:
        return 400.0;
    }
  }
}
