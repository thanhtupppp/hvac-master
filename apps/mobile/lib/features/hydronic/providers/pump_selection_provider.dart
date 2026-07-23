import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/hvac/models/enums.dart';
import '../data/pump_catalog.dart';
import '../formulas/pump_selection_engine.dart';

class PumpSelectionState {
  final double flowRate;
  final double headFt;
  final UnitSystem unit;
  final Set<PumpType> pumpTypeFilter;

  const PumpSelectionState({
    this.flowRate = 200.0,
    this.headFt = 50.0,
    this.unit = UnitSystem.imperial,
    this.pumpTypeFilter = const {},
  });

  PumpSelectionInput toInput() => PumpSelectionInput(
    flowRate: flowRate,
    headFt: headFt,
    unit: unit,
    pumpTypeFilter: pumpTypeFilter.toList(),
  );

  PumpSelectionState copyWith({
    double? flowRate,
    double? headFt,
    UnitSystem? unit,
    Set<PumpType>? pumpTypeFilter,
  }) => PumpSelectionState(
    flowRate: flowRate ?? this.flowRate,
    headFt: headFt ?? this.headFt,
    unit: unit ?? this.unit,
    pumpTypeFilter: pumpTypeFilter ?? this.pumpTypeFilter,
  );
}

class PumpSelectionNotifier extends StateNotifier<PumpSelectionState> {
  PumpSelectionNotifier() : super(const PumpSelectionState());

  void onFlowChanged(double v) => state = state.copyWith(flowRate: v);
  void onHeadChanged(double v) => state = state.copyWith(headFt: v);

  void onUnitToggled() {
    final next = state.unit == UnitSystem.imperial
        ? UnitSystem.metric
        : UnitSystem.imperial;
    state = state.copyWith(unit: next);
  }

  void togglePumpType(PumpType t) {
    final next = Set<PumpType>.from(state.pumpTypeFilter);
    if (next.contains(t)) {
      next.remove(t);
    } else {
      next.add(t);
    }
    state = state.copyWith(pumpTypeFilter: next);
  }

  void reset() => state = const PumpSelectionState();
}

final pumpSelectionProvider =
    StateNotifierProvider<PumpSelectionNotifier, PumpSelectionState>((ref) {
      return PumpSelectionNotifier();
    });

final pumpSelectionResultProvider = Provider<PumpSelectionResult?>((ref) {
  final state = ref.watch(pumpSelectionProvider);
  return PumpSelectionEngine.calculate(state.toInput());
});
