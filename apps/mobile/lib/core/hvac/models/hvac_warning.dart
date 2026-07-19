import 'enums.dart';

class HvacWarning {
  final WarningType type;
  final String message;
  final WarningSeverity severity;

  const HvacWarning({
    required this.type,
    required this.message,
    required this.severity,
  });
}
