import '../models/models.dart';

class WarningBuilder {
  static List<HvacWarning> buildWarnings({
    required double actualVelocityFpm,
    required double frictionRate,
    required UnitSystem unitSystem,
  }) {
    final warnings = <HvacWarning>[];

    if (actualVelocityFpm > 1200.0) {
      warnings.add(
        const HvacWarning(
          type: WarningType.highVelocity,
          message:
              'Vận tốc gió cao hơn mức khuyến nghị, có thể gây tiếng ồn lớn.',
          severity: WarningSeverity.warning,
        ),
      );
    }

    if (actualVelocityFpm < 400.0) {
      warnings.add(
        const HvacWarning(
          type: WarningType.lowVelocity,
          message: 'Vận tốc gió thấp, có thể gây bất đồng đều trong phân phối.',
          severity: WarningSeverity.info,
        ),
      );
    }

    final isOutOfRange = unitSystem == UnitSystem.imperial
        ? (frictionRate < 0.05 || frictionRate > 0.3)
        : (frictionRate < 0.4 || frictionRate > 2.5);

    if (isOutOfRange) {
      warnings.add(
        HvacWarning(
          type: WarningType.frictionOutOfRange,
          message:
              'Tỷ lệ ma sát nằm ngoài phạm vi khuyến nghị (${unitSystem == UnitSystem.imperial ? '0.05–0.30 in.wg/100ft' : '0.4–2.5 Pa/m'}).',
          severity: WarningSeverity.info,
        ),
      );
    }

    return warnings;
  }

  static HvacWarning? checkAspectRatio(double aspectRatio) {
    if (aspectRatio > 4.0) {
      return HvacWarning(
        type: WarningType.highAspectRatio,
        message:
            'Tỷ lệ cạnh (${aspectRatio.toStringAsFixed(1)}) vượt quá giới hạn khuyến nghị (4:1).',
        severity: WarningSeverity.warning,
      );
    }
    return null;
  }
}
