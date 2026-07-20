enum TemperatureUnit { celsius, fahrenheit, kelvin }

class TemperatureConverter {
  static double toCelsius(double value, TemperatureUnit from) {
    switch (from) {
      case TemperatureUnit.celsius:
        return value;
      case TemperatureUnit.fahrenheit:
        return (value - 32) * 5 / 9;
      case TemperatureUnit.kelvin:
        return value - 273.15;
    }
  }

  static double fromCelsius(double celsius, TemperatureUnit to) {
    switch (to) {
      case TemperatureUnit.celsius:
        return celsius;
      case TemperatureUnit.fahrenheit:
        return (celsius * 9 / 5) + 32;
      case TemperatureUnit.kelvin:
        return celsius + 273.15;
    }
  }

  static double convert(
    double value,
    TemperatureUnit from,
    TemperatureUnit to,
  ) {
    if (from == to) return value;
    return fromCelsius(toCelsius(value, from), to);
  }

  static String label(TemperatureUnit unit) {
    switch (unit) {
      case TemperatureUnit.celsius:
        return '°C';
      case TemperatureUnit.fahrenheit:
        return '°F';
      case TemperatureUnit.kelvin:
        return 'K';
    }
  }

  static List<TemperatureUnit> get all => TemperatureUnit.values;
}

enum TemperatureDeltaUnit { celsius, fahrenheit, kelvin }

class TemperatureDeltaConverter {
  static double toKelvin(double value, TemperatureDeltaUnit from) {
    switch (from) {
      case TemperatureDeltaUnit.celsius:
        return value;
      case TemperatureDeltaUnit.fahrenheit:
        return value * 5 / 9;
      case TemperatureDeltaUnit.kelvin:
        return value;
    }
  }

  static double fromKelvin(double kelvin, TemperatureDeltaUnit to) {
    switch (to) {
      case TemperatureDeltaUnit.celsius:
        return kelvin;
      case TemperatureDeltaUnit.fahrenheit:
        return kelvin * 9 / 5;
      case TemperatureDeltaUnit.kelvin:
        return kelvin;
    }
  }

  static double convert(
    double value,
    TemperatureDeltaUnit from,
    TemperatureDeltaUnit to,
  ) {
    if (from == to) return value;
    return fromKelvin(toKelvin(value, from), to);
  }

  static String label(TemperatureDeltaUnit unit) {
    switch (unit) {
      case TemperatureDeltaUnit.celsius:
        return '°C';
      case TemperatureDeltaUnit.fahrenheit:
        return '°F';
      case TemperatureDeltaUnit.kelvin:
        return 'K';
    }
  }

  static List<TemperatureDeltaUnit> get all => TemperatureDeltaUnit.values;
}
