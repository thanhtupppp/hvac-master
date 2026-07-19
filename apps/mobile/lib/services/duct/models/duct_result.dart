import 'round_result.dart';
import 'rectangle_option.dart';
import 'duct_warning.dart';
import 'calculation_metadata.dart';

class DuctResult {
  final RoundResult roundDuct;
  final List<RectangleOption> rectangleOptions;
  final List<DuctWarning> warnings;
  final CalculationMetadata metadata;

  const DuctResult({
    required this.roundDuct,
    required this.rectangleOptions,
    required this.warnings,
    required this.metadata,
  });
}
