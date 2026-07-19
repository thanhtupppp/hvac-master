import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/services/duct/services/duct_calculator_service.dart';
import 'package:mobile/services/duct/models/duct_input.dart';
import 'package:mobile/services/duct/models/enums.dart';
import 'package:mobile/services/duct/providers/duct_calculator_notifier.dart';

void main() {
  group('DuctCalculatorService Tests', () {
    test('DuctCalculatorService performs conversion and returns result', () {
      final service = DuctCalculatorService();
      const input = DuctInput(
        flowRate: 1700,
        targetVelocity: 4.5,
        frictionRate: 0.8,
        method: CalculationMethod.velocity,
        unitSystem: UnitSystem.metric,
        ductType: DuctType.supplyMain,
      );
      final res = service.calculate(input);
      // Metric flow rate: 1700 m3/h = 1000.62 CFM
      // Metric velocity: 4.5 m/s = 885.825 FPM
      // Area = 1000.62 / 885.825 = 1.1296 sqft = 162.66 sqin
      // Calculated diameter = sqrt(4 * 162.66 / pi) = 14.39 inches = 365.5 mm
      expect(res.roundDuct.calculatedDiameter, closeTo(365.5, 10.0));
      expect(res.roundDuct.standardDiameter, closeTo(355.6, 10.0)); // 14 inches standard is ~355.6mm
    });

    test('DuctCalculatorService throws ArgumentError for invalid input', () {
      final service = DuctCalculatorService();
      const invalidInput = DuctInput(
        flowRate: -100,
        targetVelocity: 4.5,
        frictionRate: 0.8,
        method: CalculationMethod.velocity,
        unitSystem: UnitSystem.metric,
        ductType: DuctType.supplyMain,
      );
      expect(() => service.calculate(invalidInput), throwsArgumentError);
    });
  });

  group('DuctCalculatorNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state and initial trigger calculation', () async {
      final state = container.read(ductCalculatorProvider);
      expect(state.input.flowRate, 1700.0);
      expect(state.input.targetVelocity, 4.5);
      expect(state.input.frictionRate, 0.1);
      expect(state.input.method, CalculationMethod.velocity);
      expect(state.input.unitSystem, UnitSystem.metric);
      expect(state.input.ductType, DuctType.supplyMain);

      // It triggers calculation synchronously during initialization
      expect(state.status, CalculationStatus.success);
      expect(state.result, isNotNull);
      expect(state.errorMessage, isNull);
    });

    test('onMethodChanged triggers immediate calculation', () {
      final notifier = container.read(ductCalculatorProvider.notifier);
      
      notifier.onMethodChanged(CalculationMethod.equalFriction);
      
      final state = container.read(ductCalculatorProvider);
      expect(state.input.method, CalculationMethod.equalFriction);
      expect(state.status, CalculationStatus.success);
      expect(state.result, isNotNull);
    });

    test('onFlowRateChanged uses debounce', () async {
      final notifier = container.read(ductCalculatorProvider.notifier);
      
      notifier.onFlowRateChanged(2000.0);
      
      // Since it is debounced for 250ms, status should immediately be success (old result)
      // but the input should be updated
      var state = container.read(ductCalculatorProvider);
      expect(state.input.flowRate, 2000.0);
      
      // Wait for debounce timer (250ms + small buffer)
      await Future.delayed(const Duration(milliseconds: 300));
      
      state = container.read(ductCalculatorProvider);
      expect(state.status, CalculationStatus.success);
      expect(state.result!.roundDuct.calculatedDiameter, isNot(closeTo(365.5, 10.0))); // recalculated
    });

    test('onUnitSystemChanged converts values and recalculates', () {
      final notifier = container.read(ductCalculatorProvider.notifier);
      
      notifier.onUnitSystemChanged(UnitSystem.imperial);
      
      final state = container.read(ductCalculatorProvider);
      expect(state.input.unitSystem, UnitSystem.imperial);
      // Metric FlowRate 1700 * 0.5886 = 1000.62 CFM
      expect(state.input.flowRate, closeTo(1000.62, 0.1));
      // Metric Velocity 4.5 * 196.85 = 885.825 FPM
      expect(state.input.targetVelocity, closeTo(885.825, 0.1));
      // Metric Friction 0.1 * 0.1225 = 0.01225 in.wg/100ft
      expect(state.input.frictionRate, closeTo(0.01225, 0.001));
      
      expect(state.status, CalculationStatus.success);
      expect(state.result, isNotNull);
    });

    test('onDuctTypeChanged suggests appropriate velocity and recalculates', () {
      final notifier = container.read(ductCalculatorProvider.notifier);
      
      notifier.onDuctTypeChanged(DuctType.supplyBranch);
      
      final state = container.read(ductCalculatorProvider);
      expect(state.input.ductType, DuctType.supplyBranch);
      // Suggested metric velocity for supplyBranch is 3.0 m/s
      expect(state.input.targetVelocity, 3.0);
      expect(state.status, CalculationStatus.success);
    });

    test('invalid input sets status to idle', () async {
      final notifier = container.read(ductCalculatorProvider.notifier);
      // Set invalid flow rate
      notifier.onFlowRateChanged(-10.0);
      
      // Wait for debounce timer
      await Future.delayed(const Duration(milliseconds: 300));
      
      final state = container.read(ductCalculatorProvider);
      expect(state.status, CalculationStatus.idle);
    });
  });
}
