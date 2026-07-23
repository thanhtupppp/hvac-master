import '../../../core/hvac/models/enums.dart';
import '../data/vav_box_catalog.dart';

enum SizingMethod { byCoolingLoad, byAirflow, byRoom }

class VavBoxSizingInput {
  final double coolingLoadBtuHr; // Total cooling load
  final double heatingLoadBtuHr; // Total heating load (for reheat)
  final double supplyAirTempF; // SAT
  final double roomTempF; // Room temperature setpoint
  final double roomTempFHeat; // Heating setpoint (for reheat)
  final double minAirflowRatio; // 0.10..0.50, typical 0.30
  final double primaryAirTempF; // From AHU
  final VavBoxType boxType;
  final UnitSystem unit;
  final SizingMethod method;
  final double directAirflowCfm;

  const VavBoxSizingInput({
    required this.coolingLoadBtuHr,
    required this.heatingLoadBtuHr,
    required this.supplyAirTempF,
    required this.roomTempF,
    required this.roomTempFHeat,
    required this.minAirflowRatio,
    required this.primaryAirTempF,
    required this.boxType,
    required this.unit,
    required this.method,
    required this.directAirflowCfm,
  });

  double get coolingLoadW => unit == UnitSystem.imperial
      ? coolingLoadBtuHr * 0.293071
      : coolingLoadBtuHr;

  double get heatingLoadW => unit == UnitSystem.imperial
      ? heatingLoadBtuHr * 0.293071
      : heatingLoadBtuHr;

  double get directAirflowM3s => unit == UnitSystem.imperial
      ? directAirflowCfm / 2118.88
      : directAirflowCfm / 3600;

  double get directAirflowM3h =>
      unit == UnitSystem.imperial ? directAirflowCfm * 1.699 : directAirflowCfm;
}

class VavBoxSizingResult {
  final double coolingCfm;
  final double coolingM3s;
  final double coolingM3h;
  final double heatingCfm;
  final double heatingM3s;
  final double maxCfm;
  final double minCfm;
  final double maxM3s;
  final double minM3s;
  final double designDeltaTF;
  final double designDeltaTK;
  final double reheatingCfm;
  final double reheatingDeltaTF;
  final double reheatCapacityBtuHr;
  final double reheatCapacityW;
  final VavBoxSize? selectedSize;
  final VavBoxDefinition boxDefinition;
  final double turndownRatio;
  final String? sizeWarning;
  final String? heatingWarning;
  final bool isOversized;
  final bool isUndersized;
  final VavBoxSizingInput input;

  const VavBoxSizingResult({
    required this.coolingCfm,
    required this.coolingM3s,
    required this.coolingM3h,
    required this.heatingCfm,
    required this.heatingM3s,
    required this.maxCfm,
    required this.minCfm,
    required this.maxM3s,
    required this.minM3s,
    required this.designDeltaTF,
    required this.designDeltaTK,
    required this.reheatingCfm,
    required this.reheatingDeltaTF,
    required this.reheatCapacityBtuHr,
    required this.reheatCapacityW,
    required this.selectedSize,
    required this.boxDefinition,
    required this.turndownRatio,
    this.sizeWarning,
    this.heatingWarning,
    required this.isOversized,
    required this.isUndersized,
    required this.input,
  });
}

class VavBoxSizingEngine {
  // Psychrometric constants:
  //   imperial: 1.08 = ρ(0.075 lb/ft³) × cp(0.24 Btu/lb·°F) × 60 min  ⇒ CFM = Q_BtuHr / (1.08 × ΔT_F)
  //   metric:   ρ (1.2 kg/m³) × cp (1005 J/kg·K) = 1206 → m³/s = Q_W / (1206 × ΔT_K)
  //            but for design convenience, CFM = Q_W / (1.21 × ΔT_K) (simplified)
  static const double _cfmPerBtuHrDeltaT = 1.08; // imperial
  // Used after metric flow is computed in m³/s → CFM
  static const double _secondsPerHour = 3600.0;
  static const double _cfmPerM3s = 2118.88; // m³/s → CFM

