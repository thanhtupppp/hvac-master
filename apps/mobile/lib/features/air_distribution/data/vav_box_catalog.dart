import 'package:flutter/material.dart';

enum VavBoxType {
  singleDuctCoolingOnly,
  singleDuctWithReheat,
  dualDuct,
  fanPowered,
  induction,
  parallelFanPowered,
  seriesFanPowered,
}

class VavBoxSize {
  final double inletDiameterIn;
  final double inletAreaSqFt;
  final double maxCfm;
  final double minCfm;
  final double maxAirflowRange;

  const VavBoxSize({
    required this.inletDiameterIn,
    required this.inletAreaSqFt,
    required this.maxCfm,
    required this.minCfm,
    required this.maxAirflowRange,
  });
}

class VavBoxDefinition {
  final VavBoxType type;
  final String nameVi;
  final String nameEn;
  final String description;
  final String application;
  final double typicalTurndownRatio;
  final double reheatingCapacityFactor;
  final List<VavBoxSize> availableSizes;
  final IconData icon;
  final bool hasReheat;

  const VavBoxDefinition({
    required this.type,
    required this.nameVi,
    required this.nameEn,
    required this.description,
    required this.application,
    required this.typicalTurndownRatio,
    required this.reheatingCapacityFactor,
    required this.availableSizes,
    this.icon = Icons.device_thermostat,
    this.hasReheat = false,
  });

  String get displayName => nameVi;
}

class VavBoxCatalog {
  VavBoxCatalog._();

  static const List<VavBoxDefinition> definitions = [
    VavBoxDefinition(
      type: VavBoxType.singleDuctCoolingOnly,
      nameVi: 'Single Duct — Cooling Only',
      nameEn: 'Single Duct Cooling Only',
      description: 'Hộp VAV đơn ống, chỉ làm lạnh. Đơn giản, chi phí thấp.',
      application: 'Văn phòng, khu vực chỉ có tải lạnh.',
      typicalTurndownRatio: 0.30,
      reheatingCapacityFactor: 0,
      icon: Icons.thermostat,
      hasReheat: false,
      availableSizes: _standardSizes,
    ),
    VavBoxDefinition(
      type: VavBoxType.singleDuctWithReheat,
      nameVi: 'Single Duct — With Reheat',
      nameEn: 'Single Duct With Reheat',
      description:
          'Hộp VAV đơn ống có gia nhiệt lại (reheat). Phù hợp khu vực cần kiểm soát nhiệt độ chính xác.',
      application: 'Văn phòng ngoài rìa, phòng có tải sưởi và lạnh.',
      typicalTurndownRatio: 0.20,
      reheatingCapacityFactor: 1.0,
      icon: Icons.whatshot,
      hasReheat: true,
      availableSizes: _standardSizes,
    ),
    VavBoxDefinition(
      type: VavBoxType.dualDuct,
      nameVi: 'Dual Duct',
      nameEn: 'Dual Duct VAV',
      description:
          'Hộp VAV hai ống (cold deck + hot deck). Trộn gió nóng/lạnh tại miệng gió.',
      application: 'Bệnh viện, phòng sạch, khu vực tải biến đổi lớn.',
      typicalTurndownRatio: 0.10,
      reheatingCapacityFactor: 1.5,
      icon: Icons.swap_vertical_circle,
      hasReheat: true,
      availableSizes: _standardSizes,
    ),
    VavBoxDefinition(
      type: VavBoxType.fanPowered,
      nameVi: 'Fan Powered Terminal',
      nameEn: 'Fan Powered VAV',
      description:
          'Hộp VAV có quạt phụ cấp áp. Duy trì lưu lượng tối thiểu kể cả khi VAV đóng.',
      application: 'Khu vực cần lưu thông không khí liên tục.',
      typicalTurndownRatio: 0.25,
      reheatingCapacityFactor: 1.0,
      icon: Icons.air,
      hasReheat: false,
      availableSizes: _standardSizes,
    ),
    VavBoxDefinition(
      type: VavBoxType.parallelFanPowered,
      nameVi: 'Parallel Fan Powered',
      nameEn: 'Parallel Fan Powered VAV',
      description:
          'Quạt phụ chạy song song với VAV. Lưu lượng tối thiểu qua quạt, max qua VAV.',
      application: 'Khu vực tải đa dạng, cần cải thiện chất lượng không khí.',
      typicalTurndownRatio: 0.20,
      reheatingCapacityFactor: 1.2,
      icon: Icons.compare_arrows,
      hasReheat: true,
      availableSizes: _standardSizes,
    ),
    VavBoxDefinition(
      type: VavBoxType.seriesFanPowered,
      nameVi: 'Series Fan Powered',
      nameEn: 'Series Fan Powered VAV',
      description: 'Quạt phụ nối tiếp với VAV. Toàn bộ không khí qua quạt.',
      application: 'Khu vực yêu cầu cao về chất lượng không khí.',
      typicalTurndownRatio: 0.15,
      reheatingCapacityFactor: 1.0,
      icon: Icons.linear_scale,
      hasReheat: false,
      availableSizes: _standardSizes,
    ),
    VavBoxDefinition(
      type: VavBoxType.induction,
      nameVi: 'Induction VAV',
      nameEn: 'Induction Unit',
      description:
          'Hộp VAV kiểu cảm ứng. Sử dụng áp suất cao để hút gió phòng trộn.',
      application: 'Hệ thống áp suất cao, hiệu quả cao.',
      typicalTurndownRatio: 0.10,
      reheatingCapacityFactor: 1.8,
      icon: Icons.waves,
      hasReheat: true,
      availableSizes: _inductionSizes,
    ),
  ];

