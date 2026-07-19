enum PowerUnit { w, kw, mw, btuHr, ton, hp, kcalHr }

class PowerConverter {
  static const double _wPerKw = 1e3;
  static const double _wPerMw = 1e6;
  static const double _wPerBtuHr = 0.29307107;
  static const double _wPerTon = 3516.8525;
  static const double _wPerHp = 745.7;
  static const double _wPerKcalHr = 1.163;

  static double toWatts(double value, PowerUnit from) {
    switch (from) {
      case PowerUnit.w:      return value;
      case PowerUnit.kw:     return value * _wPerKw;
      case PowerUnit.mw:     return value * _wPerMw;
      case PowerUnit.btuHr:  return value * _wPerBtuHr;
      case PowerUnit.ton:    return value * _wPerTon;
      case PowerUnit.hp:     return value * _wPerHp;
      case PowerUnit.kcalHr: return value * _wPerKcalHr;
    }
  }

  static double fromWatts(double watts, PowerUnit to) {
    switch (to) {
      case PowerUnit.w:      return watts;
      case PowerUnit.kw:     return watts / _wPerKw;
      case PowerUnit.mw:     return watts / _wPerMw;
      case PowerUnit.btuHr:  return watts / _wPerBtuHr;
      case PowerUnit.ton:    return watts / _wPerTon;
      case PowerUnit.hp:     return watts / _wPerHp;
      case PowerUnit.kcalHr: return watts / _wPerKcalHr;
    }
  }

  static double convert(double value, PowerUnit from, PowerUnit to) {
    if (from == to) return value;
    return fromWatts(toWatts(value, from), to);
  }

  static String label(PowerUnit unit) {
    switch (unit) {
      case PowerUnit.w:      return 'W';
      case PowerUnit.kw:     return 'kW';
      case PowerUnit.mw:     return 'MW';
      case PowerUnit.btuHr:  return 'BTU/h';
      case PowerUnit.ton:    return 'Tấn lạnh';
      case PowerUnit.hp:     return 'HP';
      case PowerUnit.kcalHr: return 'kcal/h';
    }
  }

  static List<PowerUnit> get all => PowerUnit.values;
}
