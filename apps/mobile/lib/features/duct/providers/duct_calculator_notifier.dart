import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/hvac/models/models.dart';
import '../../../core/hvac/units/unit_converter.dart';
import '../../../core/hvac/standards/velocity_table.dart';
import '../models/duct_calculator_state.dart';
import '../services/duct_calculator_service.dart';

final ductCalculatorServiceProvider = Provider<DuctCalculatorService>((ref) {
  return DuctCalculatorService();
});

final ductCalculatorProvider =
    StateNotifierProvider<DuctCalculatorNotifier, DuctCalculatorState>((ref) {
      return DuctCalculatorNotifier(ref);
    });

class DuctCalculatorNotifier extends StateNotifier<DuctCalculatorState> {
  final Ref _ref;
  Timer? _debounceTimer;

  DuctCalculatorNotifier(this._ref)
    : super(
        const DuctCalculatorState(
          input: HvacInput(
            flowRate: 1700.0,
            targetVelocity: 4.5,
            frictionRate: 0.1,
            method: CalculationMethod.velocity,
            unitSystem: UnitSystem.metric,
            systemType: SystemType.supplyMain,
          ),
          status: CalculationStatus.idle,
        ),
      ) {
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
      newFlow = UnitConverter.toCfm(
        currentInput.flowRate,
        currentInput.unitSystem,
      );
      newVelocity = UnitConverter.toFpm(
        currentInput.targetVelocity,
        currentInput.unitSystem,
      );
      newFriction = UnitConverter.toInWg(
        currentInput.frictionRate,
        currentInput.unitSystem,
      );
    } else {
      newFlow = UnitConverter.fromCfm(currentInput.flowRate, system);
      newVelocity = UnitConverter.fromFpm(currentInput.targetVelocity, system);
      newFriction = UnitConverter.fromInWg(currentInput.frictionRate, system);
    }

    state = state.copyWith(
      input: HvacInput(
        flowRate: newFlow,
        targetVelocity: newVelocity,
        frictionRate: newFriction,
        method: currentInput.method,
        unitSystem: system,
        systemType: currentInput.systemType,
      ),
    );
    _triggerCalculation();
  }

  void onDuctTypeChanged(SystemType type) {
    double suggestedVelocity;
    if (state.input.unitSystem == UnitSystem.imperial) {
      suggestedVelocity = VelocityTable.getRecommendedVelocityFpm(type);
    } else {
      suggestedVelocity = VelocityTable.getRecommendedVelocityMs(type);
    }

    state = state.copyWith(
      input: HvacInput(
        flowRate: state.input.flowRate,
        targetVelocity: suggestedVelocity,
        frictionRate: state.input.frictionRate,
        method: state.input.method,
        unitSystem: state.input.unitSystem,
        systemType: type,
      ),
    );
    _triggerCalculation();
  }

  HvacInput _updateInput({
    double? flowRate,
    double? targetVelocity,
    double? frictionRate,
    CalculationMethod? method,
    UnitSystem? unitSystem,
    SystemType? systemType,
  }) {
    return HvacInput(
      flowRate: flowRate ?? state.input.flowRate,
      targetVelocity: targetVelocity ?? state.input.targetVelocity,
      frictionRate: frictionRate ?? state.input.frictionRate,
      method: method ?? state.input.method,
      unitSystem: unitSystem ?? state.input.unitSystem,
      systemType: systemType ?? state.input.systemType,
    );
  }

  void _debounceCalculate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: 250),
      _triggerCalculation,
    );
  }

  void _triggerCalculation() {
    if (!state.input.isValid) {
      state = state.copyWith(
        status: CalculationStatus.idle,
        result: () => null,
        errorMessage: () => null,
      );
      return;
    }
    state = state.copyWith(
      status: CalculationStatus.calculating,
      result: () => null,
      errorMessage: () => null,
    );
    try {
      final service = _ref.read(ductCalculatorServiceProvider);
      final result = service.calculate(state.input);
      state = state.copyWith(
        status: CalculationStatus.success,
        result: () => result,
        errorMessage: () => null,
      );
    } catch (e) {
      state = state.copyWith(
        status: CalculationStatus.error,
        result: () => null,
        errorMessage: () => 'Lỗi tính toán: ${e.toString()}',
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
