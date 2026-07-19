import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/screens/tools/duct_calculator_screen.dart';

void main() {
  testWidgets('E2E: Routing opens DuctSizer and updates state on inputs', (WidgetTester tester) async {
    // 1. Setup the widget tree with ProviderScope and MaterialApp using AppRoutes
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.ductSizer,
        ),
      ),
    );

    // Verify routing opened the screen successfully
    expect(find.byType(DuctCalculatorScreen), findsOneWidget);

    // Verify initial layout elements are present
    expect(find.byKey(const Key('flowRateField')), findsOneWidget);
    expect(find.byKey(const Key('velocityField')), findsOneWidget);
    expect(find.byKey(const Key('roundHeroCard')), findsOneWidget);

    // 2. Change Flow Rate input in Metric/Velocity mode
    final flowFieldFinder = find.byKey(const Key('flowRateField'));
    await tester.enterText(flowFieldFinder, '2000');
    await tester.pump();
    
    // Wait for the 250ms debounce and settle the UI
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify round hero card still exists with computed results
    expect(find.byKey(const Key('roundHeroCard')), findsOneWidget);

    // 3. Toggle to Imperial Unit System
    await tester.tap(find.text('Imperial'));
    await tester.pumpAndSettle();

    // Verify unit suffixes changed to imperial
    expect(find.text('CFM'), findsOneWidget);
    expect(find.text('fpm'), findsOneWidget);
    expect(find.text('m³/h'), findsNothing);
    expect(find.text('m/s'), findsNothing);

    // Enter flow rate in imperial (CFM)
    await tester.enterText(flowFieldFinder, '1200');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // 4. Toggle to Friction Method
    await tester.tap(find.text('Friction'));
    await tester.pumpAndSettle();

    // Verify velocity field is gone, friction field is shown
    expect(find.byKey(const Key('velocityField')), findsNothing);
    expect(find.byKey(const Key('frictionField')), findsOneWidget);

    // Enter friction rate
    final frictionFieldFinder = find.byKey(const Key('frictionField'));
    await tester.enterText(frictionFieldFinder, '0.08');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify calculations ran successfully and show the hero card
    expect(find.byKey(const Key('roundHeroCard')), findsOneWidget);
  });
}
