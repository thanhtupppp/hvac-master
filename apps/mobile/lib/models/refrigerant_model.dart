import 'package:flutter/material.dart';

class RefrigerantModel {
  final String name;
  final String safetyGroup;
  final double gwp;
  final double odp;
  final double criticalTemp; // in °C
  final double boilingPoint; // in °C at 1 atm
  final String typeClass;    // CFC, HC, HCFC, HFC
  final Color color;
  bool isFavorite;

  RefrigerantModel({
    required this.name,
    required this.safetyGroup,
    required this.gwp,
    required this.odp,
    required this.criticalTemp,
    required this.boilingPoint,
    required this.typeClass,
    required this.color,
    this.isFavorite = false,
  });

  RefrigerantModel copyWith({
    String? name,
    String? safetyGroup,
    double? gwp,
    double? odp,
    double? criticalTemp,
    double? boilingPoint,
    String? typeClass,
    Color? color,
    bool? isFavorite,
  }) {
    return RefrigerantModel(
      name: name ?? this.name,
      safetyGroup: safetyGroup ?? this.safetyGroup,
      gwp: gwp ?? this.gwp,
      odp: odp ?? this.odp,
      criticalTemp: criticalTemp ?? this.criticalTemp,
      boilingPoint: boilingPoint ?? this.boilingPoint,
      typeClass: typeClass ?? this.typeClass,
      color: color ?? this.color,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

// Global database of refrigerants matching the screenshots
final List<RefrigerantModel> defaultRefrigerants = [
  RefrigerantModel(
    name: 'R32',
    safetyGroup: 'A2L',
    gwp: 675,
    odp: 0,
    criticalTemp: 78.11,
    boilingPoint: -51.65,
    typeClass: 'HFC',
    color: const Color(0xFF00E5FF),
  ),
  RefrigerantModel(
    name: 'R41',
    safetyGroup: 'A2L',
    gwp: 92,
    odp: 0,
    criticalTemp: 44.13,
    boilingPoint: -37.1,
    typeClass: 'HFC',
    color: const Color(0xFFE91E63),
  ),
  RefrigerantModel(
    name: 'R114',
    safetyGroup: 'A1',
    gwp: 10000,
    odp: 1.0,
    criticalTemp: 145.68,
    boilingPoint: 3.6,
    typeClass: 'CFC',
    color: const Color(0xFF9C27B0),
  ),
  RefrigerantModel(
    name: 'R123',
    safetyGroup: 'B1',
    gwp: 77,
    odp: 0.02,
    criticalTemp: 183.68,
    boilingPoint: 27.6,
    typeClass: 'HCFC',
    color: const Color(0xFFFFEB3B),
  ),
  RefrigerantModel(
    name: 'R1150 (Ethylene)',
    safetyGroup: 'A3',
    gwp: 4,
    odp: 0,
    criticalTemp: 9.2,
    boilingPoint: -103.7,
    typeClass: 'HC',
    color: const Color(0xFF4CAF50),
  ),
  RefrigerantModel(
    name: 'R1233zd(E)',
    safetyGroup: 'A1',
    gwp: 4.5,
    odp: 0.00034,
    criticalTemp: 166.4,
    boilingPoint: 18.2,
    typeClass: 'HCFC',
    color: const Color(0xFF03A9F4),
  ),
  RefrigerantModel(
    name: 'R1234yf',
    safetyGroup: 'A2L',
    gwp: 4,
    odp: 0,
    criticalTemp: 94.7,
    boilingPoint: -29.4,
    typeClass: 'HFC',
    color: const Color(0xFFFF5722),
  ),
  RefrigerantModel(
    name: 'R1234ze(E)',
    safetyGroup: 'A2L',
    gwp: 7,
    odp: 0,
    criticalTemp: 109.37,
    boilingPoint: -19.0,
    typeClass: 'HFC',
    color: const Color(0xFFFFC107),
  ),
  RefrigerantModel(
    name: 'R124',
    safetyGroup: 'A1',
    gwp: 609,
    odp: 0.022,
    criticalTemp: 122.28,
    boilingPoint: -12.0,
    typeClass: 'HCFC',
    color: const Color(0xFFE040FB),
  ),
  RefrigerantModel(
    name: 'R22',
    safetyGroup: 'A1',
    gwp: 1810,
    odp: 0.055,
    criticalTemp: 96.15,
    boilingPoint: -40.8,
    typeClass: 'HCFC',
    color: const Color(0xFF8BC34A),
  ),
  RefrigerantModel(
    name: 'R134a',
    safetyGroup: 'A1',
    gwp: 1430,
    odp: 0,
    criticalTemp: 101.06,
    boilingPoint: -26.3,
    typeClass: 'HFC',
    color: const Color(0xFF29B6F6),
  ),
  RefrigerantModel(
    name: 'R410A',
    safetyGroup: 'A1',
    gwp: 2088,
    odp: 0,
    criticalTemp: 71.36,
    boilingPoint: -51.4,
    typeClass: 'HFC',
    color: const Color(0xFFF50057),
  ),
  RefrigerantModel(
    name: 'R404A',
    safetyGroup: 'A1',
    gwp: 3922,
    odp: 0,
    criticalTemp: 72.14,
    boilingPoint: -46.5,
    typeClass: 'HFC',
    color: const Color(0xFFFF9800),
  ),
];