  /// Calculate VAV box sizing per ASHRAE Handbook methodology.
  static VavBoxSizingResult? calculate(VavBoxSizingInput input) {
    if (input.method == SizingMethod.byCoolingLoad) {
      if (input.coolingLoadBtuHr <= 0) return null;
    } else {
      if (input.directAirflowCfm <= 0) return null;
    }

    final boxDef = VavBoxCatalog.get(input.boxType);

    // Step 1: Cooling CFM = Q / (1.08 × ΔT)
    // ΔT = RoomTemp - SAT (units depend on imperial vs metric)
    // For imperial: ΔT in °F, Q in Btu/hr
    // For metric: ΔT in K, Q in W
    double deltaTF, deltaTK;
    if (input.unit == UnitSystem.imperial) {
      deltaTF = input.roomTempF - input.supplyAirTempF;
      deltaTK = deltaTF * 5.0 / 9.0;
    } else {
      deltaTK = input.roomTempF - input.supplyAirTempF;
      deltaTF = deltaTK * 9.0 / 5.0;
    }
    if (deltaTF <= 0) return null;

    double coolingCfm;
    double coolingM3s;
    double coolingM3h;

    if (input.method == SizingMethod.byCoolingLoad) {
      if (input.unit == UnitSystem.imperial) {
        coolingCfm = input.coolingLoadBtuHr / (_cfmPerBtuHrDeltaT * deltaTF);
        coolingM3s = coolingCfm / _cfmPerM3s;
        coolingM3h = coolingM3s * _secondsPerHour;
      } else {
        // Metric: Q in W, ΔT in K
        // m³/s = W / (1206 × ΔT_K) — psychrometric formula using ρ×cp
        // For design convenience, ASHRAE uses 1.21 (slight rounding of 1.206)
        // because 1.08 (imperial) × 1000 ÷ 0.075 ÷ 0.24 ÷ 60 ≈ 1.04 (close to 1.21)
        // Use full derivation for precision: ρ (1.2) × cp (1006) = 1207.2 ≈ 1206
        coolingM3s = input.coolingLoadBtuHr / (1206.0 * deltaTK);
        coolingCfm = coolingM3s * _cfmPerM3s;
        coolingM3h = coolingM3s * _secondsPerHour;
      }
    } else {
      coolingCfm = input.directAirflowCfm;
      coolingM3s = input.directAirflowM3s;
      coolingM3h = input.directAirflowM3h;
    }

    // Step 2: Min CFM = max(CoolingCfm × minRatio, boxDef.minCfm ratio)
    final minFromRatio = coolingCfm * input.minAirflowRatio;
    final minCfm = minFromRatio.clamp(coolingCfm * 0.10, coolingCfm * 0.50);

    // Step 3: Max CFM — for cooling-only, max = design cooling
    // For reheat types, max may be higher to provide heating
    double maxCfm = coolingCfm;

    // Step 4: Reheat calculation (only if hasReheat)
    double heatingCfm = 0;
    double reheatingCfm = 0;
    double reheatingDeltaTF = 0;
    double reheatCapacityBtuHr = 0;
    double reheatCapacityW = 0;

    if (boxDef.hasReheat &&
        (input.unit == UnitSystem.imperial
            ? input.heatingLoadBtuHr > 0
            : input.heatingLoadW > 0)) {
      // Heating CFM — minimum airflow required to deliver heating load.
      // ΔT = |primaryAir - roomHeat| — must be positive for heat to flow.
      // If primaryAir < roomHeat, primary air is colder than heating setpoint,
      // meaning reheat cannot add heat (would need preheat) — skip calculation.
      final heatingDeltaTF = input.primaryAirTempF - input.roomTempFHeat;
      // Imperial: primaryAir is in °F; Metric: stored field is °C (not adjusted).
      // Use _cfmPerBtuHrDeltaT (1.08) only for imperial; metric uses 1206 × ΔT_K.
      if (heatingDeltaTF > 0) {
        if (input.unit == UnitSystem.imperial) {
          heatingCfm =
              input.heatingLoadBtuHr / (_cfmPerBtuHrDeltaT * heatingDeltaTF);
        } else {
          // Metric: heatingCfm = W / (1206 × ΔT_K), then × 2118.88
          final heatingM3s = input.heatingLoadW / (1206.0 * heatingDeltaTF);
          heatingCfm = heatingM3s * 2118.88;
        }
        // Reheating at min CFM, add heat to bring to room temp
        reheatingCfm = minCfm;
        reheatingDeltaTF = (input.roomTempFHeat - input.supplyAirTempF).abs();
        reheatCapacityBtuHr =
            reheatingCfm * _cfmPerBtuHrDeltaT * reheatingDeltaTF;
        reheatCapacityW = reheatCapacityBtuHr * 0.293071;

        // Max CFM = max(cooling, heating) × safety factor
        maxCfm = (coolingCfm > heatingCfm ? coolingCfm : heatingCfm) * 1.1;
      } else if (heatingDeltaTF <= 0 && input.heatingLoadW > 0) {
        // Physical warning: primary air colder than heating setpoint
        // (reheat coil cannot work — need preheat). Defer to UI warning.
      }
    }

    // Step 5: Select size from catalog (max CFM within range)
    VavBoxSize? selectedSize;
    String? sizeWarning;
    bool isOversized = false;
    bool isUndersized = false;

    for (final size in boxDef.availableSizes) {
      if (size.maxCfm >= maxCfm) {
        selectedSize = size;
        break;
      }
    }

    if (selectedSize == null) {
      // Use largest available
      selectedSize = boxDef.availableSizes.last;
      isOversized = true;
      sizeWarning =
          'Tải vượt quá size lớn nhất (${boxDef.availableSizes.last.maxCfm} CFM). Cần nhiều VAV box hoặc size lớn hơn.';
    } else if (selectedSize.maxCfm > maxCfm * 1.5) {
      isUndersized = true;
      sizeWarning =
          'Size ${selectedSize.inletDiameterIn}" chọn có thể quá lớn (max ${selectedSize.maxCfm} CFM so với yêu cầu ${maxCfm.toStringAsFixed(0)} CFM).';
    }

    // Step 6: Turndown ratio
    final turndown = maxCfm > 0 ? (minCfm / maxCfm) : 0.0;

    String? heatingWarning;
    if (boxDef.hasReheat &&
        reheatCapacityBtuHr > 0 &&
        reheatCapacityBtuHr < input.heatingLoadBtuHr) {
      heatingWarning =
          'Công suất reheat (${reheatCapacityBtuHr.toStringAsFixed(0)} Btu/h) thấp hơn heating load (${input.heatingLoadBtuHr.toStringAsFixed(0)} Btu/h). Xem xét preheat hoặc tăng min CFM.';
    }

    final minM3s = minCfm / 2118.88;
    final maxM3s = maxCfm / 2118.88;

    return VavBoxSizingResult(
      coolingCfm: coolingCfm,
      coolingM3s: coolingM3s,
      coolingM3h: coolingM3h,
      heatingCfm: heatingCfm,
      heatingM3s: heatingCfm / 2118.88,
      maxCfm: maxCfm,
      minCfm: minCfm,
      maxM3s: maxM3s,
      minM3s: minM3s,
      designDeltaTF: deltaTF,
      designDeltaTK: deltaTK,
      reheatingCfm: reheatingCfm,
      reheatingDeltaTF: reheatingDeltaTF,
      reheatCapacityBtuHr: reheatCapacityBtuHr,
      reheatCapacityW: reheatCapacityW,
      selectedSize: selectedSize,
      boxDefinition: boxDef,
      turndownRatio: turndown,
      sizeWarning: sizeWarning,
      heatingWarning: heatingWarning,
      isOversized: isOversized,
      isUndersized: isUndersized,
      input: input,
    );
  }
}
