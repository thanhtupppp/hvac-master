import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/hvac/formulas/hvac_formulas.dart';

void main() {
  test('HvacFormulas velocity calculation matches formula', () {
    final v = HvacFormulas.velocity(cfm: 1000, areaSqFt: 2.0);
    expect(v, 500.0);
  });

  test('HvacFormulas round diameter matches approximation', () {
    final d = HvacFormulas.roundDuctDiameter(
      cfm: 1000,
      frictionRateInWgPer100ft: 0.1,
    );
    expect(d, closeTo(13.62, 0.1));
  });

  test('HvacFormulas equivalent diameter matches Huebscher equation', () {
    final de = HvacFormulas.equivalentDiameter(a: 12, b: 12);
    expect(de, closeTo(13.10, 0.1));
  });
}
