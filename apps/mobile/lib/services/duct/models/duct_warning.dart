import 'enums.dart';

class DuctWarning {
  final WarningType type;
  final String message;
  final WarningSeverity severity;

  const DuctWarning({
    required this.type,
    required this.message,
    required this.severity,
  });
}
