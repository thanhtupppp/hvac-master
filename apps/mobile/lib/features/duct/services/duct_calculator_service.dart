import '../../../core/hvac/models/models.dart';
import '../../../core/hvac/units/unit_converter.dart';
import '../../../core/hvac/standards/standard_sizes.dart';
import '../../../core/hvac/validation/input_validator.dart';
import 'duct_engine.dart';

class DuctCalculatorService {
  HvacResult calculate(HvacInput input) {
    final validationError = InputValidator.validateInput(input);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final imperialInput = UnitConverter.toImperial(input);

    final standardRectSizesInInches = input.unitSystem == UnitSystem.metric
        ? StandardSizes.metricRect.map((mm) => UnitConverter.toInches(mm, UnitSystem.metric)).toList()
        : StandardSizes.imperialRect;

    final imperialResult = DuctEngine.calculate(imperialInput, standardRectSizesInInches);

    if (input.unitSystem == UnitSystem.metric) {
      return UnitConverter.resultToMetric(imperialResult);
    }
    return imperialResult;
  }
}
