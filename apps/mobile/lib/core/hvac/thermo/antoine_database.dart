class AntoineCoefficients {
  final double a1;
  final double a2;
  final double a3;
  final double tMin;
  final double tMax;

  const AntoineCoefficients({
    required this.a1,
    required this.a2,
    required this.a3,
    required this.tMin,
    required this.tMax,
  });
}

const Map<String, Map<String, AntoineCoefficients>> antoineDatabase = {
  'R22': {
    'bubble': AntoineCoefficients(
      a1: 9.748,
      a2: -2017.2,
      a3: 247.8,
      tMin: -70.0,
      tMax: 96.15,
    ),
    'dew': AntoineCoefficients(
      a1: 9.748,
      a2: -2017.2,
      a3: 247.8,
      tMin: -70.0,
      tMax: 96.15,
    ),
  },
  'R32': {
    'bubble': AntoineCoefficients(
      a1: 10.271,
      a2: -2059.6,
      a3: 252.1,
      tMin: -70.0,
      tMax: 78.11,
    ),
    'dew': AntoineCoefficients(
      a1: 10.271,
      a2: -2059.6,
      a3: 252.1,
      tMin: -70.0,
      tMax: 78.11,
    ),
  },
  'R134a': {
    'bubble': AntoineCoefficients(
      a1: 9.936,
      a2: -2147.9,
      a3: 242.3,
      tMin: -70.0,
      tMax: 101.06,
    ),
    'dew': AntoineCoefficients(
      a1: 9.936,
      a2: -2147.9,
      a3: 242.3,
      tMin: -70.0,
      tMax: 101.06,
    ),
  },
  'R410A': {
    'bubble': AntoineCoefficients(
      a1: 10.052,
      a2: -1972.1,
      a3: 247.0,
      tMin: -70.0,
      tMax: 71.36,
    ),
    'dew': AntoineCoefficients(
      a1: 10.048,
      a2: -1972.1,
      a3: 247.0,
      tMin: -70.0,
      tMax: 71.36,
    ),
  },
  'R404A': {
    'bubble': AntoineCoefficients(
      a1: 10.022,
      a2: -1880.8,
      a3: 242.4,
      tMin: -70.0,
      tMax: 72.14,
    ),
    'dew': AntoineCoefficients(
      a1: 9.992,
      a2: -1880.8,
      a3: 242.4,
      tMin: -70.0,
      tMax: 72.14,
    ),
  },
  'R114': {
    'bubble': AntoineCoefficients(
      a1: 9.954,
      a2: -2655.3,
      a3: 263.8,
      tMin: -70.0,
      tMax: 145.68,
    ),
    'dew': AntoineCoefficients(
      a1: 9.954,
      a2: -2655.3,
      a3: 263.8,
      tMin: -70.0,
      tMax: 145.68,
    ),
  },
  'R123': {
    'bubble': AntoineCoefficients(
      a1: 9.605,
      a2: -2527.3,
      a3: 235.4,
      tMin: -70.0,
      tMax: 183.68,
    ),
    'dew': AntoineCoefficients(
      a1: 9.605,
      a2: -2527.3,
      a3: 235.4,
      tMin: -70.0,
      tMax: 183.68,
    ),
  },
  'R124': {
    'bubble': AntoineCoefficients(
      a1: 9.644,
      a2: -2138.8,
      a3: 238.2,
      tMin: -70.0,
      tMax: 122.28,
    ),
    'dew': AntoineCoefficients(
      a1: 9.644,
      a2: -2138.8,
      a3: 238.2,
      tMin: -70.0,
      tMax: 122.28,
    ),
  },
  'R1150': {
    'bubble': AntoineCoefficients(
      a1: 9.352,
      a2: -1477.3,
      a3: 261.7,
      tMin: -70.0,
      tMax: 9.2,
    ),
    'dew': AntoineCoefficients(
      a1: 9.352,
      a2: -1477.3,
      a3: 261.7,
      tMin: -70.0,
      tMax: 9.2,
    ),
  },
  'R1233zd': {
    'bubble': AntoineCoefficients(
      a1: 9.686,
      a2: -2469.7,
      a3: 236.8,
      tMin: -70.0,
      tMax: 166.4,
    ),
    'dew': AntoineCoefficients(
      a1: 9.686,
      a2: -2469.7,
      a3: 236.8,
      tMin: -70.0,
      tMax: 166.4,
    ),
  },
  'R1234yf': {
    'bubble': AntoineCoefficients(
      a1: 9.644,
      a2: -2108.3,
      a3: 248.2,
      tMin: -70.0,
      tMax: 94.7,
    ),
    'dew': AntoineCoefficients(
      a1: 9.644,
      a2: -2108.3,
      a3: 248.2,
      tMin: -70.0,
      tMax: 94.7,
    ),
  },
  'R1234ze': {
    'bubble': AntoineCoefficients(
      a1: 10.118,
      a2: -2633.2,
      a3: 250.6,
      tMin: -70.0,
      tMax: 109.37,
    ),
    'dew': AntoineCoefficients(
      a1: 10.118,
      a2: -2633.2,
      a3: 250.6,
      tMin: -70.0,
      tMax: 109.37,
    ),
  },
  'R41': {
    'bubble': AntoineCoefficients(
      a1: 10.271,
      a2: -2059.6,
      a3: 252.1,
      tMin: -70.0,
      tMax: 44.13,
    ),
    'dew': AntoineCoefficients(
      a1: 10.271,
      a2: -2059.6,
      a3: 252.1,
      tMin: -70.0,
      tMax: 44.13,
    ),
  },
};
