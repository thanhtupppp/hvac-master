import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:state_notifier/state_notifier.dart';
import '../models/enums.dart';
import '../models/duct_input.dart';
import '../models/duct_calculator_state.dart';
import '../services/duct_calculator_service.dart';

final ductCalculatorServiceProvider = Provider<DuctCalculatorService>((ref) {
  return DuctCalculatorService();
});

final ductCalculatorProvider = StateNotifierProvider<DuctCalculatorNotifier, DuctCalculatorState>((ref) {
  return DuctCalculatorNotifier(ref);
});

class DuctCalculatorNotifier extends StateNotifier<DuctCalculatorState> {
  final Ref _ref;
  Timer? _debounceTimer;

  DuctCalculatorNotifier(this._ref)
      : super(const DuctCalculatorState(
          input: DuctInput(
            flowRate: 1700.0,
            targetVelocity: 4.5,
            frictionRate: 0.1,
            method: CalculationMethod.velocity,
            unitSystem: UnitSystem.metric,
            ductType: DuctType.supplyMain,
          ),
          status: CalculationStatus.idle,
        )) {
    _triggerCalculation();
  }

  void onFlowRateChanged(double value) {
    state = state.copyWith(input: _updateInput(flowRate: value));
    _debounceCalculate();
  }

  void onTargetVelocityChanged(double value) {
    state = state.copyWith(input: _updateInput(targetVelocity: value));
    _debounceCalculate();
  }

  void onFrictionRateChanged(double value) {
    state = state.copyWith(input: _updateInput(frictionRate: value));
    _debounceCalculate();
  }

  void onMethodChanged(CalculationMethod method) {
    state = state.copyWith(input: _updateInput(method: method));
    _triggerCalculation();
  }

  void onUnitSystemChanged(UnitSystem system) {
    final currentInput = state.input;
    if (currentInput.unitSystem == system) return;

    double newFlow = currentInput.flowRate;
    double newVelocity = currentInput.targetVelocity;
    double newFriction = currentInput.frictionRate;

    if (system == UnitSystem.imperial) {
      newFlow = currentInput.flowRate * 0.5886;
      newVelocity = currentInput.targetVelocity * 196.85;
      newFriction = currentInput.frictionRate * 0.1225;
    } else {
      newFlow = currentInput.flowRate / 0.5886;
      newVelocity = currentInput.targetVelocity / 196.85;
      newFriction = currentInput.frictionRate / 0.1225;
    }

    state = state.copyWith(
      input: DuctInput(
        flowRate: newFlow,
        targetVelocity: newVelocity,
        frictionRate: newFriction,
        method: currentInput.method,
        unitSystem: system,
        ductType: currentInput.ductType,
      ),
    );
    _triggerCalculation();
  }

  void onDuctTypeChanged(DuctType type) {
    double suggestedVelocity = state.input.targetVelocity;
    if (state.input.unitSystem == UnitSystem.imperial) {
      if (type == DuctType.supplyMain) suggestedVelocity = 900;
      if (type == DuctType.supplyBranch) suggestedVelocity = 600;
      if (type == DuctType.returnMain) suggestedVelocity = 700;
      if (type == DuctType.exhaust) suggestedVelocity = 800;
    } else {
      if (type == DuctType.supplyMain) suggestedVelocity = 4.5;
      if (type == DuctType.supplyBranch) suggestedVelocity = 3.0;
      if (type == DuctType.returnMain) suggestedVelocity = 3.5;
      if (type == DuctType.exhaust) suggestedVelocity = 4.0;
    }

    state = state.copyWith(
      input: DuctInput(
        flowRate: state.input.flowRate,
        targetVelocity: suggestedVelocity,
        frictionRate: state.input.frictionRate,
        method: state.input.method,
        unitSystem: state.input.unitSystem,
        ductType: type,
      ),
    );
    _triggerCalculation();
  }

  DuctInput _updateInput({
    double? flowRate,
    double? targetVelocity,
    double? frictionRate,
    CalculationMethod? method,
    UnitSystem? unitSystem,
    DuctType? ductType,
  }) {
    return DuctInput(
      flowRate: flowRate ?? state.input.flowRate,
      targetVelocity: targetVelocity ?? state.input.targetVelocity,
      frictionRate: frictionRate ?? state.input.frictionRate,
      method: method ?? state.input.method,
      unitSystem: unitSystem ?? state.input.unitSystem,
      ductType: ductType ?? state.input.ductType,
    );
  }

  void _debounceCalculate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), _triggerCalculation);
  }

  void _triggerCalculation() {
    if (!state.input.isValid) {
      state = state.copyWith(status: CalculationStatus.idle);
      return;
    }
    state = state.copyWith(status: CalculationStatus.calculating);
    try {
      final service = _ref.read(ductCalculatorServiceProvider);
      final result = service.calculate(state.input);
      state = state.copyWith(
        status: CalculationStatus.success,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: CalculationStatus.error,
        errorMessage: 'Lỗi tính toán: ${e.toString()}',
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
