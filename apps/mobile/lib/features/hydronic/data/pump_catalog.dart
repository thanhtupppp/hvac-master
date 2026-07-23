import 'dart:math' as math;

/// Pump model classification.
enum PumpType { endSuction, inline, verticalMultistage, splitCase, circulator }

/// Pump family / catalog identifier (e.g. "Bell & Gossett 1510", "Grundfos CR").
class PumpModel {
  final String manufacturer;
  final String series;
  final String model;
  final PumpType type;
  final double maxFlowGpm; // at best efficiency point (BEP)
  final double maxHeadFt; // at shutoff (zero flow)
  final double bestEfficiency; // decimal (0.0–1.0)
  final double minFlowGpm;
  final double impellerDiameterIn;
  final double maxPowerHp;

  const PumpModel({
    required this.manufacturer,
    required this.series,
    required this.model,
    required this.type,
    required this.maxFlowGpm,
    required this.maxHeadFt,
    required this.bestEfficiency,
    required this.minFlowGpm,
    required this.impellerDiameterIn,
    required this.maxPowerHp,
  });

  String get displayName => '$manufacturer $series $model';
}

/// A standardized pump catalog.
///
/// Data is representative only — for production use real manufacturer curves
/// (Bell & Gossett, Grundfos, Taco, Armstrong, etc.).
class PumpCatalog {
  PumpCatalog._();

