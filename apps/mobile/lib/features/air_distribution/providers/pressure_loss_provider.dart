import 'package:flutter_riverpod/legacy.dart';

import '../../../core/hvac/models/enums.dart';
import '../constants/air_distribution_constants.dart';
import '../formulas/duct_pressure_loss_engine.dart';
import '../data/fitting_coefficients.dart';

enum PressureLossStatus { idle, calculating, success, error }

class PressureLossState {
  final DuctPressureLossInput input;
  final DuctPressureLossResult? result;
  final PressureLossStatus status;
  final String? errorMessage;

  const PressureLossState({
    required this.input,
    this.result,
    this.status = PressureLossStatus.idle,
    this.errorMessage,
  });

  PressureLossState copyWith({
    DuctPressureLossInput? input,
    DuctPressureLossResult? result,
    PressureLossStatus? status,
    String? errorMessage,
  }) {
    return PressureLossState(
      input: input ?? this.input,
      result: result ?? this.result,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PressureLossNotifier extends StateNotifier<PressureLossState> {
  PressureLossNotifier()
    : super(
        PressureLossState(
          input: DuctPressureLossInput(
            flowRate: 1000,
            unit: UnitSystem.imperial,
            shape: DuctShapeForLoss.round,
            ductDiameter: 12,
            length: 50,
            material: DuctMaterial.galvanized,
            fittings: [
              FittingWithQuantity(type: FittingType.elbow90R10, quantity: 2),
              FittingWithQuantity(type: FittingType.teeBranch, quantity: 1),
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
    double? newDiameter = current.ductDiameter;
    double? newWidth = current.ductWidth;
    double? newHeight = current.ductHeight;
    double newLength = current.length;

    if (current.unit == UnitSystem.imperial && unit == UnitSystem.metric) {
      newFlowRate = current.flowRate * 1.699;
      if (newDiameter != null) newDiameter = current.ductDiameterIn * 25.4;
      if (newWidth != null) newWidth = current.ductWidthM * 1000;
      if (newHeight != null) newHeight = current.ductHeightM * 1000;
      newLength = current.lengthM;
    } else if (current.unit == UnitSystem.metric &&
        unit == UnitSystem.imperial) {
      newFlowRate = current.flowRate / 1.699;
      if (newDiameter != null) newDiameter = current.ductDiameterIn;
      if (newWidth != null) newWidth = current.ductWidthM * 1000 / 25.4;
      if (newHeight != null) newHeight = current.ductHeightM * 1000 / 25.4;
      newLength = current.lengthFt;
    }

    state = state.copyWith(
      input: DuctPressureLossInput(
        flowRate: newFlowRate,
        unit: unit,
        shape: current.shape,
        ductDiameter: newDiameter,
        ductWidth: newWidth,
        ductHeight: newHeight,
        length: newLength,
        material: current.material,
        fittings: current.fittings,
      ),
    );
    _calculate();
  }

  void onShapeChanged(DuctShapeForLoss shape) {
    final current = state.input;
    state = state.copyWith(
      input: DuctPressureLossInput(
        flowRate: current.flowRate,
        unit: current.unit,
        shape: shape,
        ductDiameter: shape == DuctShapeForLoss.round
            ? current.ductDiameter
            : null,
        ductWidth: shape == DuctShapeForLoss.rectangular
            ? current.ductWidth
            : null,
        ductHeight: shape == DuctShapeForLoss.rectangular
            ? current.ductHeight
            : null,
        length: current.length,
        material: current.material,
        fittings: current.fittings,
      ),
    );
    _calculate();
  }

  void onDuctDiameterChanged(double? value) {
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

  void onLengthChanged(double value) {
    state = state.copyWith(input: _replaceInput(state.input, length: value));
    _calculate();
  }

  void onMaterialChanged(DuctMaterial material) {
    state = state.copyWith(
      input: _replaceInput(state.input, material: material),
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

  DuctPressureLossInput _replaceInput(
    DuctPressureLossInput current, {
    double? flowRate,
    UnitSystem? unit,
    DuctShapeForLoss? shape,
    double? ductDiameter,
    double? ductWidth,
    double? ductHeight,
    double? length,
    DuctMaterial? material,
    List<FittingWithQuantity>? fittings,
  }) {
    return DuctPressureLossInput(
      flowRate: flowRate ?? current.flowRate,
      unit: unit ?? current.unit,
      shape: shape ?? current.shape,
      ductDiameter: ductDiameter ?? current.ductDiameter,
      ductWidth: ductWidth ?? current.ductWidth,
      ductHeight: ductHeight ?? current.ductHeight,
      length: length ?? current.length,
      material: material ?? current.material,
      fittings: fittings ?? current.fittings,
    );
  }

  void _calculate() {
    state = state.copyWith(status: PressureLossStatus.calculating);

    try {
      final result = DuctPressureLossEngine.calculate(state.input);
      if (result == null) {
        state = state.copyWith(
          status: PressureLossStatus.error,
          errorMessage: 'Vui lòng nhập đầy đủ thông số đường ống.',
        );
        return;
      }
      state = state.copyWith(
        status: PressureLossStatus.success,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: PressureLossStatus.error,
        errorMessage: 'Lỗi tính toán: $e',
      );
    }
  }
}

final pressureLossProvider =
    StateNotifierProvider<PressureLossNotifier, PressureLossState>((ref) {
      return PressureLossNotifier();
    });
