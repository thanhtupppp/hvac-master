import 'package:flutter/material.dart';

enum DiffuserType {
  ceilingSquare,
  ceilingRound,
  slot,
  perforated,
  eggCrate,
  supplyRegister,
  returnGrille,
  linearBar,
  jetNozzle,
}

class DiffuserDefinition {
  final DiffuserType type;
  final String nameVi;
  final String nameEn;
  final String description;
  final double maxCfmPerSqFt;
  final double minThrowVelocityFpm;
  final double maxNeckVelocityFpm;
  final double maxNcRating;
  final List<DiffuserSize> availableSizes;
  final IconData icon;

  const DiffuserDefinition({
    required this.type,
    required this.nameVi,
    required this.nameEn,
    required this.description,
    required this.maxCfmPerSqFt,
    required this.minThrowVelocityFpm,
    required this.maxNeckVelocityFpm,
    required this.maxNcRating,
    required this.availableSizes,
    this.icon = Icons.grid_view,
  });

  String get displayName => nameVi;
}

class DiffuserSize {
  final double width;
  final double length;
  final double? neckAreaSqFt;

  const DiffuserSize({
    required this.width,
    required this.length,
    this.neckAreaSqFt,
  });

  /// Returns face area in sq ft.
  /// `neckAreaSqFt` is preferred (true neck opening in ft²).
  /// Otherwise computes face area from width × length (assumed inches).
  double get area => neckAreaSqFt ?? (width * length) / 144.0;
}

class DiffuserCatalog {
  DiffuserCatalog._();

