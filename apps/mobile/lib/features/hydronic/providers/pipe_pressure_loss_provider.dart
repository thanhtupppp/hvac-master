import 'package:flutter_riverpod/legacy.dart';

import '../../../core/hvac/models/enums.dart';
import '../constants/hydronic_constants.dart';
import '../formulas/pipe_pressure_loss_engine.dart';

enum PipePressureLossStatus { idle, calculating, success, error }

class PipePressureLossState {
  final PipePressureLossInput input;
  final PipePressureLossResult? result;
  final PipePressureLossStatus status;
  final String? errorMessage;

  const PipePressureLossState({
    required this.input,
    this.result,
    this.status = PipePressureLossStatus.idle,
    this.errorMessage,
  });

  PipePressureLossState copyWith({
    PipePressureLossInput? input,
    PipePressureLossResult? result,
    PipePressureLossStatus? status,
    String? errorMessage,
  }) {
    return PipePressureLossState(
      input: input ?? this.input,
      result: result ?? this.result,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PipePressureLossNotifier extends StateNotifier<PipePressureLossState> {
  PipePressureLossNotifier()
    : super(
        const PipePressureLossState(
          input: PipePressureLossInput(
            flowRate: 100,
            diameterIn: 2.0,
            lengthFt: 100,
            material: PipeMaterial.steelBlack,
            service: PipeService.chilledWater,
            fittings: [],
            unit: UnitSystem.imperial,
          ),
        ),
      ) {
    _calculate();
  }

  void onFlowRateChanged(double v) {
    state = state.copyWith(input: _replace(state.input, flowRate: v));
    _calculate();
  }

  void onDiameterChanged(double v) {
    state = state.copyWith(input: _replace(state.input, diameterIn: v));
    _calculate();
  }

  void onLengthChanged(double v) {
    state = state.copyWith(input: _replace(state.input, lengthFt: v));
    _calculate();
  }

  void onMaterialChanged(PipeMaterial v) {
    state = state.copyWith(input: _replace(state.input, material: v));
    _calculate();
  }

  void onServiceChanged(PipeService v) {
    state = state.copyWith(input: _replace(state.input, service: v));
    _calculate();
  }

  void onMethodChanged(FrictionMethod v) {
    state = state.copyWith(input: _replace(state.input, method: v));
    _calculate();
  }

  void onGlycolChanged(double v) {
    state = state.copyWith(
      input: _replace(state.input, glycolConcentration: v),
    );
    _calculate();
  }

  void addFitting(FittingEntry entry) {
    final newList = [...state.input.fittings, entry];
    state = state.copyWith(input: _replace(state.input, fittings: newList));
    _calculate();
  }

  void removeFitting(int index) {
    final newList = [...state.input.fittings];
    newList.removeAt(index);
    state = state.copyWith(input: _replace(state.input, fittings: newList));
    _calculate();
  }

  void onUnitSystemChanged(UnitSystem unit) {
    final current = state.input;
    if (current.unit == unit) return;

    double newFlow = current.flowRate;
    double newLength = current.lengthFt;

    if (current.unit == UnitSystem.imperial && unit == UnitSystem.metric) {
      newFlow = current.flowRate * HydronicConstants.gpmToM3h;
      newLength = current.lengthFt * HydronicConstants.ftToM;
    } else if (current.unit == UnitSystem.metric &&
        unit == UnitSystem.imperial) {
      newFlow = current.flowRate / HydronicConstants.gpmToM3h;
      newLength = current.flowRate / HydronicConstants.ftToM;
    }

    state = state.copyWith(
      input: PipePressureLossInput(
        flowRate: newFlow,
        diameterIn: current.diameterIn,
        lengthFt: newLength,
        material: current.material,
        service: current.service,
        glycolConcentration: current.glycolConcentration,
        method: current.method,
        fittings: current.fittings,
        unit: unit,
      ),
    );
    _calculate();
  }

  PipePressureLossInput _replace(
    PipePressureLossInput current, {
    double? flowRate,
    double? diameterIn,
    double? lengthFt,
    PipeMaterial? material,
    PipeService? service,
    double? glycolConcentration,
    FrictionMethod? method,
    List<FittingEntry>? fittings,
    UnitSystem? unit,
  }) {
    return PipePressureLossInput(
      flowRate: flowRate ?? current.flowRate,
      diameterIn: diameterIn ?? current.diameterIn,
      lengthFt: lengthFt ?? current.lengthFt,
      material: material ?? current.material,
      service: service ?? current.service,
      glycolConcentration: glycolConcentration ?? current.glycolConcentration,
      method: method ?? current.method,
      fittings: fittings ?? current.fittings,
      unit: unit ?? current.unit,
    );
  }

  void _calculate() {
    state = state.copyWith(status: PipePressureLossStatus.calculating);
    try {
      final result = PipePressureLossEngine.calculate(state.input);
      if (result == null) {
        state = state.copyWith(
          status: PipePressureLossStatus.error,
          errorMessage: 'Dữ liệu đầu vào không hợp lệ.',
        );
        return;
      }
      state = state.copyWith(
        status: PipePressureLossStatus.success,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: PipePressureLossStatus.error,
        errorMessage: 'Lỗi tính toán: $e',
      );
    }
  }
}

final pipePressureLossProvider =
    StateNotifierProvider<PipePressureLossNotifier, PipePressureLossState>((
      ref,
    ) {
      return PipePressureLossNotifier();
    });
