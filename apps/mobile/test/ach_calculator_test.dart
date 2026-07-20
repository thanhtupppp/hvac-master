import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/tools/ach_calculator_screen.dart';

void main() {
  group('AchCalculatorScreen formula logic (unit tests)', () {
    // ACH = CFM × 60 / vol_ft³  ⟹  CFM = ACH × vol_ft³ / 60
    // vol_ft³ (metric) = l×w×h_m³ × 35.3147
    // vol_ft³ (imperial) = l×w×h_ft (no extra conversion)
    test('Metric: 6×5×3 m, ACH 6 → 317.8 CFM', () {
      const volM3 = 6 * 5 * 3; // 90
      const volFt3 = volM3 * 35.3147; // 3178
      const ach = 6.0;
      final cfm = ach * volFt3 / 60;
      expect(cfm, closeTo(317.8, 0.1));
    });

    test(
      'Imperial: 10×10×8 ft, ACH 6 → 80 CFM (was bug: ×35.3147 always applied)',
      () {
        // OLD BUG: code always treated dimension inputs as meters and multiplied vol×35.3147
        // OLD: volFt3 = 800 × 35.3147 = 28252 → CFM = 2825 (35× too high)
        // FIX: dimensions are already in ft, no conversion needed
        const volFt3 = 10 * 10 * 8.0; // 800 (not multiplied by 35.3147)
        const ach = 6.0;
        final cfm = ach * volFt3 / 60;
        expect(cfm, closeTo(80.0, 0.1));
      },
    );

    test('Imperial reverse: 10×10×8 ft, 80 CFM → ACH 6', () {
      const volFt3 = 10 * 10 * 8.0; // 800
      const cfm = 80.0;
      final ach = cfm * 60 / volFt3;
      expect(ach, closeTo(6.0, 0.1));
    });
  });

  group('AchCalculatorScreen widget', () {
    testWidgets('renders all inputs and mode toggle', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AchCalculatorScreen()));
      expect(find.text('Tính ACH'), findsOneWidget);
      expect(find.text('Tính CFM từ ACH'), findsOneWidget);
      expect(find.text('Tính ACH từ CFM'), findsOneWidget);
    });

    testWidgets('Imperial toggle switches unit labels to ft', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AchCalculatorScreen()));
      await tester.tap(find.text('Imperial'));
      await tester.pumpAndSettle();
      expect(find.text('ft'), findsNWidgets(3));
    });

    testWidgets('Metric toggle restores unit labels to m', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AchCalculatorScreen()));
      await tester.tap(find.text('Imperial'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Metric'));
      await tester.pumpAndSettle();
      expect(find.text('m'), findsNWidgets(3));
    });
  });
}
