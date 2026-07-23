import 'package:flutter_riverpod/legacy.dart';

import '../../../core/hvac/models/enums.dart';
import '../data/diffuser_catalog.dart';
import '../formulas/diffuser_selection_engine.dart';

enum DiffuserSelectionStatus { idle, calculating, success, error }

class DiffuserSelectionState {
  final DiffuserSelectionInput input;
  final DiffuserSelectionResult? result;
  final DiffuserSelectionStatus status;
  final String? errorMessage;

  const DiffuserSelectionState({
    required this.input,
    this.result,
    this.status = DiffuserSelectionStatus.idle,
    this.errorMessage,
  });

  DiffuserSelectionState copyWith({
    DiffuserSelectionInput? input,
    DiffuserSelectionResult? result,
    DiffuserSelectionStatus? status,
    String? errorMessage,
  }) {
    return DiffuserSelectionState(
      input: input ?? this.input,
      result: result ?? this.result,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DiffuserSelectionNotifier extends StateNotifier<DiffuserSelectionState> {
  DiffuserSelectionNotifier()
    : super(
        DiffuserSelectionState(
          input: const DiffuserSelectionInput(
            totalCfm: 800,
            roomLengthFt: 24,
            roomWidthFt: 16,
            ceilingHeightFt: 9,
            ach: 6,
            diffuserCount: 4,
            throwDistanceFt: 12,
            mountingHeightFt: 9,
            maxNeckVelocityFpm: 800,
            maxNcRating: 35,
            diffuserType: DiffuserType.ceilingSquare,
            unit: UnitSystem.imperial,
            method: DiffuserSizingMethod.byAirflow,
          ),
        ),
      ) {
    _calculate();
  }

  void onMethodChanged(DiffuserSizingMethod method) {
    state = state.copyWith(input: _replaceInput(state.input, method: method));
    _calculate();
  }

  void onUnitSystemChanged(UnitSystem unit) {
    final current = state.input;
    if (current.unit == unit) return;

    double newTotal = current.totalCfm;
    double newLength = current.roomLengthFt;
    double newWidth = current.roomWidthFt;
    double newCeiling = current.ceilingHeightFt;
    double newThrow = current.throwDistanceFt;
    double newMount = current.mountingHeightFt;
    double newMaxNeck = current.maxNeckVelocityFpm;

    if (current.unit == UnitSystem.imperial && unit == UnitSystem.metric) {
      newTotal = current.totalCfm * 1.699;
      newLength = current.roomLengthFt * 0.3048;
      newWidth = current.roomWidthFt * 0.3048;
      newCeiling = current.ceilingHeightFt * 0.3048;
      newThrow = current.throwDistanceFt * 0.3048;
      newMount = current.mountingHeightFt * 0.3048;
      // FPM → m/s: divide by 196.85
      newMaxNeck = current.maxNeckVelocityFpm / 196.85;
    } else if (current.unit == UnitSystem.metric &&
        unit == UnitSystem.imperial) {
      newTotal = current.totalCfm / 1.699;
      newLength = current.roomLengthFt / 0.3048;
      newWidth = current.roomWidthFt / 0.3048;
      newCeiling = current.ceilingHeightFt / 0.3048;
      newThrow = current.throwDistanceFt / 0.3048;
      newMount = current.mountingHeightFt / 0.3048;
      // m/s → FPM: multiply by 196.85
      newMaxNeck = current.maxNeckVelocityFpm * 196.85;
    }

    state = state.copyWith(
      input: DiffuserSelectionInput(
        totalCfm: newTotal,
        roomLengthFt: newLength,
        roomWidthFt: newWidth,
        ceilingHeightFt: newCeiling,
        ach: current.ach,
        diffuserCount: current.diffuserCount,
        throwDistanceFt: newThrow,
        mountingHeightFt: newMount,
        maxNeckVelocityFpm: newMaxNeck,
        maxNcRating: current.maxNcRating,
        diffuserType: current.diffuserType,
        unit: unit,
        method: current.method,
      ),
    );
    _calculate();
  }

  void onDiffuserTypeChanged(DiffuserType type) {
    final def = DiffuserCatalog.get(type);
    state = state.copyWith(
      input: _replaceInput(
        state.input,
        diffuserType: type,
        maxNeckVelocityFpm: def.maxNeckVelocityFpm.toDouble(),
        maxNcRating: def.maxNcRating.toDouble(),
      ),
    );
    _calculate();
  }

  void onTotalCfmChanged(double value) {
    state = state.copyWith(input: _replaceInput(state.input, totalCfm: value));
    _calculate();
  }

  void onRoomLengthChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, roomLengthFt: value),
    );
    _calculate();
  }

