import 'package:flutter/material.dart';

enum FittingType {
  elbow90R05,
  elbow90R10,
  elbow90R15,
  elbow90R20,
  elbow90Mitered,
  elbow45,
  elbow45Mitered,
  teeBranch,
  teeRun,
  reducerConical,
  reducerBellmouth,
  transition,
  takeoff,
  damper,
  filter,
  coil,
  vavBox,
  louver,
  intake,
  exhaust,
}

class FittingDefinition {
  final FittingType type;
  final String nameVi;
  final String nameEn;
  final double defaultK;
  final List<double> sizeFactors;
  final IconData icon;

  const FittingDefinition({
    required this.type,
    required this.nameVi,
    required this.nameEn,
    required this.defaultK,
    this.sizeFactors = const [],
    this.icon = Icons.account_tree,
  });

  String get displayName => nameVi;
}

class FittingCoefficients {
  FittingCoefficients._();

  // SMACNA HVAC Systems Duct Design — Table of loss coefficients (K-values)
  // These are reference values for standard fittings.
  // Actual K may vary based on size, Reynolds number, and geometry.

  // SMACNA HVAC Duct Construction Standards (2005) Table 4-1
  // and ASHRAE Handbook Fundamentals 2021 Chapter 21 Table 22.
  // K-values are total loss coefficients (energy loss per unit velocity pressure).
  static const Map<FittingType, FittingDefinition> definitions = {
    FittingType.elbow90R05: FittingDefinition(
      type: FittingType.elbow90R05,
      nameVi: 'Khuỷu 90° (R/D = 0.5)',
      nameEn: 'Elbow 90° (R/D = 0.5)',
      defaultK: 1.50, // SMACNA: tight radius
      icon: Icons.turn_right,
    ),
    FittingType.elbow90R10: FittingDefinition(
      type: FittingType.elbow90R10,
      nameVi: 'Khuỷu 90° (R/D = 1.0)',
      nameEn: 'Elbow 90° (R/D = 1.0)',
      defaultK: 0.50, // SMACNA: standard radius
      icon: Icons.turn_right,
    ),
    FittingType.elbow90R15: FittingDefinition(
      type: FittingType.elbow90R15,
      nameVi: 'Khuỷu 90° (R/D = 1.5)',
      nameEn: 'Elbow 90° (R/D = 1.5)',
      defaultK: 0.30, // SMACNA: long radius
      icon: Icons.turn_right,
    ),
    FittingType.elbow90R20: FittingDefinition(
      type: FittingType.elbow90R20,
      nameVi: 'Khuỷu 90° (R/D = 2.0)',
      nameEn: 'Elbow 90° (R/D = 2.0)',
      defaultK: 0.20, // SMACNA: very long radius
      icon: Icons.turn_right,
    ),
    FittingType.elbow90Mitered: FittingDefinition(
      type: FittingType.elbow90Mitered,
      nameVi: 'Khuỷu 90° cắt góc (Mitered)',
      nameEn: 'Mitered Elbow 90°',
      defaultK: 1.10, // SMACNA: without turning vanes
      icon: Icons.turn_right,
    ),
    FittingType.elbow45: FittingDefinition(
      type: FittingType.elbow45,
      nameVi: 'Khuỷu 45°',
      nameEn: 'Elbow 45°',
      defaultK: 0.40, // SMACNA: smooth radius 45°
      icon: Icons.turn_right,
    ),
    FittingType.elbow45Mitered: FittingDefinition(
      type: FittingType.elbow45Mitered,
      nameVi: 'Khuỷu 45° cắt góc',
      nameEn: 'Mitered Elbow 45°',
      defaultK: 0.60, // SMACNA: mitered 45°
      icon: Icons.turn_right,
    ),
    FittingType.teeBranch: FittingDefinition(
      type: FittingType.teeBranch,
      nameVi: 'Tee nhánh (Branch)',
      nameEn: 'Tee Branch',
      defaultK: 1.80, // SMACNA: conical tee, varies 1.0-2.5
      icon: Icons.horizontal_rule,
    ),
    FittingType.teeRun: FittingDefinition(
      type: FittingType.teeRun,
      nameVi: 'Tee đoạn thẳng (Run)',
      nameEn: 'Tee Straight Through',
      defaultK: 0.20, // SMACNA: straight-through run
      icon: Icons.horizontal_rule,
    ),
    FittingType.reducerConical: FittingDefinition(
      type: FittingType.reducerConical,
      nameVi: 'Co thu conical',
      nameEn: 'Conical Reducer',
      defaultK: 0.10, // SMACNA: gradual conical reducer
      icon: Icons.compress,
    ),
    FittingType.reducerBellmouth: FittingDefinition(
      type: FittingType.reducerBellmouth,
      nameVi: 'Co thu bellmouth',
      nameEn: 'Bellmouth Reducer',
      defaultK: 0.05, // SMACNA: smooth bellmouth
      icon: Icons.compress,
    ),
    FittingType.transition: FittingDefinition(
      type: FittingType.transition,
      nameVi: 'Chuyển tiết diện (Transition)',
      nameEn: 'Transition',
      defaultK: 0.20, // SMACNA: gradual transition 15° included angle
      icon: Icons.swap_horiz,
    ),
    FittingType.takeoff: FittingDefinition(
      type: FittingType.takeoff,
      nameVi: 'Điểm lấy gió (Takeoff)',
      nameEn: 'Duct Takeoff',
      defaultK: 0.50, // SMACNA: rectangular branch takeoff
      icon: Icons.output,
    ),
    FittingType.damper: FittingDefinition(
      type: FittingType.damper,
      nameVi: 'Van điều chỉnh (Damper)',
      nameEn: 'Volume Damper',
      defaultK: 0.80, // SMACNA: opposed blade damper (open)
      icon: Icons.tune,
    ),
    FittingType.filter: FittingDefinition(
      type: FittingType.filter,
      nameVi: 'Bộ lọc (Filter)',
      nameEn: 'Air Filter',
      defaultK: 1.30, // SMACNA: panel filter (clean)
      icon: Icons.filter_alt,
    ),
    FittingType.coil: FittingDefinition(
      type: FittingType.coil,
      nameVi: 'Bộ trao đổi nhiệt (Coil)',
      nameEn: 'Heating/Cooling Coil',
      defaultK: 0.60, // SMACNA: 4-row heating coil
      icon: Icons.ac_unit,
    ),
    FittingType.vavBox: FittingDefinition(
      type: FittingType.vavBox,
      nameVi: 'Hộp VAV',
      nameEn: 'VAV Box',
      defaultK: 0.50, // SMACNA: VAV terminal unit
      icon: Icons.device_thermostat,
    ),
    FittingType.louver: FittingDefinition(
      type: FittingType.louver,
      nameVi: 'Lưới chắn (Louver)',
      nameEn: 'Louver',
      defaultK: 1.50, // SMACNA: intake louver
      icon: Icons.grid_on,
    ),
    FittingType.intake: FittingDefinition(
      type: FittingType.intake,
      nameVi: 'Đầu hút gió (Intake)',
      nameEn: 'Intake Hood',
      defaultK: 1.00, // SMACNA: intake hood with screen
      icon: Icons.air,
    ),
    FittingType.exhaust: FittingDefinition(
      type: FittingType.exhaust,
      nameVi: 'Đầu xả gió (Exhaust)',
      nameEn: 'Exhaust Hood',
      defaultK: 1.20, // SMACNA: exhaust hood with screen
      icon: Icons.wind_power,
    ),
  };

