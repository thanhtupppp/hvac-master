import 'package:flutter_riverpod/legacy.dart';

import '../../../core/hvac/models/enums.dart';
import '../constants/hydronic_constants.dart';
import '../formulas/pipe_sizer_engine.dart';

enum PipeSizerStatus { idle, calculating, success, error }

class PipeSizerState {
  final PipeSizerInput input;
  final PipeSizerResult? result;
  final PipeSizerStatus status;
  final String? errorMessage;

  const PipeSizerState({
    required this.input,
    this.result,
    this.status = PipeSizerStatus.idle,
    this.errorMessage,
  });

  PipeSizerState copyWith({
    PipeSizerInput? input,
    PipeSizerResult? result,
    PipeSizerStatus? status,
    String? errorMessage,
  }) {
    return PipeSizerState(
      input: input ?? this.input,
      result: result ?? this.result,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PipeSizerNotifier extends StateNotifier<PipeSizerState> {
  PipeSizerNotifier()
    : super(
        const PipeSizerState(
          input: PipeSizerInput(
            flowRate: 50, // GPM
            service: PipeService.chilledWater,
            material: PipeMaterial.steelBlack,
            schedule: PipeSchedule.schedule40,
            unit: UnitSystem.imperial,
          ),
        ),
      ) {
    _calculate();
  }

  void onFlowRateChanged(double value) {
    state = state.copyWith(input: _replaceInput(state.input, flowRate: value));
    _calculate();
  }

  void onServiceChanged(PipeService service) {
    state = state.copyWith(input: _replaceInput(state.input, service: service));
    _calculate();
  }

  void onMaterialChanged(PipeMaterial material) {
    state = state.copyWith(
      input: _replaceInput(state.input, material: material),
    );
    _calculate();
  }

  void onScheduleChanged(PipeSchedule schedule) {
    state = state.copyWith(
      input: _replaceInput(state.input, schedule: schedule),
    );
    _calculate();
  }

  void onMaxVelocityChanged(double? value) {
    state = state.copyWith(
      input: _replaceInput(state.input, maxVelocity: value),
    );
    _calculate();
  }

  void onUnitSystemChanged(UnitSystem unit) {
    final current = state.input;
    if (current.unit == unit) return;

    double newFlowRate = current.flowRate;
    if (current.unit == UnitSystem.imperial && unit == UnitSystem.metric) {
      newFlowRate = current.flowRate * HydronicConstants.gpmToM3h;
    } else if (current.unit == UnitSystem.metric &&
        unit == UnitSystem.imperial) {
      newFlowRate = current.flowRate / HydronicConstants.gpmToM3h;
    }

    state = state.copyWith(
      input: PipeSizerInput(
        flowRate: newFlowRate,
        service: current.service,
        material: current.material,
        schedule: current.schedule,
        maxVelocity: null,
        minVelocity: null,
        unit: unit,
      ),
    );
    _calculate();
  }

  PipeSizerInput _replaceInput(
    PipeSizerInput current, {
    double? flowRate,
    PipeService? service,
    PipeMaterial? material,
    PipeSchedule? schedule,
    double? maxVelocity,
    double? minVelocity,
    UnitSystem? unit,
  }) {
    return PipeSizerInput(
      flowRate: flowRate ?? current.flowRate,
      service: service ?? current.service,
      material: material ?? current.material,
      schedule: schedule ?? current.schedule,
      maxVelocity: maxVelocity,
      minVelocity: minVelocity,
      unit: unit ?? current.unit,
    );
  }

  void _calculate() {
    state = state.copyWith(status: PipeSizerStatus.calculating);
    try {
      final result = PipeSizerEngine.calculate(state.input);
      if (result == null) {
        state = state.copyWith(
          status: PipeSizerStatus.error,
          errorMessage: 'Lưu lượng phải lớn hơn 0.',
        );
        return;
      }
      state = state.copyWith(status: PipeSizerStatus.success, result: result);
    } catch (e) {
      state = state.copyWith(
        status: PipeSizerStatus.error,
        errorMessage: 'Lỗi tính toán: $e',
      );
    }
  }
}

final pipeSizerProvider =
    StateNotifierProvider<PipeSizerNotifier, PipeSizerState>((ref) {
      return PipeSizerNotifier();
    });
