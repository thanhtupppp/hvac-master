class CoolingLoadResult {
  final double totalLoadW;
  final double sensibleLoadW;
  final double latentLoadW;
  final double flowRateLs;
  final double airflowLs;

  const CoolingLoadResult({
    required this.totalLoadW,
    required this.sensibleLoadW,
    required this.latentLoadW,
    required this.flowRateLs,
    required this.airflowLs,
  });

  double get tons => totalLoadW / 3516.85;
  double get btuh => totalLoadW * 3.41214;
}

class CoolingLoad {
  static const double _rhoAir = 1.2;
  static const double _cpAir = 1006;

  static CoolingLoadResult calculate({
    required double roomAreaM2,
    required double roomHeightM,
    required double coolingLoadDensityWPerM2,
    required double sensibleFraction,
    required double supplyAirTempDiffK,
    required double chilledWaterDeltaTK,
    double? infiltrationRate,
    int? occupantCount,
  }) {
    final volume = roomAreaM2 * roomHeightM;

    final totalLoadW = roomAreaM2 * coolingLoadDensityWPerM2;
    final sensibleLoadW = totalLoadW * sensibleFraction;
    final latentLoadW = totalLoadW * (1 - sensibleFraction);

    final airflowLs = sensibleLoadW / (_rhoAir * _cpAir * supplyAirTempDiffK);

    final infiltrationLoad = infiltrationRate != null
        ? infiltrationRate *
              volume *
              _rhoAir *
              _cpAir *
              supplyAirTempDiffK /
              3600
        : 0.0;

    final occupantLoad = occupantCount != null ? occupantCount * 100.0 : 0.0;

    final totalWithExtras = totalLoadW + infiltrationLoad + occupantLoad;
    final flowRateLs = chilledWaterDeltaTK > 0
        ? totalWithExtras / (4186 * _rhoAir * chilledWaterDeltaTK)
        : 0.0;

    return CoolingLoadResult(
      totalLoadW: totalWithExtras,
      sensibleLoadW: sensibleLoadW + infiltrationLoad + occupantLoad,
      latentLoadW: latentLoadW,
      flowRateLs: flowRateLs,
      airflowLs: airflowLs,
    );
  }

  static const Map<String, double> loadDensityTable = {
    'Residential': 50,
    'Office': 80,
    'Retail': 120,
    'Server room': 300,
    'Kitchen': 200,
    'Hospital': 150,
  };
}
