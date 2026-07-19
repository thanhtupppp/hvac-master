import 'enums.dart';

class DuctInput {
  final double flowRate;
  final double targetVelocity;
  final double frictionRate;
  final CalculationMethod method;
  final UnitSystem unitSystem;
  final DuctType ductType;

  const DuctInput({
    required this.flowRate,
    required this.targetVelocity,
    required this.frictionRate,
    required this.method,
    required this.unitSystem,
    required this.ductType,
  });

  bool get isValid {
    if (flowRate <= 0) return false;
    if (method == CalculationMethod.velocity && targetVelocity <= 0) return false;
    if (method == CalculationMethod.equalFriction && frictionRate <= 0) return false;
    return true;
  }
}
