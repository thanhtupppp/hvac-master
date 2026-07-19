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
