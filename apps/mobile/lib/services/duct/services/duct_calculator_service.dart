import '../models/duct_input.dart';
import '../models/duct_result.dart';
import '../models/enums.dart';
import '../engine/duct_engine.dart';
import '../engine/unit_converter.dart';

class DuctCalculatorService {
  DuctResult calculate(DuctInput input) {
    if (!input.isValid) {
      throw ArgumentError('DuctInput is invalid.');
    }
    
    // 1. Convert to Imperial
    final imperialInput = UnitConverter.toImperial(input);

    // 2. Compute via Engine
    final imperialResult = DuctEngine.calculate(imperialInput);

    // 3. Convert back to Metric if input was Metric
    if (input.unitSystem == UnitSystem.metric) {
      return UnitConverter.resultToMetric(imperialResult);
    }
    return imperialResult;
  }
}
