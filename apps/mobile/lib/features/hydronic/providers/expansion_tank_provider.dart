import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/hvac/models/enums.dart';
import '../constants/hydronic_constants.dart';
import '../formulas/expansion_tank_engine.dart';

class ExpansionTankState {
  final double systemVolume;
  final double tempInitial;
  final double tempFinal;
  final double prechargePressure;
  final double reliefPressure;
  final double glycolConcentration;
  final ExpansionTankType tankType;
  final UnitSystem unit;

  const ExpansionTankState({
    this.systemVolume = 100.0, // 100 gallons default
    this.tempInitial = 50.0, // 50 °F cold start
    this.tempFinal = 180.0, // 180 °F hot operation
    this.prechargePressure = 12.0, // 12 PSI precharge
    this.reliefPressure = 30.0, // 30 PSI relief
    this.glycolConcentration = 0.0,
    this.tankType = ExpansionTankType.closedDiaphragm,
    this.unit = UnitSystem.imperial,
  });

  ExpansionTankInput toInput() {
    if (unit == UnitSystem.imperial) {
      return ExpansionTankInput(
        systemVolume: systemVolume, // gallons
        tempInitialC: tempInitial, // °F
        tempFinalC: tempFinal,
        prechargePressure: prechargePressure, // PSI
        reliefPressure: reliefPressure,
        glycolConcentration: glycolConcentration,
        tankType: tankType,
        unit: unit,
      );
    } else {
      return ExpansionTankInput(
        systemVolume: systemVolume, // liters
        tempInitialC: _fToC(tempInitial),
        tempFinalC: _fToC(tempFinal),
        prechargePressure: _psiToKpa(prechargePressure),
        reliefPressure: _psiToKpa(reliefPressure),
        glycolConcentration: glycolConcentration,
        tankType: tankType,
        unit: unit,
      );
    }
  }

  ExpansionTankState copyWith({
    double? systemVolume,
    double? tempInitial,
    double? tempFinal,
    double? prechargePressure,
    double? reliefPressure,
    double? glycolConcentration,
    ExpansionTankType? tankType,
    UnitSystem? unit,
  }) => ExpansionTankState(
    systemVolume: systemVolume ?? this.systemVolume,
    tempInitial: tempInitial ?? this.tempInitial,
    tempFinal: tempFinal ?? this.tempFinal,
    prechargePressure: prechargePressure ?? this.prechargePressure,
    reliefPressure: reliefPressure ?? this.reliefPressure,
    glycolConcentration: glycolConcentration ?? this.glycolConcentration,
    tankType: tankType ?? this.tankType,
    unit: unit ?? this.unit,
  );

  // Static helpers for unit conversion
  static double _fToC(double f) => (f - 32) * 5 / 9;
  static double _psiToKpa(double psi) =>
      psi * HydronicConstants.psiToPa / 1000.0;
}

class ExpansionTankNotifier extends StateNotifier<ExpansionTankState> {
  ExpansionTankNotifier() : super(const ExpansionTankState());

  void onVolumeChanged(double v) => state = state.copyWith(systemVolume: v);
  void onTempInitialChanged(double v) => state = state.copyWith(tempInitial: v);
  void onTempFinalChanged(double v) => state = state.copyWith(tempFinal: v);
  void onPrechargeChanged(double v) =>
      state = state.copyWith(prechargePressure: v);
  void onReliefChanged(double v) => state = state.copyWith(reliefPressure: v);
  void onGlycolChanged(double v) =>
      state = state.copyWith(glycolConcentration: v);
  void onTankTypeChanged(ExpansionTankType t) =>
      state = state.copyWith(tankType: t);

  void onUnitToggled() {
    final next = state.unit == UnitSystem.imperial
        ? UnitSystem.metric
        : UnitSystem.imperial;
    state = state.copyWith(unit: next);
  }

  void reset() => state = const ExpansionTankState();
}

final expansionTankProvider =
    StateNotifierProvider<ExpansionTankNotifier, ExpansionTankState>((ref) {
      return ExpansionTankNotifier();
    });

final expansionTankResultProvider = Provider<ExpansionTankResult?>((ref) {
  final state = ref.watch(expansionTankProvider);
  return ExpansionTankEngine.calculate(state.toInput());
});
