import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/hvac/models/enums.dart';
import '../constants/hydronic_constants.dart';
import '../data/fitting_coefficients.dart';
import '../formulas/pipe_pressure_loss_engine.dart';
import '../formulas/pump_head_engine.dart';

/// State for the Pump Head Calculator screen.
class PumpHeadState {
  final double flowRate;
  final double pipeDiameterIn;
  final double pipeLengthFt;
  final PipeMaterial material;
  final PipeService service;
  final double glycolConcentration;
  final FrictionMethod method;
  final List<FittingEntry> fittings;
  final double staticHeadFt;
  final double suctionPressurePsi;
  final double dischargePressurePsi;
  final UnitSystem unit;

  const PumpHeadState({
    this.flowRate = 100.0,
    this.pipeDiameterIn = 2.067,
    this.pipeLengthFt = 100.0,
    this.material = PipeMaterial.steelBlack,
    this.service = PipeService.chilledWater,
    this.glycolConcentration = 0.0,
    this.method = FrictionMethod.darcyWeisbach,
    this.fittings = const [],
    this.staticHeadFt = 30.0,
    this.suctionPressurePsi = 0.0,
    this.dischargePressurePsi = 0.0,
    this.unit = UnitSystem.imperial,
  });

  PumpHeadInput toInput() => PumpHeadInput(
        flowRate: flowRate,
        pipeDiameterIn: pipeDiameterIn,
        pipeLengthFt: pipeLengthFt,
        material: material,
        service: service,
        glycolConcentration: glycolConcentration,
        method: method,
        fittings: fittings,
        staticHeadFt: staticHeadFt,
        suctionPressurePsi: suctionPressurePsi,
        dischargePressurePsi: dischargePressurePsi,
        unit: unit,
      );

  PumpHeadState copyWith({
    double? flowRate,
    double? pipeDiameterIn,
    double? pipeLengthFt,
    PipeMaterial? material,
    PipeService? service,
    double? glycolConcentration,
    FrictionMethod? method,
    List<FittingEntry>? fittings,
    double? staticHeadFt,
    double? suctionPressurePsi,
    double? dischargePressurePsi,
    UnitSystem? unit,
  }) =>
      PumpHeadState(
        flowRate: flowRate ?? this.flowRate,
        pipeDiameterIn: pipeDiameterIn ?? this.pipeDiameterIn,
        pipeLengthFt: pipeLengthFt ?? this.pipeLengthFt,
        material: material ?? this.material,
        service: service ?? this.service,
        glycolConcentration: glycolConcentration ?? this.glycolConcentration,
        method: method ?? this.method,
        fittings: fittings ?? this.fittings,
        staticHeadFt: staticHeadFt ?? this.staticHeadFt,
        suctionPressurePsi: suctionPressurePsi ?? this.suctionPressurePsi,
        dischargePressurePsi: dischargePressurePsi ?? this.dischargePressurePsi,
        unit: unit ?? this.unit,
      );
}

class PumpHeadNotifier extends StateNotifier<PumpHeadState> {
  PumpHeadNotifier() : super(const PumpHeadState());

  void onFlowChanged(double v) => state = state.copyWith(flowRate: v);
  void onDiameterChanged(double v) => state = state.copyWith(pipeDiameterIn: v);
  void onLengthChanged(double v) => state = state.copyWith(pipeLengthFt: v);
  void onMaterialChanged(PipeMaterial m) => state = state.copyWith(material: m);
  void onServiceChanged(PipeService s) => state = state.copyWith(service: s);
  void onGlycolChanged(double v) => state = state.copyWith(glycolConcentration: v);
  void onMethodChanged(FrictionMethod m) => state = state.copyWith(method: m);
  void onStaticHeadChanged(double v) => state = state.copyWith(staticHeadFt: v);
  void onSuctionPressureChanged(double v) =>
      state = state.copyWith(suctionPressurePsi: v);
  void onDischargePressureChanged(double v) =>
      state = state.copyWith(dischargePressurePsi: v);

  void onUnitToggled() {
    final next = state.unit == UnitSystem.imperial
        ? UnitSystem.metric
        : UnitSystem.imperial;
    state = state.copyWith(unit: next);
  }

  void addFitting(FittingType type, int count) {
    final updated = List<FittingEntry>.from(state.fittings)
      ..add(FittingEntry(
        type: type,
        nominalSizeIn: state.pipeDiameterIn,
        quantity: count,
      ));
    state = state.copyWith(fittings: updated);
  }

  void removeFitting(int index) {
    if (index < 0 || index >= state.fittings.length) return;
    final updated = List<FittingEntry>.from(state.fittings)..removeAt(index);
    state = state.copyWith(fittings: updated);
  }

  void clearFittings() => state = state.copyWith(fittings: []);

  void reset() => state = const PumpHeadState();
}

final pumpHeadProvider =
    StateNotifierProvider<PumpHeadNotifier, PumpHeadState>((ref) {
  return PumpHeadNotifier();
});

/// Provider for the calculation result.
final pumpHeadResultProvider = Provider<PumpHeadResult?>((ref) {
  final state = ref.watch(pumpHeadProvider);
  return PumpHeadEngine.calculate(state.toInput());
});
