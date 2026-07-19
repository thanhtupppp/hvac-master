class CalculationMetadata {
  final DateTime timestamp;
  final String algorithmVersion;
  final String standard;

  const CalculationMetadata({
    required this.timestamp,
    required this.algorithmVersion,
    required this.standard,
  });
}
