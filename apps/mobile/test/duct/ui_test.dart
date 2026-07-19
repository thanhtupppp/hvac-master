import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/screens/tools/duct_calculator_screen.dart';
import 'package:mobile/features/duct/providers/duct_calculator_notifier.dart';

void main() {
  testWidgets('DuctCalculatorScreen renders segment controls and form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DuctCalculatorScreen())),
    );

    expect(find.text('Tính Toán Thiết Kế Ống Gió'), findsOneWidget);
    expect(find.text('Metric'), findsOneWidget);
    expect(find.text('Imperial'), findsOneWidget);
    expect(find.text('Velocity'), findsOneWidget);
    expect(find.text('Friction'), findsOneWidget);
    expect(find.text('m³/h'), findsOneWidget);
    expect(find.text('m/s'), findsOneWidget);
    expect(find.text('Pa/m'), findsNothing);
    expect(find.byKey(const Key('roundHeroCard')), findsOneWidget);
    expect(find.text('ỐNG TRÒN GỢI Ý (HERO)'), findsOneWidget);
    expect(find.text('ỐNG CHỮ NHẬT ĐỀ XUẤT (BEST)'), findsOneWidget);
  });

  testWidgets(
    'DuctCalculatorScreen toggling unit system updates suffixes and values',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: DuctCalculatorScreen())),
      );

      await tester.tap(find.text('Imperial'));
      await tester.pumpAndSettle();

      expect(find.text('CFM'), findsOneWidget);
      expect(find.text('fpm'), findsOneWidget);
      expect(find.text('m³/h'), findsNothing);
      expect(find.text('m/s'), findsNothing);
    },
  );

  testWidgets(
    'DuctCalculatorScreen toggling method switches between velocity and friction fields',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: DuctCalculatorScreen())),
      );

      expect(find.byKey(const Key('velocityField')), findsOneWidget);
      expect(find.byKey(const Key('frictionField')), findsNothing);

      await tester.tap(find.text('Friction'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('velocityField')), findsNothing);
      expect(find.byKey(const Key('frictionField')), findsOneWidget);
    },
  );

  testWidgets(
    'DuctCalculatorScreen input updates trigger state calculations and render results',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DuctCalculatorScreen()),
        ),
      );

      final flowFieldFinder = find.byKey(const Key('flowRateField'));
      expect(flowFieldFinder, findsOneWidget);

      await tester.enterText(flowFieldFinder, '2500');
      await tester.pump();

      final state = container.read(ductCalculatorProvider);
      expect(state.input.flowRate, 2500.0);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('roundHeroCard')), findsOneWidget);
      expect(find.byKey(const Key('rectangleSection')), findsOneWidget);

      container.dispose();
    },
  );
}