  /// All pumps in the catalog, ordered by max head × max flow (descending).
  static const List<PumpModel> all = [
    // ── End-suction (small to medium) ──────────────────────────
    PumpModel(
      manufacturer: 'Bell & Gossett',
      series: 'Series 1510',
      model: '1.5x1x6',
      type: PumpType.endSuction,
      maxFlowGpm: 250,
      maxHeadFt: 75,
      bestEfficiency: 0.72,
      minFlowGpm: 25,
      impellerDiameterIn: 6.0,
      maxPowerHp: 7.5,
    ),
    PumpModel(
      manufacturer: 'Bell & Gossett',
      series: 'Series 1510',
      model: '2x2x6',
      type: PumpType.endSuction,
      maxFlowGpm: 400,
      maxHeadFt: 90,
      bestEfficiency: 0.74,
      minFlowGpm: 50,
      impellerDiameterIn: 7.5,
      maxPowerHp: 15,
    ),
    PumpModel(
      manufacturer: 'Bell & Gossett',
      series: 'Series 1510',
      model: '3x3x8',
      type: PumpType.endSuction,
      maxFlowGpm: 800,
      maxHeadFt: 120,
      bestEfficiency: 0.78,
      minFlowGpm: 100,
      impellerDiameterIn: 9.5,
      maxPowerHp: 30,
    ),

    // ── Inline circulators ─────────────────────────────────────
    PumpModel(
      manufacturer: 'Taco',
      series: '0010',
      model: '0010-F3',
      type: PumpType.circulator,
      maxFlowGpm: 50,
      maxHeadFt: 25,
      bestEfficiency: 0.55,
      minFlowGpm: 5,
      impellerDiameterIn: 4.0,
      maxPowerHp: 0.75,
    ),
    PumpModel(
      manufacturer: 'Taco',
      series: '0011',
      model: '0011-M3',
      type: PumpType.circulator,
      maxFlowGpm: 70,
      maxHeadFt: 35,
      bestEfficiency: 0.58,
      minFlowGpm: 8,
      impellerDiameterIn: 5.0,
      maxPowerHp: 1.5,
    ),
    PumpModel(
      manufacturer: 'Grundfos',
      series: 'UPS',
      model: 'UPS 32-80',
      type: PumpType.circulator,
      maxFlowGpm: 80,
      maxHeadFt: 30,
      bestEfficiency: 0.60,
      minFlowGpm: 5,
      impellerDiameterIn: 3.5,
      maxPowerHp: 0.5,
    ),
    PumpModel(
      manufacturer: 'Grundfos',
      series: 'UPS',
      model: 'UPS 43-100',
      type: PumpType.circulator,
      maxFlowGpm: 130,
      maxHeadFt: 45,
      bestEfficiency: 0.62,
      minFlowGpm: 10,
      impellerDiameterIn: 4.5,
      maxPowerHp: 1.0,
    ),

    // ── Vertical multistage ────────────────────────────────────
    PumpModel(
      manufacturer: 'Grundfos',
      series: 'CR',
      model: 'CR 5-12',
      type: PumpType.verticalMultistage,
      maxFlowGpm: 60,
      maxHeadFt: 175,
      bestEfficiency: 0.68,
      minFlowGpm: 5,
      impellerDiameterIn: 4.0,
      maxPowerHp: 7.5,
    ),
    PumpModel(
      manufacturer: 'Grundfos',
      series: 'CR',
      model: 'CR 10-12',
      type: PumpType.verticalMultistage,
      maxFlowGpm: 130,
      maxHeadFt: 220,
      bestEfficiency: 0.72,
      minFlowGpm: 15,
      impellerDiameterIn: 5.0,
      maxPowerHp: 15,
    ),
    PumpModel(
      manufacturer: 'Grundfos',
      series: 'CR',
      model: 'CR 32-10',
      type: PumpType.verticalMultistage,
      maxFlowGpm: 400,
      maxHeadFt: 250,
      bestEfficiency: 0.76,
      minFlowGpm: 50,
      impellerDiameterIn: 6.5,
      maxPowerHp: 40,
    ),

    // ── Split-case (large flow) ────────────────────────────────
    PumpModel(
      manufacturer: 'Bell & Gossett',
      series: 'Series 4382',
      model: '4x4x9',
      type: PumpType.splitCase,
      maxFlowGpm: 1500,
      maxHeadFt: 150,
      bestEfficiency: 0.85,
      minFlowGpm: 200,
      impellerDiameterIn: 12.5,
      maxPowerHp: 75,
    ),
    PumpModel(
      manufacturer: 'Bell & Gossett',
      series: 'Series 4382',
      model: '6x6x10',
      type: PumpType.splitCase,
      maxFlowGpm: 3000,
      maxHeadFt: 180,
      bestEfficiency: 0.87,
      minFlowGpm: 400,
      impellerDiameterIn: 14.0,
      maxPowerHp: 150,
    ),

    // ── Inline ─────────────────────────────────────────────────
    PumpModel(
      manufacturer: 'Taco',
      series: 'FI',
      model: 'FI 100B',
      type: PumpType.inline,
      maxFlowGpm: 250,
      maxHeadFt: 60,
      bestEfficiency: 0.70,
      minFlowGpm: 30,
      impellerDiameterIn: 7.0,
      maxPowerHp: 5,
    ),
    PumpModel(
      manufacturer: 'Bell & Gossett',
      series: 'Series 80',
      model: '80-4',
      type: PumpType.inline,
      maxFlowGpm: 200,
      maxHeadFt: 50,
      bestEfficiency: 0.68,
      minFlowGpm: 25,
      impellerDiameterIn: 6.0,
      maxPowerHp: 4,
    ),
  ];

  /// Pumps that can meet the required operating point (Q, H).
  /// Returns list sorted by efficiency (descending) — best efficiency first.
  static List<PumpSelectionCandidate> findMatchingPumps({
    required double flowGpm,
    required double headFt,
  }) {
    if (flowGpm <= 0 || headFt <= 0) return const [];

    final candidates = <PumpSelectionCandidate>[];
    for (final pump in all) {
      final cand = _evaluatePump(pump, flowGpm, headFt);
      if (cand != null) candidates.add(cand);
    }

    candidates.sort(
      (a, b) => b.efficiencyAtPoint.compareTo(a.efficiencyAtPoint),
    );
    return candidates;
  }