  static const List<DiffuserDefinition> definitions = [
    DiffuserDefinition(
      type: DiffuserType.ceilingSquare,
      nameVi: 'Khuếch tán trần vuông',
      nameEn: 'Square Ceiling Diffuser',
      description:
          'Phổ biến nhất cho hệ thống cấp gió lạnh. Phân phối đều theo 4 hướng.',
      maxCfmPerSqFt: 1.5,
      minThrowVelocityFpm: 50,
      maxNeckVelocityFpm: 800,
      maxNcRating: 35,
      icon: Icons.grid_view,
      availableSizes: [
        DiffuserSize(width: 6, length: 6),
        DiffuserSize(width: 8, length: 8),
        DiffuserSize(width: 10, length: 10),
        DiffuserSize(width: 12, length: 12),
        DiffuserSize(width: 14, length: 14),
        DiffuserSize(width: 16, length: 16),
        DiffuserSize(width: 18, length: 18),
        DiffuserSize(width: 20, length: 20),
        DiffuserSize(width: 24, length: 24),
      ],
    ),
    DiffuserDefinition(
      type: DiffuserType.ceilingRound,
      nameVi: 'Khuếch tán trần tròn',
      nameEn: 'Round Ceiling Diffuser',
      description: 'Thẩm mỹ tốt, dễ lắp đặt. Phân phối xoay tròn.',
      maxCfmPerSqFt: 1.3,
      minThrowVelocityFpm: 50,
      maxNeckVelocityFpm: 750,
      maxNcRating: 30,
      icon: Icons.circle_outlined,
      availableSizes: [
        DiffuserSize(width: 6, length: 6),
        DiffuserSize(width: 8, length: 8),
        DiffuserSize(width: 10, length: 10),
        DiffuserSize(width: 12, length: 12),
        DiffuserSize(width: 14, length: 14),
        DiffuserSize(width: 16, length: 16),
        DiffuserSize(width: 18, length: 18),
        DiffuserSize(width: 20, length: 20),
      ],
    ),
    DiffuserDefinition(
      type: DiffuserType.slot,
      nameVi: 'Khuếch tán rãnh (Slot)',
      nameEn: 'Slot Diffuser',
      description:
          'Thiết kế thanh mảnh, phù hợp không gian hiện đại. Điều chỉnh hướng gió linh hoạt.',
      maxCfmPerSqFt: 2.0,
      minThrowVelocityFpm: 40,
      maxNeckVelocityFpm: 600,
      maxNcRating: 25,
      icon: Icons.view_stream,
      availableSizes: [
        DiffuserSize(width: 4, length: 24, neckAreaSqFt: 0.33),
        DiffuserSize(width: 6, length: 24, neckAreaSqFt: 0.50),
        DiffuserSize(width: 6, length: 36, neckAreaSqFt: 0.50),
        DiffuserSize(width: 6, length: 48, neckAreaSqFt: 0.50),
        DiffuserSize(width: 8, length: 24, neckAreaSqFt: 0.67),
        DiffuserSize(width: 8, length: 36, neckAreaSqFt: 0.67),
        DiffuserSize(width: 8, length: 48, neckAreaSqFt: 0.67),
      ],
    ),
    DiffuserDefinition(
      type: DiffuserType.perforated,
      nameVi: 'Khuếch tán đục lỗ',
      nameEn: 'Perforated Diffuser',
      description:
          'Tích hợp panel trần, thẩm mỹ cao. Phù hợp văn phòng, phòng họp.',
      maxCfmPerSqFt: 1.2,
      minThrowVelocityFpm: 50,
      maxNeckVelocityFpm: 600,
      maxNcRating: 30,
      icon: Icons.grid_on,
      availableSizes: [
        DiffuserSize(width: 24, length: 24),
        DiffuserSize(width: 24, length: 48),
        DiffuserSize(width: 48, length: 48),
      ],
    ),
    DiffuserDefinition(
      type: DiffuserType.eggCrate,
      nameVi: 'Lưới trứng (Egg Crate)',
      nameEn: 'Egg Crate Grille',
      description: 'Dùng cho hồi gió. Free area cao, ít cản trở.',
      maxCfmPerSqFt: 2.5,
      minThrowVelocityFpm: 50,
      maxNeckVelocityFpm: 500,
      maxNcRating: 25,
      icon: Icons.filter_alt,
      availableSizes: [
        DiffuserSize(width: 10, length: 10),
        DiffuserSize(width: 12, length: 12),
        DiffuserSize(width: 14, length: 14),
        DiffuserSize(width: 16, length: 16),
        DiffuserSize(width: 18, length: 18),
        DiffuserSize(width: 20, length: 20),
        DiffuserSize(width: 24, length: 24),
      ],
    ),
    DiffuserDefinition(
      type: DiffuserType.supplyRegister,
      nameVi: 'Miệng gió cấp (Supply Register)',
      nameEn: 'Supply Register',
      description: 'Có cánh điều chỉnh. Lắp tường hoặc sàn.',
      maxCfmPerSqFt: 1.0,
      minThrowVelocityFpm: 60,
      maxNeckVelocityFpm: 700,
      maxNcRating: 35,
      icon: Icons.air,
      availableSizes: [
        DiffuserSize(width: 6, length: 10),
        DiffuserSize(width: 8, length: 12),
        DiffuserSize(width: 10, length: 14),
        DiffuserSize(width: 12, length: 18),
        DiffuserSize(width: 14, length: 20),
        DiffuserSize(width: 16, length: 24),
      ],
    ),
    DiffuserDefinition(
      type: DiffuserType.returnGrille,
      nameVi: 'Miệng gió hồi (Return Grille)',
      nameEn: 'Return Air Grille',
      description: 'Dùng cho hệ thống hồi gió. Thiết kế đơn giản.',
      maxCfmPerSqFt: 2.0,
      minThrowVelocityFpm: 50,
      maxNeckVelocityFpm: 600,
      maxNcRating: 30,
      icon: Icons.wind_power,
      availableSizes: [
        DiffuserSize(width: 10, length: 6),
        DiffuserSize(width: 12, length: 8),
        DiffuserSize(width: 14, length: 10),
        DiffuserSize(width: 16, length: 12),
        DiffuserSize(width: 20, length: 14),
        DiffuserSize(width: 24, length: 16),
        DiffuserSize(width: 30, length: 18),
        DiffuserSize(width: 36, length: 24),
      ],
    ),
    DiffuserDefinition(
      type: DiffuserType.linearBar,
      nameVi: 'Thanh khe (Linear Bar)',
      nameEn: 'Linear Bar Grille',
      description: 'Thanh dài, nhiều cánh. Thẩm mỹ cho không gian hiện đại.',
      maxCfmPerSqFt: 1.8,
      minThrowVelocityFpm: 40,
      maxNeckVelocityFpm: 500,
      maxNcRating: 25,
      icon: Icons.view_agenda,
      availableSizes: [
        DiffuserSize(width: 4, length: 24),
        DiffuserSize(width: 4, length: 36),
        DiffuserSize(width: 4, length: 48),
        DiffuserSize(width: 6, length: 24),
        DiffuserSize(width: 6, length: 36),
        DiffuserSize(width: 6, length: 48),
        DiffuserSize(width: 6, length: 60),
      ],
    ),
    DiffuserDefinition(
      type: DiffuserType.jetNozzle,
      nameVi: 'Miệng phun (Jet Nozzle)',
      nameEn: 'Jet Nozzle Diffuser',
      description: 'Tầm xa, tốc độ cao. Nhà kho, nhà xưởng, atrium.',
      maxCfmPerSqFt: 3.0,
      minThrowVelocityFpm: 30,
      maxNeckVelocityFpm: 1200,
      maxNcRating: 45,
      icon: Icons.rocket_launch,
      availableSizes: [
        DiffuserSize(width: 8, length: 8),
        DiffuserSize(width: 10, length: 10),
        DiffuserSize(width: 12, length: 12),
        DiffuserSize(width: 14, length: 14),
      ],
    ),
  ];

  static DiffuserDefinition get(DiffuserType type) {
    return definitions.firstWhere(
      (d) => d.type == type,
      orElse: () => definitions.first,
    );
  }

  static List<DiffuserDefinition> get supplyDiffusers => definitions
      .where(
        (d) =>
            d.type == DiffuserType.ceilingSquare ||
            d.type == DiffuserType.ceilingRound ||
            d.type == DiffuserType.slot ||
            d.type == DiffuserType.perforated ||
            d.type == DiffuserType.supplyRegister ||
            d.type == DiffuserType.linearBar ||
            d.type == DiffuserType.jetNozzle,
      )
      .toList();

  static List<DiffuserDefinition> get returnDiffusers => definitions
      .where(
        (d) =>
            d.type == DiffuserType.eggCrate ||
            d.type == DiffuserType.returnGrille ||
            d.type == DiffuserType.linearBar,
      )
      .toList();
}
