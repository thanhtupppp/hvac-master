import 'dart:math';

const double _a = 17.27;
const double _b = 237.7;

double saturationVaporPressure(double tempC) {
  return exp(_a * tempC / (tempC + _b)) * 6.112;
}

double dewPoint(double tempC, double relativeHumidity) {
  if (relativeHumidity <= 0 || relativeHumidity > 100) return double.nan;
  final gamma = log(relativeHumidity / 100) + (_a * tempC) / (_b + tempC);
  return _b * gamma / (_a - gamma);
}

double humidityRatio(double tempC, double rh, {double pressureKpa = 101.325}) {
  if (rh <= 0 || tempC.isNaN) return double.nan;
  final pv = saturationVaporPressure(tempC) * rh / 100;
  return 0.622 * pv / (pressureKpa - pv);
}

double wetBulbTemperature(double tempC, double rh) {
  if (rh <= 0 || rh > 100) return double.nan;
  if (tempC.isNaN) return double.nan;
  return tempC * (1 - exp(-0.0007 * humidityRatio(tempC, 100) * (tempC - dewPoint(tempC, rh))));
}
