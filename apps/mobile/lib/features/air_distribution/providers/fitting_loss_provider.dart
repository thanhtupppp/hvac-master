import 'package:flutter_riverpod/legacy.dart';

import '../../../core/hvac/models/enums.dart';
import '../formulas/duct_pressure_loss_engine.dart';
import '../formulas/fitting_loss_engine.dart';
import '../data/fitting_coefficients.dart';

enum FittingLossStatus { idle, calculating, success, error }

class FittingLossState {
  final FittingLossInput input;
  final FittingLossResult? result;
  final FittingLossStatus status;
  final String? errorMessage;

  const FittingLossState({
    required this.input,
    this.result,
    this.status = FittingLossStatus.idle,
    this.errorMessage,
  });

  FittingLossState copyWith({
    FittingLossInput? input,
    FittingLossResult? result,
    FittingLossStatus? status,
    String? errorMessage,
  }) {
    return FittingLossState(
      input: input ?? this.input,
      result: result ?? this.result,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FittingLossNotifier extends StateNotifier<FittingLossState> {
  FittingLossNotifier()
    : super(
        FittingLossState(
          input: FittingLossInput(
            flowRate: 1000,
            unit: UnitSystem.imperial,
            shape: FittingLossShape.round,
            ductDiameter: 12,
            fittings: [
              FittingWithQuantity(type: FittingType.elbow90R10, quantity: 4),
              FittingWithQuantity(type: FittingType.teeBranch, quantity: 2),
              FittingWithQuantity(type: FittingType.damper, quantity: 1),
            ],
          ),
        ),
      ) {
    _calculate();
  }

  void onFlowRateChanged(double value) {
    state = state.copyWith(input: _replaceInput(state.input, flowRate: value));
    _calculate();
  }

  void onUnitSystemChanged(UnitSystem unit) {
    final current = state.input;
    if (current.unit == unit) return;

    double newFlowRate = current.flowRate;
    double newDiameter = current.ductDiameter;
    double? newWidth = current.ductWidth;
    double? newHeight = current.ductHeight;

    if (current.unit == UnitSystem.imperial && unit == UnitSystem.metric) {
      newFlowRate = current.flowRate * 1.699;
      newDiameter = current.ductDiameterIn * 25.4;
      if (newWidth != null) newWidth = current.ductWidthM * 1000;
      if (newHeight != null) newHeight = current.ductHeightM * 1000;
    } else if (current.unit == UnitSystem.metric &&
        unit == UnitSystem.imperial) {
      newFlowRate = current.flowRate / 1.699;
      newDiameter = current.ductDiameterIn;
      if (newWidth != null) newWidth = current.ductWidthM * 1000 / 25.4;
      if (newHeight != null) newHeight = current.ductHeightM * 1000 / 25.4;
    }

    state = state.copyWith(
      input: FittingLossInput(
        flowRate: newFlowRate,
        unit: unit,
        shape: current.shape,
        ductDiameter: newDiameter,
        ductWidth: newWidth,
        ductHeight: newHeight,
        velocityOverride: current.velocityOverride,
        useVelocityOverride: current.useVelocityOverride,
        fittings: current.fittings,
      ),
    );
    _calculate();
  }

  void onShapeChanged(FittingLossShape shape) {
    final current = state.input;
    state = state.copyWith(
      input: FittingLossInput(
        flowRate: current.flowRate,
        unit: current.unit,
        shape: shape,
        ductDiameter: current.ductDiameter,
        ductWidth: shape == FittingLossShape.rectangular
            ? current.ductWidth
            : null,
        ductHeight: shape == FittingLossShape.rectangular
            ? current.ductHeight
            : null,
        velocityOverride: current.velocityOverride,
        useVelocityOverride: current.useVelocityOverride,
        fittings: current.fittings,
      ),
    );
    _calculate();
  }

  void onDuctDiameterChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, ductDiameter: value),
    );
    _calculate();
  }

  void onDuctSizeChanged(double? width, double? height) {
    state = state.copyWith(
      input: _replaceInput(state.input, ductWidth: width, ductHeight: height),
    );
    _calculate();
  }

  void onVelocityOverrideChanged(double value, {required bool enabled}) {
    state = state.copyWith(
      input: _replaceInput(
        state.input,
        velocityOverride: value,
        useVelocityOverride: enabled,
      ),
    );
    _calculate();
  }

  void addFitting(FittingType type, {int quantity = 1}) {
    final newFittings = [
      ...state.input.fittings,
      FittingWithQuantity(type: type, quantity: quantity),
    ];
    state = state.copyWith(
      input: _replaceInput(state.input, fittings: newFittings),
    );
    _calculate();
  }

  void removeFitting(int index) {
    if (index < 0 || index >= state.input.fittings.length) return;
    final newFittings = [...state.input.fittings];
    newFittings.removeAt(index);
    state = state.copyWith(
      input: _replaceInput(state.input, fittings: newFittings),
    );
    _calculate();
  }

  void updateFittingQuantity(int index, int quantity) {
    if (index < 0 || index >= state.input.fittings.length) return;
    final newFittings = [...state.input.fittings];
    newFittings[index] = FittingWithQuantity(
      type: newFittings[index].type,
      quantity: quantity.clamp(1, 99),
    );
    state = state.copyWith(
      input: _replaceInput(state.input, fittings: newFittings),
    );
    _calculate();
  }

  void clearFittings() {
    state = state.copyWith(
      input: _replaceInput(state.input, fittings: const []),
    );
    _calculate();
  }

  FittingLossInput _replaceInput(
    FittingLossInput current, {
    double? flowRate,
    UnitSystem? unit,
    FittingLossShape? shape,
    double? ductDiameter,
    double? ductWidth,
    double? ductHeight,
    double? velocityOverride,
    bool? useVelocityOverride,
    List<FittingWithQuantity>? fittings,
  }) {
    return FittingLossInput(
      flowRate: flowRate ?? current.flowRate,
      unit: unit ?? current.unit,
      shape: shape ?? current.shape,
      ductDiameter: ductDiameter ?? current.ductDiameter,
      ductWidth: ductWidth ?? current.ductWidth,
      ductHeight: ductHeight ?? current.ductHeight,
      velocityOverride: velocityOverride ?? current.velocityOverride,
      useVelocityOverride: useVelocityOverride ?? current.useVelocityOverride,
      fittings: fittings ?? current.fittings,
    );
  }

  void _calculate() {
    state = state.copyWith(status: FittingLossStatus.calculating);

    try {
      final result = FittingLossEngine.calculate(state.input);
      if (result == null) {
        state = state.copyWith(
          status: FittingLossStatus.error,
          errorMessage: 'Vui lòng nhập lưu lượng và kích thước ống.',
        );
        return;
      }
      state = state.copyWith(status: FittingLossStatus.success, result: result);
    } catch (e) {
      state = state.copyWith(
        status: FittingLossStatus.error,
        errorMessage: 'Lỗi tính toán: $e',
      );
    }
  }
}

final fittingLossProvider =
    StateNotifierProvider<FittingLossNotifier, FittingLossState>((ref) {
      return FittingLossNotifier();
    });
