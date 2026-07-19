double toBarAbs(double val, String unit, bool isGauge, [double atm = 1.01325]) {
  double barAbs = val;
  if (unit == 'PSI') {
    barAbs = val / 14.5037738;
  } else if (unit == 'kPa') {
    barAbs = val / 100.0;
  }

  if (isGauge) {
    barAbs += atm;
  }
  return barAbs;
}

double fromBarAbs(
  double barAbs,
  String unit,
  bool isGauge, [
  double atm = 1.01325,
]) {
  double target = barAbs;
  if (isGauge) {
    target -= atm;
  }

  if (unit == 'PSI') {
    target *= 14.5037738;
  } else if (unit == 'kPa') {
    target *= 100.0;
  }
  return target;
}

double toPascalAbs(
  double val,
  String unit,
  bool isGauge, [
  double atm = 1.01325,
]) {
  double paAbs = val;
  if (unit == 'PSI') {
    paAbs = val * 6894.75729;
  } else if (unit == 'Bar') {
    paAbs = val * 100000.0;
  } else if (unit == 'kPa') {
    paAbs = val * 1000.0;
  }

  if (isGauge) {
    paAbs += atm * 100000.0;
  }
  return paAbs;
}

double fromPascalAbs(
  double paAbs,
  String unit,
  bool isGauge, [
  double atm = 1.01325,
]) {
  double target = paAbs;
  if (isGauge) {
    target -= atm * 100000.0;
  }

  if (unit == 'PSI') {
    target /= 6894.75729;
  } else if (unit == 'Bar') {
    target /= 100000.0;
  } else if (unit == 'kPa') {
    target /= 1000.0;
  }
  return target;
}
