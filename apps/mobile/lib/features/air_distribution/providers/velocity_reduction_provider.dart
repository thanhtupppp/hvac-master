import 'package:flutter_riverpod/legacy.dart';

import '../../../core/hvac/models/enums.dart';
import '../constants/air_distribution_constants.dart';
import '../formulas/velocity_reduction_engine.dart';

enum VelocityReductionStatus { idle, calculating, success, error }

class VelocityReductionState {
  final VelocityReductionInput input;
  final VelocityReductionResult? result;
  final VelocityReductionStatus status;
  final String? errorMessage;

  const VelocityReductionState({
    required this.input,
    this.result,
    this.status = VelocityReductionStatus.idle,
    this.errorMessage,
  });

  VelocityReductionState copyWith({
    VelocityReductionInput? input,
    VelocityReductionResult? result,
    VelocityReductionStatus? status,
    String? errorMessage,
  }) {
    return VelocityReductionState(
      input: input ?? this.input,
      result: result ?? this.result,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class VelocityReductionNotifier extends StateNotifier<VelocityReductionState> {
  VelocityReductionNotifier()
    : super(
        VelocityReductionState(
          input: VelocityReductionInput(
            airflowCfm: 8000,
            initialVelocityFpm: 1600,
            numberOfSections: 4,
            reductionRatio: 0.8,
            lengthFt: 30,
            ductType: DuctType.supplyMain,
            material: DuctMaterial.galvanized,
            shape: DuctShape.round,
            unit: UnitSystem.imperial,
            maxFrictionRateInWg100ft: 0.20,
          ),
        ),
      ) {
    _calculate();
  }

  void onUnitSystemChanged(UnitSystem unit) {
    final current = state.input;
    if (current.unit == unit) return;

    double newFlow = current.airflowCfm;
    double newVel = current.initialVelocityFpm;
    double newLength = current.lengthFt;
    double newMaxFric = current.maxFrictionRateInWg100ft;

    if (current.unit == UnitSystem.imperial && unit == UnitSystem.metric) {
      newFlow = current.airflowCfm * 1.699;
      // FPM → m/s: divide by 196.85
      newVel = current.initialVelocityFpm / 196.85;
      newLength = current.lengthFt * 0.3048;
      // in.wg/100ft → Pa/m: multiply by 8.16
      newMaxFric =
          current.maxFrictionRateInWg100ft *
          AirDistributionConstants.inWg100ftToPaPerM;
    } else if (current.unit == UnitSystem.metric &&
        unit == UnitSystem.imperial) {
      newFlow = current.airflowCfm / 1.699;
      // m/s → FPM: multiply by 196.85
      newVel = current.initialVelocityFpm * 196.85;
      newLength = current.lengthFt / 0.3048;
      // Pa/m → in.wg/100ft: multiply by 0.1226
      newMaxFric =
          current.maxFrictionRateInWg100ft *
          AirDistributionConstants.paPerMToInWg100ft;
    }

    state = state.copyWith(
      input: VelocityReductionInput(
        airflowCfm: newFlow,
        initialVelocityFpm: newVel,
        numberOfSections: current.numberOfSections,
        reductionRatio: current.reductionRatio,
        lengthFt: newLength,
        ductType: current.ductType,
        material: current.material,
        shape: current.shape,
        unit: unit,
        maxFrictionRateInWg100ft: newMaxFric,
        aspectRatio: current.aspectRatio,
      ),
    );
    _calculate();
  }

  void onShapeChanged(DuctShape shape) {
    state = state.copyWith(input: _replaceInput(state.input, shape: shape));
    _calculate();
  }

  void onAirflowChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, airflowCfm: value),
    );
    _calculate();
  }

  void onInitialVelocityChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, initialVelocityFpm: value),
    );
    _calculate();
  }

  void onNumberOfSectionsChanged(int count) {
    if (count < 1) count = 1;
    if (count > 10) count = 10;
    state = state.copyWith(
      input: _replaceInput(state.input, numberOfSections: count),
    );
    _calculate();
  }

  void onReductionRatioChanged(double value) {
    if (value < 0.3) value = 0.3;
    if (value > 0.95) value = 0.95;
    state = state.copyWith(
      input: _replaceInput(state.input, reductionRatio: value),
    );
    _calculate();
  }

  void onLengthChanged(double value) {
    state = state.copyWith(input: _replaceInput(state.input, lengthFt: value));
    _calculate();
  }

  void onDuctTypeChanged(DuctType type) {
    final limits = AirDistributionConstants.ductVelocityLimits[type];
    if (limits == null) return;
    state = state.copyWith(
      input: _replaceInput(
        state.input,
        ductType: type,
        initialVelocityFpm: limits.max.toDouble(),
      ),
    );
    _calculate();
  }

  void onMaterialChanged(DuctMaterial material) {
    state = state.copyWith(
      input: _replaceInput(state.input, material: material),
    );
    _calculate();
  }

  void onMaxFrictionChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, maxFrictionRateInWg100ft: value),
    );
    _calculate();
  }

  VelocityReductionInput _replaceInput(
    VelocityReductionInput current, {
    double? airflowCfm,
    double? initialVelocityFpm,
    int? numberOfSections,
    double? reductionRatio,
    double? lengthFt,
    DuctType? ductType,
    DuctMaterial? material,
    DuctShape? shape,
    UnitSystem? unit,
    double? maxFrictionRateInWg100ft,
    double? aspectRatio,
  }) {
    return VelocityReductionInput(
      airflowCfm: airflowCfm ?? current.airflowCfm,
      initialVelocityFpm: initialVelocityFpm ?? current.initialVelocityFpm,
      numberOfSections: numberOfSections ?? current.numberOfSections,
      reductionRatio: reductionRatio ?? current.reductionRatio,
      lengthFt: lengthFt ?? current.lengthFt,
      ductType: ductType ?? current.ductType,
      material: material ?? current.material,
      shape: shape ?? current.shape,
      unit: unit ?? current.unit,
      maxFrictionRateInWg100ft:
          maxFrictionRateInWg100ft ?? current.maxFrictionRateInWg100ft,
      aspectRatio: aspectRatio ?? current.aspectRatio,
    );
  }

  void _calculate() {
    state = state.copyWith(status: VelocityReductionStatus.calculating);
    try {
      final result = VelocityReductionEngine.calculate(state.input);
      if (result == null) {
        state = state.copyWith(
          status: VelocityReductionStatus.error,
          errorMessage:
              'Vui lòng kiểm tra lưu lượng, velocity, số section và reduction ratio.',
        );
        return;
      }
      state = state.copyWith(
        status: VelocityReductionStatus.success,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: VelocityReductionStatus.error,
        errorMessage: 'Lỗi tính toán: $e',
      );
    }
  }
}

final velocityReductionProvider =
    StateNotifierProvider<VelocityReductionNotifier, VelocityReductionState>((
      ref,
    ) {
      return VelocityReductionNotifier();
    });
