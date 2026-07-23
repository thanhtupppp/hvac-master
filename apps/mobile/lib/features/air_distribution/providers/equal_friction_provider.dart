import 'package:flutter_riverpod/legacy.dart';

import '../../../core/hvac/models/enums.dart';
import '../constants/air_distribution_constants.dart';
import '../formulas/equal_friction_engine.dart';

enum EqualFrictionStatus { idle, calculating, success, error }

class EqualFrictionState {
  final EqualFrictionInput input;
  final EqualFrictionResult? result;
  final EqualFrictionStatus status;
  final String? errorMessage;

  const EqualFrictionState({
    required this.input,
    this.result,
    this.status = EqualFrictionStatus.idle,
    this.errorMessage,
  });

  EqualFrictionState copyWith({
    EqualFrictionInput? input,
    EqualFrictionResult? result,
    EqualFrictionStatus? status,
    String? errorMessage,
  }) {
    return EqualFrictionState(
      input: input ?? this.input,
      result: result ?? this.result,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class EqualFrictionNotifier extends StateNotifier<EqualFrictionState> {
  EqualFrictionNotifier()
    : super(
        EqualFrictionState(
          input: EqualFrictionInput(
            airflowCfm: 2000,
            frictionRateInWg100ft:
                AirDistributionConstants.frictionRecommendedInWg100ft,
            lengthFt: 50,
            ductType: DuctType.supplyMain,
            material: DuctMaterial.galvanized,
            shape: DuctShape.round,
            unit: UnitSystem.imperial,
            maxVelocityFpm: 1300,
          ),
        ),
      ) {
    _calculate();
  }

  void onUnitSystemChanged(UnitSystem unit) {
    final current = state.input;
    if (current.unit == unit) return;

    double newFlow = current.airflowCfm;
    double newLength = current.lengthFt;
    double newMaxVel = current.maxVelocityFpm;
    double newFriction = current.frictionRateInWg100ft;

    if (current.unit == UnitSystem.imperial && unit == UnitSystem.metric) {
      newFlow = current.airflowCfm * 1.699;
      newLength = current.lengthFt * 0.3048;
      // FPM → m/s: divide by 196.85 (NOT × 0.3048 × 60 which yields ×18.288)
      newMaxVel = current.maxVelocityFpm / 196.85;
      // in.wg/100ft → Pa/m: multiply by 8.16
      newFriction =
          current.frictionRateInWg100ft *
          AirDistributionConstants.inWg100ftToPaPerM;
    } else if (current.unit == UnitSystem.metric &&
        unit == UnitSystem.imperial) {
      newFlow = current.airflowCfm / 1.699;
      newLength = current.lengthFt / 0.3048;
      // m/s → FPM: multiply by 196.85
      newMaxVel = current.maxVelocityFpm * 196.85;
      // Pa/m → in.wg/100ft: multiply by 0.1226
      newFriction =
          current.frictionRateInWg100ft *
          AirDistributionConstants.paPerMToInWg100ft;
    }

    state = state.copyWith(
      input: EqualFrictionInput(
        airflowCfm: newFlow,
        frictionRateInWg100ft: newFriction,
        lengthFt: newLength,
        ductType: current.ductType,
        material: current.material,
        shape: current.shape,
        unit: unit,
        maxVelocityFpm: newMaxVel,
        fixedAspectRatio: current.fixedAspectRatio,
        fixedWidthIn: current.fixedWidthIn,
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

  void onFrictionRateChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(
        state.input,
        frictionRateInWg100ft: value.clamp(0.01, 0.50),
      ),
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
        maxVelocityFpm: limits.max.toDouble(),
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

  void onMaxVelocityChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, maxVelocityFpm: value),
    );
    _calculate();
  }

  EqualFrictionInput _replaceInput(
    EqualFrictionInput current, {
    double? airflowCfm,
    double? frictionRateInWg100ft,
    double? lengthFt,
    DuctType? ductType,
    DuctMaterial? material,
    DuctShape? shape,
    UnitSystem? unit,
    double? maxVelocityFpm,
    int? fixedAspectRatio,
    int? fixedWidthIn,
  }) {
    return EqualFrictionInput(
      airflowCfm: airflowCfm ?? current.airflowCfm,
      frictionRateInWg100ft:
          frictionRateInWg100ft ?? current.frictionRateInWg100ft,
      lengthFt: lengthFt ?? current.lengthFt,
      ductType: ductType ?? current.ductType,
      material: material ?? current.material,
      shape: shape ?? current.shape,
      unit: unit ?? current.unit,
      maxVelocityFpm: maxVelocityFpm ?? current.maxVelocityFpm,
      fixedAspectRatio: fixedAspectRatio ?? current.fixedAspectRatio,
      fixedWidthIn: fixedWidthIn ?? current.fixedWidthIn,
    );
  }

  void _calculate() {
    state = state.copyWith(status: EqualFrictionStatus.calculating);
    try {
      final result = EqualFrictionEngine.calculate(state.input);
      if (!result.hasSelection && result.sizeWarning == null) {
        state = state.copyWith(
          status: EqualFrictionStatus.error,
          errorMessage:
              'Vui lòng kiểm tra lưu lượng, friction rate và độ dài ống.',
        );
        return;
      }
      state = state.copyWith(
        status: EqualFrictionStatus.success,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: EqualFrictionStatus.error,
        errorMessage: 'Lỗi tính toán: $e',
      );
    }
  }
}

final equalFrictionProvider =
    StateNotifierProvider<EqualFrictionNotifier, EqualFrictionState>((ref) {
      return EqualFrictionNotifier();
    });
