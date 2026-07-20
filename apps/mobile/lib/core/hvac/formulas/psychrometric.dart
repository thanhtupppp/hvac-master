import 'dart:math';

// Buck equation constants (Magnus-Tetens approximation, valid 0–60°C)
// Source: Buck (1981), ASHRAE Handbook — Fundamentals
const double _buckA = 17.502;
const double _buckB = 240.97;
const double _satPressureCoeff = 0.61121; // kPa at 0°C

double saturationVaporPressure(double tempC) {
  return _satPressureCoeff * exp(_buckA * tempC / (tempC + _buckB));
}

double dewPoint(double tempC, double relativeHumidity) {
  if (relativeHumidity <= 0 || relativeHumidity > 100) return double.nan;
  final gamma =
      log(relativeHumidity / 100) + (_buckA * tempC) / (_buckB + tempC);
  return _buckB * gamma / (_buckA - gamma);
}

double humidityRatio(double tempC, double rh, {double pressureKpa = 101.325}) {
  if (rh <= 0 || tempC.isNaN) return double.nan;
  final pvKpa = saturationVaporPressure(tempC) * rh / 100;
  if (pvKpa >= pressureKpa) return double.nan;
  return 0.622 * pvKpa / (pressureKpa - pvKpa);
}

double wetBulbTemperature(double tempC, double rh) {
  if (rh <= 0 || rh > 100) return double.nan;
  if (tempC.isNaN) return double.nan;
  return tempC *
      (1 -
          exp(
            -0.0007 * humidityRatio(tempC, 100) * (tempC - dewPoint(tempC, rh)),
          ));
}
