/// Fitting types with their K-coefficients by size category.
enum FittingType {
  // Straight run fittings
  returnBendR1D,
  returnBendR3D,
  returnBendMitered,
  miterBend90,
  // Tees
  teeBranchThreaded,
  teeBranchSoldered,
  teeBranchWelded,
  teeThroughThreaded,
  teeThroughSoldered,
  teeThroughWelded,
  teeSaddle,
  // Elbows
  elbow90Threaded,
  elbow90ButtWeld,
  elbow90Flanged,
  elbow90Mitered,
  elbow45Threaded,
  elbow45ButtWeld,
  elbow45Flanged,
  elbow180Threaded,
  elbow180ButtWeld,
  // Reducers/Expanders
  reducerConcentric,
  reducerEccentric,
  // Valves (fully open)
  valveGate,
  valveGlobe,
  valveAngle,
  valveBall,
  valveButterfly,
  valveCheckSwing,
  valveCheckLift,
  valveCheckTiltingDisk,
  // Entrance/Exit
  entranceNormal,
  entranceSharpEdged,
  entranceRounded,
  exitNormal,
  exitProjecting,
  expanderConcentric,
  expanderEccentric,
}

/// K-values for a fitting type.
/// Keys are nominal pipe sizes encoded as sixteenths of an inch:
///   8  = 0.5"   16 = 1.0"   32 = 2.0"
///   24 = 1.5"   40 = 2.5"   48 = 3.0"
///   64 = 4.0"   80 = 5.0"   96 = 6.0"
///  128 = 8.0"  160 = 10.0" 192 = 12.0"
class FittingKValues {
  final Map<int, double> threaded;
  final Map<int, double> buttWeld;
  final Map<int, double> flanged;
  final Map<int, double> soldered;

  const FittingKValues({
    this.threaded = const {},
    this.buttWeld = const {},
    this.flanged = const {},
    this.soldered = const {},
  });

  /// Get K value for a given nominal size in inches.
  double kFor(double nominalIn, String connectionType) {
    final sixteenths = _toSixteenths(nominalIn);
    final map = _mapFor(connectionType);
    return map[sixteenths] ?? _closest(sixteenths, map.keys.toList()) ?? 1.0;
  }

  Map<int, double> _mapFor(String connType) {
    switch (connType) {
      case 'threaded':
      case 'screwed':
        return threaded;
      case 'butt_weld':
      case 'weld':
      case 'welded':
        return buttWeld;
      case 'flanged':
        return flanged;
      case 'soldered':
      case 'solder':
      case 'copper':
        return soldered;
      default:
        return threaded.isNotEmpty ? threaded : buttWeld;
    }
  }

  double? _closest(int sixteenths, List<int> sizes) {
    if (sizes.isEmpty) return null;
    int best = sizes.first;
    int bestDiff = (sizes.first - sixteenths).abs();
    for (final s in sizes) {
      final diff = (s - sixteenths).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = s;
      }
    }
    return _mapFor('')[best];
  }

  static int _toSixteenths(double inches) => (inches * 16).round();
}

/// Default K when specific size is not in catalog.
const double kDefault = 1.0;

// ─────────────────────────────────────────────────────────────
// CATALOG  (keys = nominal size in sixteenths of an inch)
// ─────────────────────────────────────────────────────────────

