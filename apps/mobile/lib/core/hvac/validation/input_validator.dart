import '../models/models.dart';

class InputValidator {
  static bool isValidFlowRate(double flowRate) {
    return flowRate > 0 && flowRate.isFinite;
  }

  static bool isValidVelocity(double velocity) {
    return velocity > 0 && velocity.isFinite;
  }

  static bool isValidFrictionRate(double frictionRate) {
    return frictionRate > 0 && frictionRate.isFinite;
  }

  static bool isValidFrictionRateRange(double frictionRate, UnitSystem unit) {
    if (unit == UnitSystem.imperial) {
      return frictionRate >= 0.05 && frictionRate <= 0.3;
    } else {
      return frictionRate >= 0.4 && frictionRate <= 2.5;
    }
  }

  static String? validateInput(HvacInput input) {
    if (!isValidFlowRate(input.flowRate)) {
      return 'Lưu lượng gió phải lớn hơn 0';
    }
    if (input.method == CalculationMethod.velocity &&
        !isValidVelocity(input.targetVelocity)) {
      return 'Vận tốc gió phải lớn hơn 0';
    }
    if (input.method == CalculationMethod.equalFriction &&
        !isValidFrictionRate(input.frictionRate)) {
      return 'Tỷ lệ ma sát phải lớn hơn 0';
    }
    return null;
  }
}