  static const List<VavBoxSize> _standardSizes = [
    VavBoxSize(
      inletDiameterIn: 6,
      inletAreaSqFt: 0.20,
      maxCfm: 250,
      minCfm: 50,
      maxAirflowRange: 5,
    ),
    VavBoxSize(
      inletDiameterIn: 8,
      inletAreaSqFt: 0.35,
      maxCfm: 500,
      minCfm: 100,
      maxAirflowRange: 5,
    ),
    VavBoxSize(
      inletDiameterIn: 10,
      inletAreaSqFt: 0.55,
      maxCfm: 850,
      minCfm: 170,
      maxAirflowRange: 5,
    ),
    VavBoxSize(
      inletDiameterIn: 12,
      inletAreaSqFt: 0.79,
      maxCfm: 1300,
      minCfm: 260,
      maxAirflowRange: 5,
    ),
    VavBoxSize(
      inletDiameterIn: 14,
      inletAreaSqFt: 1.07,
      maxCfm: 1800,
      minCfm: 360,
      maxAirflowRange: 5,
    ),
    VavBoxSize(
      inletDiameterIn: 16,
      inletAreaSqFt: 1.40,
      maxCfm: 2400,
      minCfm: 480,
      maxAirflowRange: 5,
    ),
  ];

  static const List<VavBoxSize> _inductionSizes = [
    VavBoxSize(
      inletDiameterIn: 8,
      inletAreaSqFt: 0.35,
      maxCfm: 600,
      minCfm: 60,
      maxAirflowRange: 10,
    ),
    VavBoxSize(
      inletDiameterIn: 10,
      inletAreaSqFt: 0.55,
      maxCfm: 1000,
      minCfm: 100,
      maxAirflowRange: 10,
    ),
    VavBoxSize(
      inletDiameterIn: 12,
      inletAreaSqFt: 0.79,
      maxCfm: 1500,
      minCfm: 150,
      maxAirflowRange: 10,
    ),
    VavBoxSize(
      inletDiameterIn: 14,
      inletAreaSqFt: 1.07,
      maxCfm: 2200,
      minCfm: 220,
      maxAirflowRange: 10,
    ),
  ];

  static VavBoxDefinition get(VavBoxType type) => definitions.firstWhere(
    (d) => d.type == type,
    orElse: () => definitions[0],
  );
}