final Map<FittingType, FittingKValues> fittingCatalog = {
  FittingType.elbow90Threaded: const FittingKValues(
    threaded: {
      8: 1.5,
      12: 1.4,
      16: 1.1,
      20: 1.1,
      24: 0.90,
      32: 0.75,
      40: 0.70,
      48: 0.70,
      64: 0.66,
      80: 0.66,
      96: 0.66,
    },
  ),
  FittingType.elbow90ButtWeld: const FittingKValues(
    buttWeld: {
      16: 0.90,
      24: 0.90,
      32: 0.90,
      48: 0.90,
      64: 0.90,
      96: 0.90,
      128: 0.90,
      160: 0.90,
      192: 0.90,
    },
  ),
  FittingType.elbow90Flanged: const FittingKValues(
    flanged: {
      16: 0.60,
      24: 0.60,
      32: 0.60,
      48: 0.60,
      64: 0.60,
      80: 0.60,
      96: 0.60,
      128: 0.60,
      160: 0.60,
      192: 0.60,
    },
  ),
  FittingType.elbow90Mitered: const FittingKValues(
    threaded: {16: 2.2, 24: 2.2, 32: 2.2, 48: 2.2, 64: 2.2, 96: 2.2, 128: 2.2},
  ),
  FittingType.elbow45Threaded: const FittingKValues(
    threaded: {
      8: 0.40,
      12: 0.36,
      16: 0.30,
      20: 0.30,
      24: 0.24,
      32: 0.20,
      40: 0.19,
      48: 0.19,
      64: 0.18,
      80: 0.18,
      96: 0.18,
    },
  ),
  FittingType.elbow45ButtWeld: const FittingKValues(
    buttWeld: {
      16: 0.45,
      24: 0.45,
      32: 0.45,
      48: 0.45,
      64: 0.45,
      96: 0.45,
      128: 0.45,
    },
  ),
  FittingType.elbow45Flanged: const FittingKValues(
    flanged: {
      16: 0.30,
      24: 0.30,
      32: 0.30,
      48: 0.30,
      64: 0.30,
      96: 0.30,
      128: 0.30,
    },
  ),
  FittingType.returnBendR1D: const FittingKValues(
    threaded: {
      8: 2.3,
      12: 2.3,
      16: 2.2,
      24: 2.0,
      32: 1.8,
      40: 1.7,
      48: 1.6,
      64: 1.5,
      80: 1.4,
      96: 1.4,
    },
  ),
  FittingType.returnBendR3D: const FittingKValues(
    threaded: {16: 0.80, 24: 0.70, 32: 0.60, 48: 0.55, 64: 0.50, 96: 0.50},
    buttWeld: {16: 0.60, 24: 0.50, 32: 0.50, 48: 0.40, 64: 0.40, 96: 0.40},
    flanged: {16: 0.50, 24: 0.40, 32: 0.40, 48: 0.30, 64: 0.30, 96: 0.30},
  ),
  FittingType.teeBranchThreaded: const FittingKValues(
    threaded: {
      8: 1.5,
      12: 1.4,
      16: 1.3,
      20: 1.3,
      24: 1.2,
      32: 1.1,
      40: 1.1,
      48: 1.1,
      64: 1.0,
      80: 1.0,
      96: 1.0,
    },
  ),
  FittingType.teeBranchSoldered: const FittingKValues(
    soldered: {
      8: 1.4,
      12: 1.3,
      16: 1.2,
      20: 1.2,
      24: 1.1,
      32: 1.0,
      40: 1.0,
      48: 1.0,
      64: 0.95,
      80: 0.95,
      96: 0.95,
    },
  ),
  FittingType.teeBranchWelded: const FittingKValues(
    buttWeld: {
      16: 1.0,
      24: 1.0,
      32: 1.0,
      40: 1.0,
      48: 1.0,
      64: 0.95,
      96: 0.90,
      128: 0.90,
      160: 0.90,
      192: 0.90,
    },
  ),
  FittingType.teeThroughThreaded: const FittingKValues(
    threaded: {
      8: 0.90,
      12: 0.90,
      16: 0.90,
      20: 0.90,
      24: 0.90,
      32: 0.90,
      40: 0.90,
      48: 0.90,
      64: 0.90,
      80: 0.90,
      96: 0.90,
    },
  ),
  FittingType.teeThroughSoldered: const FittingKValues(
    soldered: {
      8: 0.70,
      12: 0.70,
      16: 0.70,
      20: 0.70,
      24: 0.70,
      32: 0.70,
      40: 0.70,
      48: 0.70,
      64: 0.70,
      80: 0.70,
      96: 0.70,
    },
  ),
  FittingType.teeThroughWelded: const FittingKValues(
    buttWeld: {
      16: 0.60,
      24: 0.60,
      32: 0.60,
      40: 0.60,
      48: 0.60,
      64: 0.60,
      96: 0.60,
      128: 0.60,
      160: 0.60,
      192: 0.60,
    },
  ),
  FittingType.valveGate: const FittingKValues(
    threaded: {
      8: 0.22,
      12: 0.18,
      16: 0.14,
      20: 0.11,
      24: 0.09,
      32: 0.08,
      40: 0.07,
      48: 0.07,
      64: 0.06,
      80: 0.06,
      96: 0.06,
    },
    flanged: {
      8: 0.12,
      12: 0.10,
      16: 0.08,
      20: 0.08,
      24: 0.06,
      32: 0.05,
      40: 0.05,
      48: 0.05,
      64: 0.04,
      96: 0.04,
      128: 0.04,
      160: 0.04,
    },
  ),
  FittingType.valveGlobe: const FittingKValues(
    threaded: {
      8: 6.9,
      12: 6.1,
      16: 5.5,
      20: 5.1,
      24: 4.5,
      32: 4.1,
      40: 3.7,
      48: 3.4,
      64: 3.0,
      80: 2.8,
      96: 2.5,
    },
    flanged: {
      16: 6.0,
      24: 5.0,
      32: 4.5,
      40: 4.0,
      48: 3.5,
      64: 3.0,
      96: 2.5,
      128: 2.5,
      160: 2.5,
    },
  ),
  FittingType.valveAngle: const FittingKValues(
    threaded: {
      8: 3.0,
      12: 2.5,
      16: 2.0,
      20: 1.8,
      24: 1.6,
      32: 1.4,
      40: 1.1,
      48: 0.90,
      64: 0.70,
      80: 0.55,
      96: 0.40,
    },
    flanged: {
      16: 2.5,
      24: 2.0,
      32: 1.5,
      48: 1.0,
      64: 0.80,
      96: 0.50,
      128: 0.50,
    },
  ),
  FittingType.valveBall: const FittingKValues(
    threaded: {
      8: 0.05,
      12: 0.05,
      16: 0.05,
      20: 0.04,
      24: 0.04,
      32: 0.03,
      40: 0.03,
      48: 0.03,
      64: 0.02,
      80: 0.02,
      96: 0.02,
    },
  ),
  FittingType.valveButterfly: const FittingKValues(
    flanged: {
      24: 0.40,
      32: 0.30,
      48: 0.25,
      64: 0.15,
      96: 0.10,
      128: 0.09,
      160: 0.08,
      192: 0.08,
      224: 0.08,
      256: 0.08,
    },
  ),
  FittingType.valveCheckSwing: const FittingKValues(
    threaded: {
      8: 2.5,
      12: 2.3,
      16: 2.1,
      20: 1.8,
      24: 1.7,
      32: 1.5,
      40: 1.4,
      48: 1.3,
      64: 1.2,
      80: 1.1,
      96: 1.1,
    },
    flanged: {
      16: 2.0,
      24: 1.7,
      32: 1.5,
      48: 1.2,
      64: 1.0,
      96: 0.90,
      128: 0.90,
      160: 0.80,
      192: 0.80,
    },
  ),
  FittingType.valveCheckLift: const FittingKValues(
    threaded: {
      8: 12.0,
      12: 10.0,
      16: 8.0,
      20: 7.0,
      24: 6.0,
      32: 5.0,
      40: 4.5,
      48: 4.0,
      64: 3.5,
      80: 3.0,
      96: 3.0,
    },
  ),
  FittingType.reducerConcentric: const FittingKValues(
    threaded: {16: 0.30, 24: 0.25, 32: 0.20, 48: 0.15, 64: 0.12, 96: 0.10},
    buttWeld: {
      16: 0.30,
      24: 0.25,
      32: 0.20,
      48: 0.15,
      64: 0.12,
      96: 0.10,
      128: 0.08,
      160: 0.08,
      192: 0.08,
    },
    flanged: {
      16: 0.30,
      24: 0.25,
      32: 0.20,
      48: 0.15,
      64: 0.12,
      96: 0.10,
      128: 0.08,
      160: 0.08,
      192: 0.08,
    },
  ),
  FittingType.reducerEccentric: const FittingKValues(
    threaded: {16: 0.30, 24: 0.25, 32: 0.20, 48: 0.15, 64: 0.12, 96: 0.10},
    buttWeld: {
      16: 0.30,
      24: 0.25,
      32: 0.20,
      48: 0.15,
      64: 0.12,
      96: 0.10,
      128: 0.08,
      160: 0.08,
      192: 0.08,
    },
    flanged: {
      16: 0.30,
      24: 0.25,
      32: 0.20,
      48: 0.15,
      64: 0.12,
      96: 0.10,
      128: 0.08,
      160: 0.08,
      192: 0.08,
    },
  ),
  FittingType.entranceNormal: const FittingKValues(
    threaded: {
      8: 0.50,
      12: 0.50,
      16: 0.50,
      24: 0.50,
      32: 0.50,
      48: 0.50,
      64: 0.50,
      96: 0.50,
      128: 0.50,
    },
  ),
  FittingType.entranceSharpEdged: const FittingKValues(
    threaded: {
      8: 0.78,
      12: 0.78,
      16: 0.78,
      24: 0.78,
      32: 0.78,
      48: 0.78,
      64: 0.78,
      96: 0.78,
    },
  ),
  FittingType.exitNormal: const FittingKValues(
    threaded: {
      8: 1.00,
      12: 1.00,
      16: 1.00,
      24: 1.00,
      32: 1.00,
      48: 1.00,
      64: 1.00,
      96: 1.00,
      128: 1.00,
    },
  ),
  FittingType.miterBend90: const FittingKValues(
    buttWeld: {
      64: 1.1,
      96: 1.0,
      128: 1.0,
      160: 1.0,
      192: 1.0,
      256: 1.0,
      320: 1.0,
      384: 1.0,
    },
  ),
};

