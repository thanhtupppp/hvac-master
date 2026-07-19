import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/hvac/models/models.dart';
import 'package:mobile/features/duct/providers/duct_calculator_notifier.dart';

void main() {
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
      expect(state.input.systemType, SystemType.supplyMain);

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

      var state = container.read(ductCalculatorProvider);
      expect(state.input.flowRate, 2000.0);

      await Future.delayed(const Duration(milliseconds: 300));

      state = container.read(ductCalculatorProvider);
      expect(state.status, CalculationStatus.success);
      expect(
        state.result!.roundResult.calculatedDiameter,
        isNot(closeTo(365.5, 10.0)),
      );
    });

    test('onUnitSystemChanged converts values and recalculates', () {
      final notifier = container.read(ductCalculatorProvider.notifier);

      notifier.onUnitSystemChanged(UnitSystem.imperial);

      final state = container.read(ductCalculatorProvider);
      expect(state.input.unitSystem, UnitSystem.imperial);
      expect(state.input.flowRate, closeTo(1000.62, 0.1));
      expect(state.input.targetVelocity, closeTo(885.825, 0.1));
      expect(state.input.frictionRate, closeTo(0.01225, 0.001));

      expect(state.status, CalculationStatus.success);
      expect(state.result, isNotNull);
    });

    test(
      'onDuctTypeChanged suggests appropriate velocity and recalculates',
      () {
        final notifier = container.read(ductCalculatorProvider.notifier);

        notifier.onDuctTypeChanged(SystemType.supplyBranch);

        final state = container.read(ductCalculatorProvider);
        expect(state.input.systemType, SystemType.supplyBranch);
        expect(state.input.targetVelocity, 3.0);
        expect(state.status, CalculationStatus.success);
      },
    );

    test('invalid input sets status to idle', () async {
      final notifier = container.read(ductCalculatorProvider.notifier);
      notifier.onFlowRateChanged(-10.0);

      await Future.delayed(const Duration(milliseconds: 300));

      final state = container.read(ductCalculatorProvider);
      expect(state.status, CalculationStatus.idle);
    });
  });
}
