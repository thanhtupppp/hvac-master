import 'package:flutter_riverpod/legacy.dart';

import '../../../core/hvac/models/enums.dart';
import '../formulas/fan_selection_engine.dart';

enum FanSelectionStatus { idle, calculating, success, error }

class FanSelectionState {
  final FanSelectionInput input;
  final FanOperatingPoint? result;
  final FanSelectionStatus status;
  final String? errorMessage;

  const FanSelectionState({
    required this.input,
    this.result,
    this.status = FanSelectionStatus.idle,
    this.errorMessage,
  });

  FanSelectionState copyWith({
    FanSelectionInput? input,
    FanOperatingPoint? result,
    FanSelectionStatus? status,
    String? errorMessage,
  }) {
    return FanSelectionState(
      input: input ?? this.input,
      result: result ?? this.result,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FanSelectionNotifier extends StateNotifier<FanSelectionState> {
  FanSelectionNotifier()
    : super(
        FanSelectionState(
          input: const FanSelectionInput(
            flowRate: 5000,
            staticPressure: 1.5,
            unit: UnitSystem.imperial,
            fanType: FanType.centrifugalBackward,
            driveType: DriveType.belt,
          ),
        ),
      ) {
    _calculate();
  }

  void onFlowRateChanged(double value) {
    state = state.copyWith(input: _replaceInput(state.input, flowRate: value));
    _calculate();
  }

  void onStaticPressureChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, staticPressure: value),
    );
    _calculate();
  }

  void onUnitSystemChanged(UnitSystem unit) {
    final current = state.input;
    if (current.unit == unit) return;

    double newFlowRate = current.flowRate;
    double newPressure = current.staticPressure;

    if (current.unit == UnitSystem.imperial && unit == UnitSystem.metric) {
      newFlowRate = current.flowRate * 1.699; // CFM → m³/h
      newPressure = current.staticPressure * 248.84; // in.wg → Pa
    } else if (current.unit == UnitSystem.metric &&
        unit == UnitSystem.imperial) {
      newFlowRate = current.flowRate / 1.699;
      newPressure = current.staticPressure / 248.84;
    }

    state = state.copyWith(
      input: FanSelectionInput(
        flowRate: newFlowRate,
        staticPressure: newPressure,
        unit: unit,
        fanType: current.fanType,
        driveType: current.driveType,
        density: current.density,
        altitude: current.altitude,
        efficiencyOverride: current.efficiencyOverride,
        motorEfficiency: current.motorEfficiency,
        safetyFactor: current.safetyFactor,
      ),
    );
    _calculate();
  }

  void onFanTypeChanged(FanType fanType) {
    state = state.copyWith(input: _replaceInput(state.input, fanType: fanType));
    _calculate();
  }

  void onDriveTypeChanged(DriveType driveType) {
    state = state.copyWith(
      input: _replaceInput(state.input, driveType: driveType),
    );
    _calculate();
  }

  void onAltitudeChanged(double altitude) {
    // Air density at altitude (ISA model, simplified)
    // ρ = ρ₀ × (1 - L×h/T₀)^(g/(L×R) - 1)
    // Simplified: ρ ≈ 1.225 × exp(-h/8500)
    final density = 1.225 * _expApprox(-altitude / 8500);
    state = state.copyWith(
      input: _replaceInput(
        state.input,
        altitude: altitude,
        density: density.clamp(0.4, 1.5),
      ),
    );
    _calculate();
  }

  void onEfficiencyOverrideChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, efficiencyOverride: value),
    );
    _calculate();
  }

  void onMotorEfficiencyChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, motorEfficiency: value),
    );
    _calculate();
  }

  void onSafetyFactorChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, safetyFactor: value),
    );
    _calculate();
  }

  double _expApprox(double x) {
    // Taylor series approximation for small x
    if (x.abs() < 0.001) return 1.0 + x;
    return _expStd(x);
  }

  double _expStd(double x) {
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i < 50; i++) {
      term *= x / i;
      result += term;
      if (term.abs() < 1e-15) break;
    }
    return result;
  }

  FanSelectionInput _replaceInput(
    FanSelectionInput current, {
    double? flowRate,
    double? staticPressure,
    UnitSystem? unit,
    FanType? fanType,
    DriveType? driveType,
    double? density,
    double? altitude,
    double? efficiencyOverride,
    double? motorEfficiency,
    double? safetyFactor,
  }) {
    return FanSelectionInput(
      flowRate: flowRate ?? current.flowRate,
      staticPressure: staticPressure ?? current.staticPressure,
      unit: unit ?? current.unit,
      fanType: fanType ?? current.fanType,
      driveType: driveType ?? current.driveType,
      density: density ?? current.density,
      altitude: altitude ?? current.altitude,
      efficiencyOverride: efficiencyOverride ?? current.efficiencyOverride,
      motorEfficiency: motorEfficiency ?? current.motorEfficiency,
      safetyFactor: safetyFactor ?? current.safetyFactor,
    );
  }

  void _calculate() {
    state = state.copyWith(status: FanSelectionStatus.calculating);

    try {
      final result = FanSelectionEngine.calculate(state.input);
      if (result == null) {
        state = state.copyWith(
          status: FanSelectionStatus.error,
          errorMessage: 'Vui lòng nhập lưu lượng và cột áp.',
        );
        return;
      }
      state = state.copyWith(
        status: FanSelectionStatus.success,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: FanSelectionStatus.error,
        errorMessage: 'Lỗi tính toán: $e',
      );
    }
  }
}

final fanSelectionProvider =
    StateNotifierProvider<FanSelectionNotifier, FanSelectionState>((ref) {
      return FanSelectionNotifier();
    });
