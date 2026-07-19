import 'enums.dart';

class HvacInput {
  final double flowRate;
  final double targetVelocity;
  final double frictionRate;
  final CalculationMethod method;
  final UnitSystem unitSystem;
  final SystemType systemType;

  const HvacInput({
    required this.flowRate,
    required this.targetVelocity,
    required this.frictionRate,
    required this.method,
    required this.unitSystem,
    required this.systemType,
  });

  bool get isValid {
    if (flowRate <= 0) return false;
    if (method == CalculationMethod.velocity && targetVelocity <= 0) return false;
    if (method == CalculationMethod.equalFriction && frictionRate <= 0) return false;
    return true;
  }
}
