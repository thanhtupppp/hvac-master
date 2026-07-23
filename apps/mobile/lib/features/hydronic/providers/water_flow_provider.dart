import 'package:flutter_riverpod/legacy.dart';

import '../../../core/hvac/models/enums.dart';
import '../constants/hydronic_constants.dart';
import '../formulas/water_flow_engine.dart';

enum WaterFlowStatus { idle, calculating, success, error }

class WaterFlowState {
  final WaterFlowInput input;
  final WaterFlowResult? result;
  final WaterFlowStatus status;
  final String? errorMessage;

  const WaterFlowState({
    required this.input,
    this.result,
    this.status = WaterFlowStatus.idle,
    this.errorMessage,
  });

  WaterFlowState copyWith({
    WaterFlowInput? input,
    WaterFlowResult? result,
    WaterFlowStatus? status,
    String? errorMessage,
  }) {
    return WaterFlowState(
      input: input ?? this.input,
      result: result ?? this.result,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class WaterFlowNotifier extends StateNotifier<WaterFlowState> {
  WaterFlowNotifier()
      : super(
          WaterFlowState(
            input: const WaterFlowInput(
              flowRate: 50,    // GPM default
              diameter: 2.0,  // 2" default
              material: PipeMaterial.steelBlack,
              service: PipeService.chilledWater,
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

  void onDiameterChanged(double value) {
    state = state.copyWith(input: _replaceInput(state.input, diameter: value));
    _calculate();
  }

  void onMaterialChanged(PipeMaterial material) {
    state = state.copyWith(input: _replaceInput(state.input, material: material));
    _calculate();
  }

  void onServiceChanged(PipeService service) {
    state = state.copyWith(input: _replaceInput(state.input, service: service));
    _calculate();
  }

  void onUnitSystemChanged(UnitSystem unit) {
    final current = state.input;
    if (current.unit == unit) return;

    double newFlowRate = current.flowRate;
    double newDiameter = current.diameter;

    if (current.unit == UnitSystem.imperial && unit == UnitSystem.metric) {
      newFlowRate = current.flowRate * HydronicConstants.gpmToM3h; // GPM → m³/h
      newDiameter = current.diameter * HydronicConstants.inchToMm;   // in → mm
    } else if (current.unit == UnitSystem.metric && unit == UnitSystem.imperial) {
      newFlowRate = current.flowRate / HydronicConstants.gpmToM3h;
      newDiameter = current.diameter / HydronicConstants.inchToMm;
    }

    state = state.copyWith(
      input: WaterFlowInput(
        flowRate: newFlowRate,
        diameter: newDiameter,
        material: current.material,
        service: current.service,
        unit: unit,
      ),
    );
    _calculate();
  }

  WaterFlowInput _replaceInput(
    WaterFlowInput current, {
    double? flowRate,
    double? diameter,
    PipeMaterial? material,
    PipeService? service,
    UnitSystem? unit,
  }) {
    return WaterFlowInput(
      flowRate: flowRate ?? current.flowRate,
      diameter: diameter ?? current.diameter,
      material: material ?? current.material,
      service: service ?? current.service,
      unit: unit ?? current.unit,
    );
  }

  void _calculate() {
    state = state.copyWith(status: WaterFlowStatus.calculating);

    try {
      final result = WaterFlowEngine.calculate(state.input);
      if (result == null) {
        state = state.copyWith(
          status: WaterFlowStatus.error,
          errorMessage: 'Lưu lượng và đường kính phải lớn hơn 0.',
        );
        return;
      }
      state = state.copyWith(
        status: WaterFlowStatus.success,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: WaterFlowStatus.error,
        errorMessage: 'Lỗi tính toán: $e',
      );
    }
  }
}

final waterFlowProvider =
    StateNotifierProvider<WaterFlowNotifier, WaterFlowState>((ref) {
  return WaterFlowNotifier();
});
