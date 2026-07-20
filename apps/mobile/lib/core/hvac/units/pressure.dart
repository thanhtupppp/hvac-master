enum PressureUnit { pa, kpa, mpa, bar, psi, inhg, mmhg, inh2o }

class PressureConverter {
  static const double _paPerKpa = 1e3;
  static const double _paPerMpa = 1e6;
  static const double _paPerBar = 1e5;
  static const double _paPerPsi = 6894.75729;
  static const double _paPerInHg = 3386.39;
  static const double _paPerMmHg = 133.322;
  static const double _paPerInH2o = 249.089;

  static double toPascal(double value, PressureUnit from) {
    switch (from) {
      case PressureUnit.pa:
        return value;
      case PressureUnit.kpa:
        return value * _paPerKpa;
      case PressureUnit.mpa:
        return value * _paPerMpa;
      case PressureUnit.bar:
        return value * _paPerBar;
      case PressureUnit.psi:
        return value * _paPerPsi;
      case PressureUnit.inhg:
        return value * _paPerInHg;
      case PressureUnit.mmhg:
        return value * _paPerMmHg;
      case PressureUnit.inh2o:
        return value * _paPerInH2o;
    }
  }

  static double fromPascal(double pascal, PressureUnit to) {
    switch (to) {
      case PressureUnit.pa:
        return pascal;
      case PressureUnit.kpa:
        return pascal / _paPerKpa;
      case PressureUnit.mpa:
        return pascal / _paPerMpa;
      case PressureUnit.bar:
        return pascal / _paPerBar;
      case PressureUnit.psi:
        return pascal / _paPerPsi;
      case PressureUnit.inhg:
        return pascal / _paPerInHg;
      case PressureUnit.mmhg:
        return pascal / _paPerMmHg;
      case PressureUnit.inh2o:
        return pascal / _paPerInH2o;
    }
  }

  static double convert(double value, PressureUnit from, PressureUnit to) {
    if (from == to) return value;
    return fromPascal(toPascal(value, from), to);
  }

  static String label(PressureUnit unit) {
    switch (unit) {
      case PressureUnit.pa:
        return 'Pa';
      case PressureUnit.kpa:
        return 'kPa';
      case PressureUnit.mpa:
        return 'MPa';
      case PressureUnit.bar:
        return 'Bar';
      case PressureUnit.psi:
        return 'PSI';
      case PressureUnit.inhg:
        return 'inHg';
      case PressureUnit.mmhg:
        return 'mmHg';
      case PressureUnit.inh2o:
        return 'inH₂O';
    }
  }

  static String description(PressureUnit unit) {
    switch (unit) {
      case PressureUnit.pa:
        return 'Pascal';
      case PressureUnit.kpa:
        return 'Kilopascal';
      case PressureUnit.mpa:
        return 'Megapascal';
      case PressureUnit.bar:
        return 'Bar';
      case PressureUnit.psi:
        return 'Pounds per square inch';
      case PressureUnit.inhg:
        return 'Inches of Mercury';
      case PressureUnit.mmhg:
        return 'Millimeters of Mercury';
      case PressureUnit.inh2o:
        return 'Inches of Water';
    }
  }

  static List<PressureUnit> get all => PressureUnit.values;

  static List<PressureUnit> get common => [
    PressureUnit.bar,
    PressureUnit.psi,
    PressureUnit.kpa,
    PressureUnit.mpa,
  ];
}
