import 'dart:math' as math;

import '../../../core/hvac/models/enums.dart';
import '../data/pump_catalog.dart';

/// Input for pump selection.
class PumpSelectionInput {
  final double flowRate; // GPM (imperial) or m³/h (metric)
  final double headFt; // ft (imperial) or m (metric)
  final UnitSystem unit;
  final List<PumpType> pumpTypeFilter; // empty = no filter

  const PumpSelectionInput({
    required this.flowRate,
    required this.headFt,
    this.unit = UnitSystem.imperial,
    this.pumpTypeFilter = const [],
  });
}

/// Result of pump selection.
class PumpSelectionResult {
  final double requiredFlowGpm;
  final double requiredHeadFt;
  final List<PumpSelectionCandidate> candidates;
  final List<String> warnings;

  const PumpSelectionResult({
    required this.requiredFlowGpm,
    required this.requiredHeadFt,
    required this.candidates,
    required this.warnings,
  });
}

/// Engine that finds suitable pumps for a given operating point.
class PumpSelectionEngine {
  PumpSelectionEngine._();

  static const double _m3hToGpm = 4.40287;
  static const double _ftToM = 0.3048;

  /// Find all pumps that can meet the required Q/H point.
  static PumpSelectionResult? calculate(PumpSelectionInput input) {
    if (input.flowRate <= 0 || input.headFt <= 0) return null;

    final flowGpm = input.unit == UnitSystem.imperial
        ? input.flowRate
        : input.flowRate * _m3hToGpm;
    final headFt = input.unit == UnitSystem.imperial
        ? input.headFt
        : input.headFt / _ftToM;

    final warnings = <String>[];

    var candidates = PumpCatalog.findMatchingPumps(
      flowGpm: flowGpm,
      headFt: headFt,
    );

    // Apply filter
    if (input.pumpTypeFilter.isNotEmpty) {
      candidates = candidates
          .where((c) => input.pumpTypeFilter.contains(c.pump.type))
          .toList();
    }

    // Warnings
    if (candidates.isEmpty) {
      warnings.add(
        'No pump in catalog meets '
        '${flowGpm.toStringAsFixed(0)} GPM at '
        '${headFt.toStringAsFixed(1)} ft. '
        'Consider a larger model or custom selection.',
      );
    } else {
      // Check if best efficiency is poor
      final best = candidates.first.efficiencyAtPoint;
      if (best < 0.4) {
        warnings.add(
          'Best efficiency only '
          '${(best * 100).toStringAsFixed(0)}% — operating point '
          'is far from BEP.',
        );
      }
    }

    // Check if required head is extreme
    if (headFt > 250) {
      warnings.add(
        'Required head ${headFt.toStringAsFixed(0)} ft is very high; '
        'consider multi-stage pump.',
      );
    }

    return PumpSelectionResult(
      requiredFlowGpm: flowGpm,
      requiredHeadFt: headFt,
      candidates: candidates,
      warnings: warnings,
    );
  }

  /// Estimate impeller trim diameter for a given pump.
  ///
  /// Uses affinity law: D_trim / D_max = sqrt(H_required / H_shutoff).
  /// Returns null if trim is not feasible (would require <50% of full diameter).
  static double? estimateImpellerTrim({
    required PumpModel pump,
    required double requiredHeadFt,
  }) {
    if (requiredHeadFt <= 0 || requiredHeadFt > pump.maxHeadFt) return null;
    final ratio = requiredHeadFt / pump.maxHeadFt;
    final diameterRatio = math.sqrt(ratio);
    final trim = pump.impellerDiameterIn * diameterRatio;
    // Pump manufacturers typically allow trimming to 50–100% of full diameter
    if (trim < pump.impellerDiameterIn * 0.5) return null;
    if (trim > pump.impellerDiameterIn) return null;
    return trim;
  }
}
