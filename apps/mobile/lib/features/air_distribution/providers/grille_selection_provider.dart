import 'package:flutter_riverpod/legacy.dart';

import '../../../core/hvac/models/enums.dart';
import '../formulas/grille_selection_engine.dart';

enum GrilleSelectionStatus { idle, calculating, success, error }

class GrilleSelectionState {
  final GrilleSelectionInput input;
  final GrilleSelectionResult? result;
  final GrilleSelectionStatus status;
  final String? errorMessage;

  const GrilleSelectionState({
    required this.input,
    this.result,
    this.status = GrilleSelectionStatus.idle,
    this.errorMessage,
  });

  GrilleSelectionState copyWith({
    GrilleSelectionInput? input,
    GrilleSelectionResult? result,
    GrilleSelectionStatus? status,
    String? errorMessage,
  }) {
    return GrilleSelectionState(
      input: input ?? this.input,
      result: result ?? this.result,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class GrilleSelectionNotifier extends StateNotifier<GrilleSelectionState> {
  GrilleSelectionNotifier()
    : super(
        GrilleSelectionState(
          input: const GrilleSelectionInput(
            totalCfm: 800,
            roomAreaSqFt: 384,
            ceilingHeightFt: 9,
            grilleCount: 2,
            grilleType: GrilleType.returnGrille,
            application: GrilleApplication.returnAir,
            unit: UnitSystem.imperial,
            byRoomArea: false,
            ach: 6,
            maxFaceVelocityFpm: 300,
            maxNcRating: 30,
            mountingHeightFt: 9,
          ),
        ),
      ) {
    _calculate();
  }

  void onUnitSystemChanged(UnitSystem unit) {
    final current = state.input;
    if (current.unit == unit) return;

    double newTotal = current.totalCfm;
    double newArea = current.roomAreaSqFt;
    double newCeiling = current.ceilingHeightFt;
    double newMount = current.mountingHeightFt;
    double newFaceVel = current.maxFaceVelocityFpm;

    if (current.unit == UnitSystem.imperial && unit == UnitSystem.metric) {
      newTotal = current.totalCfm * 1.699;
      newArea = current.roomAreaSqFt * 0.092903;
      newCeiling = current.ceilingHeightFt * 0.3048;
      newMount = current.mountingHeightFt * 0.3048;
      // FPM → m/s: divide by 196.85
      newFaceVel = current.maxFaceVelocityFpm / 196.85;
    } else if (current.unit == UnitSystem.metric &&
        unit == UnitSystem.imperial) {
      newTotal = current.totalCfm / 1.699;
      newArea = current.roomAreaSqFt / 0.092903;
      newCeiling = current.ceilingHeightFt / 0.3048;
      newMount = current.mountingHeightFt / 0.3048;
      // m/s → FPM: multiply by 196.85
      newFaceVel = current.maxFaceVelocityFpm * 196.85;
    }

    state = state.copyWith(
      input: GrilleSelectionInput(
        totalCfm: newTotal,
        roomAreaSqFt: newArea,
        ceilingHeightFt: newCeiling,
        grilleCount: current.grilleCount,
        grilleType: current.grilleType,
        application: current.application,
        unit: unit,
        byRoomArea: current.byRoomArea,
        ach: current.ach,
        maxFaceVelocityFpm: newFaceVel,
        maxNcRating: current.maxNcRating,
        mountingHeightFt: newMount,
      ),
    );
    _calculate();
  }

  void onApplicationChanged(GrilleApplication app) {
    state = state.copyWith(
      input: _replaceInput(
        state.input,
        application: app,
        maxFaceVelocityFpm: GrilleSelectionEngine.getDefaultFaceVelocity(app),
        maxNcRating: GrilleSelectionEngine.getDefaultNc(app),
      ),
    );
    _calculate();
  }

  void onGrilleTypeChanged(GrilleType type) {
    state = state.copyWith(input: _replaceInput(state.input, grilleType: type));
    _calculate();
  }

  void onTotalCfmChanged(double value) {
    state = state.copyWith(input: _replaceInput(state.input, totalCfm: value));
    _calculate();
  }

  void onRoomAreaChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, roomAreaSqFt: value),
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

  void onGrilleCountChanged(int count) {
    state = state.copyWith(
      input: _replaceInput(state.input, grilleCount: count),
    );
    _calculate();
  }

  void onByRoomAreaChanged(bool byRoomArea) {
    state = state.copyWith(
      input: _replaceInput(state.input, byRoomArea: byRoomArea),
    );
    _calculate();
  }

  void onMaxFaceVelocityChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, maxFaceVelocityFpm: value),
    );
    _calculate();
  }

  void onMaxNcChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, maxNcRating: value),
    );
    _calculate();
  }

  GrilleSelectionInput _replaceInput(
    GrilleSelectionInput current, {
    double? totalCfm,
    double? roomAreaSqFt,
    double? ceilingHeightFt,
    int? grilleCount,
    GrilleType? grilleType,
    GrilleApplication? application,
    UnitSystem? unit,
    bool? byRoomArea,
    double? ach,
    double? maxFaceVelocityFpm,
    double? maxNcRating,
    double? mountingHeightFt,
  }) {
    return GrilleSelectionInput(
      totalCfm: totalCfm ?? current.totalCfm,
      roomAreaSqFt: roomAreaSqFt ?? current.roomAreaSqFt,
      ceilingHeightFt: ceilingHeightFt ?? current.ceilingHeightFt,
      grilleCount: grilleCount ?? current.grilleCount,
      grilleType: grilleType ?? current.grilleType,
      application: application ?? current.application,
      unit: unit ?? current.unit,
      byRoomArea: byRoomArea ?? current.byRoomArea,
      ach: ach ?? current.ach,
      maxFaceVelocityFpm: maxFaceVelocityFpm ?? current.maxFaceVelocityFpm,
      maxNcRating: maxNcRating ?? current.maxNcRating,
      mountingHeightFt: mountingHeightFt ?? current.mountingHeightFt,
    );
  }

  void _calculate() {
    state = state.copyWith(status: GrilleSelectionStatus.calculating);
    try {
      final result = GrilleSelectionEngine.calculate(state.input);
      if (result == null) {
        state = state.copyWith(
          status: GrilleSelectionStatus.error,
          errorMessage: 'Vui lòng nhập số lượng grille > 0 và thông số hợp lệ.',
        );
        return;
      }
      state = state.copyWith(
        status: GrilleSelectionStatus.success,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: GrilleSelectionStatus.error,
        errorMessage: 'Lỗi tính toán: $e',
      );
    }
  }
}

final grilleSelectionProvider =
    StateNotifierProvider<GrilleSelectionNotifier, GrilleSelectionState>((ref) {
      return GrilleSelectionNotifier();
    });