  void onRoomWidthChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, roomWidthFt: value),
    );
    _calculate();
  }

  void onCeilingHeightChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, ceilingHeightFt: value),
    );
    _calculate();
  }

  void onAchChanged(double value) {
    state = state.copyWith(input: _replaceInput(state.input, ach: value));
    _calculate();
  }

  void onDiffuserCountChanged(int count) {
    state = state.copyWith(
      input: _replaceInput(state.input, diffuserCount: count),
    );
    _calculate();
  }

  void onThrowDistanceChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, throwDistanceFt: value),
    );
    _calculate();
  }

  void onMountingHeightChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, mountingHeightFt: value),
    );
    _calculate();
  }

  void onMaxNeckVelocityChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, maxNeckVelocityFpm: value),
    );
    _calculate();
  }

  void onMaxNcRatingChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, maxNcRating: value),
    );
    _calculate();
  }

  DiffuserSelectionInput _replaceInput(
    DiffuserSelectionInput current, {
    double? totalCfm,
    double? roomLengthFt,
    double? roomWidthFt,
    double? ceilingHeightFt,
    double? ach,
    int? diffuserCount,
    double? throwDistanceFt,
    double? mountingHeightFt,
    double? maxNeckVelocityFpm,
    double? maxNcRating,
    DiffuserType? diffuserType,
    UnitSystem? unit,
    DiffuserSizingMethod? method,
  }) {
    return DiffuserSelectionInput(
      totalCfm: totalCfm ?? current.totalCfm,
      roomLengthFt: roomLengthFt ?? current.roomLengthFt,
      roomWidthFt: roomWidthFt ?? current.roomWidthFt,
      ceilingHeightFt: ceilingHeightFt ?? current.ceilingHeightFt,
      ach: ach ?? current.ach,
      diffuserCount: diffuserCount ?? current.diffuserCount,
      throwDistanceFt: throwDistanceFt ?? current.throwDistanceFt,
      mountingHeightFt: mountingHeightFt ?? current.mountingHeightFt,
      maxNeckVelocityFpm: maxNeckVelocityFpm ?? current.maxNeckVelocityFpm,
      maxNcRating: maxNcRating ?? current.maxNcRating,
      diffuserType: diffuserType ?? current.diffuserType,
      unit: unit ?? current.unit,
      method: method ?? current.method,
    );
  }

  void _calculate() {
    state = state.copyWith(status: DiffuserSelectionStatus.calculating);
    try {
      final result = DiffuserSelectionEngine.calculate(state.input);
      if (result == null) {
        state = state.copyWith(
          status: DiffuserSelectionStatus.error,
          errorMessage:
              'Vui lòng nhập số lượng diffuser > 0 và thông số hợp lệ.',
        );
        return;
      }
      state = state.copyWith(
        status: DiffuserSelectionStatus.success,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: DiffuserSelectionStatus.error,
        errorMessage: 'Lỗi tính toán: $e',
      );
    }
  }
}

final diffuserSelectionProvider =
    StateNotifierProvider<DiffuserSelectionNotifier, DiffuserSelectionState>((
      ref,
    ) {
      return DiffuserSelectionNotifier();
    });