/// Get display name (Vietnamese) for a fitting type.
String getFittingNameVi(FittingType type) {
  switch (type) {
    case FittingType.elbow90Threaded:
      return 'Elbow 90° (Ren)';
    case FittingType.elbow90ButtWeld:
      return 'Elbow 90° (Hàn)';
    case FittingType.elbow90Flanged:
      return 'Elbow 90° (Bích)';
    case FittingType.elbow90Mitered:
      return 'Elbow 90° Miter';
    case FittingType.elbow45Threaded:
      return 'Elbow 45° (Ren)';
    case FittingType.elbow45ButtWeld:
      return 'Elbow 45° (Hàn)';
    case FittingType.elbow45Flanged:
      return 'Elbow 45° (Bích)';
    case FittingType.elbow180Threaded:
      return 'Elbow 180° (Ren)';
    case FittingType.elbow180ButtWeld:
      return 'Elbow 180° (Hàn)';
    case FittingType.returnBendR1D:
      return 'Return Bend R=1D';
    case FittingType.returnBendR3D:
      return 'Return Bend R=3D';
    case FittingType.returnBendMitered:
      return 'Return Bend Mitered';
    case FittingType.teeBranchThreaded:
      return 'Tee nhánh (Ren)';
    case FittingType.teeBranchSoldered:
      return 'Tee nhánh (Hàn)';
    case FittingType.teeBranchWelded:
      return 'Tee nhánh (Hàn butt)';
    case FittingType.teeThroughThreaded:
      return 'Tee thẳng (Ren)';
    case FittingType.teeThroughSoldered:
      return 'Tee thẳng (Hàn)';
    case FittingType.teeThroughWelded:
      return 'Tee thẳng (Hàn butt)';
    case FittingType.valveGate:
      return 'Van Cửa (Gate)';
    case FittingType.valveGlobe:
      return 'Van Globe';
    case FittingType.valveAngle:
      return 'Van Góc (Angle)';
    case FittingType.valveBall:
      return 'Van Bi (Ball)';
    case FittingType.valveButterfly:
      return 'Van Bướm (Butterfly)';
    case FittingType.valveCheckSwing:
      return 'Van Một Chiều (Swing)';
    case FittingType.valveCheckLift:
      return 'Van Một Chiều (Lift)';
    case FittingType.valveCheckTiltingDisk:
      return 'Van Một Chiều (Tilting)';
    case FittingType.reducerConcentric:
      return 'Co Thu Đồng Tâm';
    case FittingType.reducerEccentric:
      return 'Co Thu Lệch Tâm';
    case FittingType.expanderConcentric:
      return 'Co Giãn Đồng Tâm';
    case FittingType.expanderEccentric:
      return 'Co Giãn Lệch Tâm';
    case FittingType.entranceNormal:
      return 'Lỗ Vào Bình Thường';
    case FittingType.entranceSharpEdged:
      return 'Lỗ Vào Sắc Cạnh';
    case FittingType.entranceRounded:
      return 'Lỗ Vào Bo Tròn';
    case FittingType.exitNormal:
      return 'Lỗ Ra Bình Thường';
    case FittingType.exitProjecting:
      return 'Lỗ Ra Nhô Ra';
    case FittingType.miterBend90:
      return 'Miter Bend 90°';
    case FittingType.teeSaddle:
      return 'Tee Saddle';
  }
}
