import 'hvac_warning.dart';
import 'round_result.dart';
import 'rectangle_option.dart';
import 'calculation_metadata.dart';

class HvacResult {
  final RoundResult roundResult;
  final List<RectangleOption> rectangleOptions;
  final List<HvacWarning> warnings;
  final CalculationMetadata metadata;

  const HvacResult({
    required this.roundResult,
    required this.rectangleOptions,
    required this.warnings,
    required this.metadata,
  });
}