  static PumpSelectionCandidate? _evaluatePump(
    PumpModel pump,
    double flowGpm,
    double headFt,
  ) {
    // Capacity bounds: pump cannot deliver beyond its max envelope
    if (flowGpm > pump.maxFlowGpm * 1.05) return null;
    if (flowGpm < pump.minFlowGpm * 0.9) return null;
    if (headFt > pump.maxHeadFt * 1.05) return null;

    // Pump curve approximation: parabolic head-flow relationship
    //   H(Q) ≈ H_shutoff × (1 − (Q/Q_max)^n)  with n ≈ 1.5
    // The operating point (Q, H) must lie ON or BELOW this curve, otherwise
    // the pump cannot deliver the required head at that flow.
    final qRatio = flowGpm / pump.maxFlowGpm;
    final curveHeadFt = pump.maxHeadFt * (1.0 - math.pow(qRatio, 1.5).toDouble());
    // Allow 5% tolerance for curve approximation
    if (headFt > curveHeadFt * 1.05) return null;
    final curveDeviation = (headFt - curveHeadFt) / pump.maxHeadFt; // negative = below curve

    // Operating point efficiency: bell curve peaking at ~75% of max flow (BEP)
    final devFromBep = (qRatio - 0.75).abs();
    final efficiencyFactor = (1.0 - devFromBep * 1.2).clamp(0.0, 1.0);
    final efficiencyAtPoint = pump.bestEfficiency * efficiencyFactor;

    // Head margin: how much extra head available at the operating flow
    final headMargin = curveHeadFt - headFt;
    final headMarginPct = pump.maxHeadFt > 0
        ? headMargin / pump.maxHeadFt
        : 0.0;

    // Power at operating point (BHP = ρ g Q H / η)
    const rho = 62.4; // lb/ft³ (water)
    const hpFtLbs = 550.0; // 1 HP = 550 ft·lb/s
    final qFt3s = flowGpm * 0.002228; // GPM → ft³/s
    final waterPowerFtLbS = rho * qFt3s * headFt;
    final bhp = efficiencyAtPoint > 0
        ? waterPowerFtLbS / (efficiencyAtPoint * hpFtLbs)
        : double.infinity;

    // Specific speed (N_s = N × Q^0.5 / H^0.75) — 3500 RPM assumed
    const rpm = 3500.0;
    final specificSpeed = rpm * math.sqrt(flowGpm) / math.pow(headFt, 0.75);

    return PumpSelectionCandidate(
      pump: pump,
      efficiencyAtPoint: efficiencyAtPoint,
      headMarginFt: headMargin,
      headMarginPct: headMarginPct,
      brakePowerHp: bhp,
      specificSpeed: specificSpeed.toDouble(),
      flowOperatingRatio: qRatio,
    );
  }

  /// Returns localized name for the pump type.
  static String getPumpTypeVi(PumpType t) {
    switch (t) {
      case PumpType.endSuction:
        return 'End-suction';
      case PumpType.inline:
        return 'Inline';
      case PumpType.verticalMultistage:
        return 'Vertical multistage';
      case PumpType.splitCase:
        return 'Split-case';
      case PumpType.circulator:
        return 'Circulator';
    }
  }
}

/// A specific pump evaluated at a given operating point.
class PumpSelectionCandidate {
  final PumpModel pump;
  final double efficiencyAtPoint; // 0.0–1.0
  final double headMarginFt; // shutoff head − required head
  final double headMarginPct; // margin as fraction of max head
  final double brakePowerHp; // BHP at operating point
  final double specificSpeed; // N_s for affinity-law scaling
  final double flowOperatingRatio; // Q_operating / Q_max

  const PumpSelectionCandidate({
    required this.pump,
    required this.efficiencyAtPoint,
    required this.headMarginFt,
    required this.headMarginPct,
    required this.brakePowerHp,
    required this.specificSpeed,
    required this.flowOperatingRatio,
  });
}
