import '../../../core/hvac/models/models.dart';

class DuctCalculatorState {
  final HvacInput input;
  final HvacResult? result;
  final CalculationStatus status;
  final String? errorMessage;

  const DuctCalculatorState({
    required this.input,
    this.result,
    required this.status,
    this.errorMessage,
  });

  DuctCalculatorState copyWith({
    HvacInput? input,
    HvacResult? Function()? result,
    CalculationStatus? status,
    String? Function()? errorMessage,
  }) {
    return DuctCalculatorState(
      input: input ?? this.input,
      result: result != null ? result() : this.result,
      status: status ?? this.status,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}
