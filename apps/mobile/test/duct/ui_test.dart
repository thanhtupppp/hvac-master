import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/screens/tools/duct_calculator_screen.dart';
import 'package:mobile/services/duct/models/enums.dart';
import 'package:mobile/services/duct/providers/duct_calculator_notifier.dart';

void main() {
  testWidgets('DuctCalculatorScreen renders segment controls and form', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DuctCalculatorScreen(),
        ),
      ),
    );

    // Verify screen title in AppBar
    expect(find.text('Tính Toán Thiết Kế Ống Gió'), findsOneWidget);

    // Verify segment controls are present
    expect(find.text('Metric'), findsOneWidget);
    expect(find.text('Imperial'), findsOneWidget);
    expect(find.text('Velocity'), findsOneWidget);
    expect(find.text('Friction'), findsOneWidget);

    // Verify initial metric units on the fields
    expect(find.text('m³/h'), findsOneWidget); // Flow rate unit
    expect(find.text('m/s'), findsOneWidget);  // Velocity unit
    expect(find.text('Pa/m'), findsNothing);    // Friction unit should not be visible initially in velocity method

    // Verify that the Round Hero Result card is rendered (since notifier runs immediately)
    expect(find.byKey(const Key('roundHeroCard')), findsOneWidget);
    expect(find.text('ỐNG TRÒN GỢI Ý (HERO)'), findsOneWidget);
    expect(find.text('ỐNG CHỮ NHẬT ĐỀ XUẤT (BEST)'), findsOneWidget);
  });

  testWidgets('DuctCalculatorScreen toggling unit system updates suffixes and values', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DuctCalculatorScreen(),
        ),
      ),
    );

    // Tap on Imperial segment
    await tester.tap(find.text('Imperial'));
    await tester.pumpAndSettle();

    // Suffixes should update
    expect(find.text('CFM'), findsOneWidget);
    expect(find.text('fpm'), findsOneWidget);
    expect(find.text('m³/h'), findsNothing);
    expect(find.text('m/s'), findsNothing);
  });

  testWidgets('DuctCalculatorScreen toggling method switches between velocity and friction fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DuctCalculatorScreen(),
        ),
      ),
    );

    // Initial state: velocity method -> velocity field visible, friction rate hidden
    expect(find.byKey(const Key('velocityField')), findsOneWidget);
    expect(find.byKey(const Key('frictionField')), findsNothing);

    // Tap on Friction segment to switch to equalFriction method
    await tester.tap(find.text('Friction'));
    await tester.pumpAndSettle();

    // Now: equalFriction method -> friction rate visible, velocity field hidden
    expect(find.byKey(const Key('velocityField')), findsNothing);
    expect(find.byKey(const Key('frictionField')), findsOneWidget);
  });

  testWidgets('DuctCalculatorScreen input updates trigger state calculations and render results', (WidgetTester tester) async {
    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: DuctCalculatorScreen(),
        ),
      ),
    );

    // Enter a new flow rate value
    final flowFieldFinder = find.byKey(const Key('flowRateField'));
    expect(flowFieldFinder, findsOneWidget);

    await tester.enterText(flowFieldFinder, '2500');
    await tester.pump();

    // Verify notifier input was updated
    final state = container.read(ductCalculatorProvider);
    expect(state.input.flowRate, 2500.0);

    // Wait for the 250ms debounce and settle
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify recalculation was executed and results are shown
    expect(find.byKey(const Key('roundHeroCard')), findsOneWidget);
    expect(find.byKey(const Key('rectangleSection')), findsOneWidget);

    container.dispose();
  });
}