  static FittingDefinition get(FittingType type) {
    return definitions[type] ?? definitions[FittingType.elbow90R10]!;
  }

  static List<FittingDefinition> get all => definitions.values.toList();

  static List<FittingDefinition> get elbows => definitions.values
      .where(
        (f) =>
            f.type == FittingType.elbow90R05 ||
            f.type == FittingType.elbow90R10 ||
            f.type == FittingType.elbow90R15 ||
            f.type == FittingType.elbow90R20 ||
            f.type == FittingType.elbow90Mitered ||
            f.type == FittingType.elbow45 ||
            f.type == FittingType.elbow45Mitered,
      )
      .toList();

  static List<FittingDefinition> get tees => definitions.values
      .where(
        (f) => f.type == FittingType.teeBranch || f.type == FittingType.teeRun,
      )
      .toList();

  static List<FittingDefinition> get transitions => definitions.values
      .where(
        (f) =>
            f.type == FittingType.reducerConical ||
            f.type == FittingType.reducerBellmouth ||
            f.type == FittingType.transition,
      )
      .toList();

  static List<FittingDefinition> get accessories => definitions.values
      .where(
        (f) =>
            f.type == FittingType.takeoff ||
            f.type == FittingType.damper ||
            f.type == FittingType.filter ||
            f.type == FittingType.coil ||
            f.type == FittingType.vavBox ||
            f.type == FittingType.louver ||
            f.type == FittingType.intake ||
            f.type == FittingType.exhaust,
      )
      .toList();
}
