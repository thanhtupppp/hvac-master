import 'enums.dart';
import 'duct_input.dart';
import 'duct_result.dart';

class DuctCalculatorState {
  final DuctInput input;
  final DuctResult? result;
  final CalculationStatus status;
  final String? errorMessage;

  const DuctCalculatorState({
    required this.input,
    this.result,
    required this.status,
    this.errorMessage,
  });

  DuctCalculatorState copyWith({
    DuctInput? input,
    DuctResult? Function()? result,
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
