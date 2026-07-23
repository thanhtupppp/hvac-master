import 'package:flutter_riverpod/legacy.dart';

import '../../../core/hvac/models/enums.dart';
import '../data/vav_box_catalog.dart';
import '../formulas/vav_box_engine.dart';

enum VavSizingStatus { idle, calculating, success, error }

class VavSizingState {
  final VavBoxSizingInput input;
  final VavBoxSizingResult? result;
  final VavSizingStatus status;
  final String? errorMessage;

  const VavSizingState({
    required this.input,
    this.result,
    this.status = VavSizingStatus.idle,
    this.errorMessage,
  });

  VavSizingState copyWith({
    VavBoxSizingInput? input,
    VavBoxSizingResult? result,
    VavSizingStatus? status,
    String? errorMessage,
  }) {
    return VavSizingState(
      input: input ?? this.input,
      result: result ?? this.result,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class VavSizingNotifier extends StateNotifier<VavSizingState> {
  VavSizingNotifier()
    : super(
        VavSizingState(
          input: const VavBoxSizingInput(
            coolingLoadBtuHr: 18000,
            heatingLoadBtuHr: 8000,
            supplyAirTempF: 55,
            roomTempF: 75,
            roomTempFHeat: 70,
            minAirflowRatio: 0.30,
            primaryAirTempF: 55,
            boxType: VavBoxType.singleDuctWithReheat,
            unit: UnitSystem.imperial,
            method: SizingMethod.byCoolingLoad,
            directAirflowCfm: 0,
          ),
        ),
      ) {
    _calculate();
  }

  void onMethodChanged(SizingMethod method) {
    state = state.copyWith(input: _replaceInput(state.input, method: method));
    _calculate();
  }

  void onBoxTypeChanged(VavBoxType boxType) {
    state = state.copyWith(input: _replaceInput(state.input, boxType: boxType));
    _calculate();
  }

  void onUnitSystemChanged(UnitSystem unit) {
    final current = state.input;
    if (current.unit == unit) return;

    double newCooling = current.coolingLoadBtuHr;
    double newHeating = current.heatingLoadBtuHr;
    double newSat = current.supplyAirTempF;
    double newRoom = current.roomTempF;
    double newRoomHeat = current.roomTempFHeat;
    double newPrimary = current.primaryAirTempF;
    double newAirflow = current.directAirflowCfm;

    if (current.unit == UnitSystem.imperial && unit == UnitSystem.metric) {
      newCooling = current.coolingLoadBtuHr * 0.293071;
      newHeating = current.heatingLoadBtuHr * 0.293071;
      newSat = (current.supplyAirTempF - 32) * 5 / 9;
      newRoom = (current.roomTempF - 32) * 5 / 9;
      newRoomHeat = (current.roomTempFHeat - 32) * 5 / 9;
      newPrimary = (current.primaryAirTempF - 32) * 5 / 9;
      newAirflow = current.directAirflowCfm * 1.699;
    } else if (current.unit == UnitSystem.metric &&
        unit == UnitSystem.imperial) {
      newCooling = current.coolingLoadBtuHr / 0.293071;
      newHeating = current.heatingLoadBtuHr / 0.293071;
      newSat = current.supplyAirTempF * 9 / 5 + 32;
      newRoom = current.roomTempF * 9 / 5 + 32;
      newRoomHeat = current.roomTempFHeat * 9 / 5 + 32;
      newPrimary = current.primaryAirTempF * 9 / 5 + 32;
      newAirflow = current.directAirflowCfm / 1.699;
    }

    state = state.copyWith(
      input: VavBoxSizingInput(
        coolingLoadBtuHr: newCooling,
        heatingLoadBtuHr: newHeating,
        supplyAirTempF: newSat,
        roomTempF: newRoom,
        roomTempFHeat: newRoomHeat,
        minAirflowRatio: current.minAirflowRatio,
        primaryAirTempF: newPrimary,
        boxType: current.boxType,
        unit: unit,
        method: current.method,
        directAirflowCfm: newAirflow,
      ),
    );
    _calculate();
  }

  void onCoolingLoadChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, coolingLoadBtuHr: value),
    );
    _calculate();
  }

  void onHeatingLoadChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, heatingLoadBtuHr: value),
    );
    _calculate();
  }

  void onSupplyAirTempChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, supplyAirTempF: value),
    );
    _calculate();
  }

  void onRoomTempChanged(double value) {
    state = state.copyWith(input: _replaceInput(state.input, roomTempF: value));
    _calculate();
  }

  void onRoomTempHeatChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, roomTempFHeat: value),
    );
    _calculate();
  }

  void onMinAirflowRatioChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(
        state.input,
        minAirflowRatio: value.clamp(0.10, 0.50),
      ),
    );
    _calculate();
  }

  void onPrimaryAirTempChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, primaryAirTempF: value),
    );
    _calculate();
  }

  void onDirectAirflowChanged(double value) {
    state = state.copyWith(
      input: _replaceInput(state.input, directAirflowCfm: value),
    );
    _calculate();
  }

  VavBoxSizingInput _replaceInput(
    VavBoxSizingInput current, {
    double? coolingLoadBtuHr,
    double? heatingLoadBtuHr,
    double? supplyAirTempF,
    double? roomTempF,
    double? roomTempFHeat,
    double? minAirflowRatio,
    double? primaryAirTempF,
    VavBoxType? boxType,
    UnitSystem? unit,
    SizingMethod? method,
    double? directAirflowCfm,
  }) {
    return VavBoxSizingInput(
      coolingLoadBtuHr: coolingLoadBtuHr ?? current.coolingLoadBtuHr,
      heatingLoadBtuHr: heatingLoadBtuHr ?? current.heatingLoadBtuHr,
      supplyAirTempF: supplyAirTempF ?? current.supplyAirTempF,
      roomTempF: roomTempF ?? current.roomTempF,
      roomTempFHeat: roomTempFHeat ?? current.roomTempFHeat,
      minAirflowRatio: minAirflowRatio ?? current.minAirflowRatio,
      primaryAirTempF: primaryAirTempF ?? current.primaryAirTempF,
      boxType: boxType ?? current.boxType,
      unit: unit ?? current.unit,
      method: method ?? current.method,
      directAirflowCfm: directAirflowCfm ?? current.directAirflowCfm,
    );
  }

  void _calculate() {
    state = state.copyWith(status: VavSizingStatus.calculating);

    try {
      final result = VavBoxSizingEngine.calculate(state.input);
      if (result == null) {
        state = state.copyWith(
          status: VavSizingStatus.error,
          errorMessage:
              'Vui lòng nhập tải lạnh và đảm bảo nhiệt độ phòng > nhiệt độ cấp.',
        );
        return;
      }
      state = state.copyWith(status: VavSizingStatus.success, result: result);
    } catch (e) {
      state = state.copyWith(
        status: VavSizingStatus.error,
        errorMessage: 'Lỗi tính toán: $e',
      );
    }
  }
}

final vavSizingProvider =
    StateNotifierProvider<VavSizingNotifier, VavSizingState>((ref) {
      return VavSizingNotifier();
    });
