import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/hvac/models/enums.dart';
import '../providers/fitting_loss_provider.dart';
import '../formulas/fitting_loss_engine.dart';
import '../data/fitting_coefficients.dart';

class FittingLossScreen extends ConsumerStatefulWidget {
  const FittingLossScreen({super.key});

  @override
  ConsumerState<FittingLossScreen> createState() => _FittingLossScreenState();
}

class _FittingLossScreenState extends ConsumerState<FittingLossScreen> {
  final _flowController = TextEditingController();
  final _diameterController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _velocityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllersFromState(ref.read(fittingLossProvider));
    });
  }

  @override
  void dispose() {
    _flowController.dispose();
    _diameterController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _velocityController.dispose();
    super.dispose();
  }

  void _syncControllersFromState(FittingLossState state) {
    final input = state.input;
    final isMetric = input.unit == UnitSystem.metric;

    _flowController.text = input.flowRate.toStringAsFixed(0);
    if (input.shape == FittingLossShape.round) {
      _diameterController.text = input.ductDiameter.toStringAsFixed(
        isMetric ? 0 : 1,
      );
    } else {
      _widthController.text = (input.ductWidth ?? 0).toStringAsFixed(
        isMetric ? 0 : 1,
      );
      _heightController.text = (input.ductHeight ?? 0).toStringAsFixed(
        isMetric ? 0 : 1,
      );
    }
    _velocityController.text = input.velocityOverride.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fittingLossProvider);
    final notifier = ref.read(fittingLossProvider.notifier);

    ref.listen<FittingLossState>(fittingLossProvider, (prev, next) {
      if (prev?.input.unit != next.input.unit) {
        _syncControllersFromState(next);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tổn Thất Phụ Kiện Ống Gió',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSegmentControls(state, notifier),
          const SizedBox(height: 16),
          _buildDuctInfoSection(state, notifier),
          const SizedBox(height: 16),
          _buildFittingsSection(state, notifier),
          const SizedBox(height: 16),
          if (state.status == FittingLossStatus.success && state.result != null)
            _buildResultsSection(state)
          else if (state.status == FittingLossStatus.error)
            _buildErrorSection(state),
          if (state.result != null && state.result!.contributions.isNotEmpty)
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSegmentControls(
    FittingLossState state,
    FittingLossNotifier notifier,
  ) {
    final isMetric = state.input.unit == UnitSystem.metric;
    final isRound = state.input.shape == FittingLossShape.round;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                label: 'Metric',
                isSelected: isMetric,
                onTap: () => notifier.onUnitSystemChanged(UnitSystem.metric),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildToggleButton(
                label: 'Imperial',
                isSelected: !isMetric,
                onTap: () => notifier.onUnitSystemChanged(UnitSystem.imperial),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                label: 'Ống Tròn',
                isSelected: isRound,
                onTap: () => notifier.onShapeChanged(FittingLossShape.round),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildToggleButton(
                label: 'Ống Chữ Nhật',
                isSelected: !isRound,
                onTap: () =>
                    notifier.onShapeChanged(FittingLossShape.rectangular),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPrimary : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : AppColors.divider,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDuctInfoSection(
    FittingLossState state,
    FittingLossNotifier notifier,
  ) {
    final input = state.input;
    final isMetric = input.unit == UnitSystem.metric;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('THÔNG TIN ĐƯỜNG ỐNG'),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Lưu lượng gió',
            suffix: isMetric ? 'm³/h' : 'CFM',
            controller: _flowController,
            onChanged: (v) {
              final d = double.tryParse(v);
              if (d != null) notifier.onFlowRateChanged(d);
            },
          ),
          const Divider(color: AppColors.divider),
          if (input.shape == FittingLossShape.round)
            _buildInputField(
              label: 'Đường kính ống',
              suffix: isMetric ? 'mm' : 'inch',
              controller: _diameterController,
              onChanged: (v) {
                final d = double.tryParse(v);
                if (d != null && d > 0) notifier.onDuctDiameterChanged(d);
              },
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'Chiều rộng',
                    suffix: isMetric ? 'mm' : 'inch',
                    controller: _widthController,
                    onChanged: (v) {
                      final d = double.tryParse(v);
                      if (d != null && d > 0) {
                        notifier.onDuctSizeChanged(d, input.ductHeight);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    label: 'Chiều cao',
                    suffix: isMetric ? 'mm' : 'inch',
                    controller: _heightController,
                    onChanged: (v) {
                      final d = double.tryParse(v);
                      if (d != null && d > 0) {
                        notifier.onDuctSizeChanged(input.ductWidth, d);
                      }
                    },
                  ),
                ),
              ],
            ),
          const Divider(color: AppColors.divider),
          _buildVelocityOverrideRow(state, notifier, isMetric),
        ],
      ),
    );
  }

  Widget _buildVelocityOverrideRow(
    FittingLossState state,
    FittingLossNotifier notifier,
    bool isMetric,
  ) {
    return Row(
      children: [
        Checkbox(
          value: state.input.useVelocityOverride,
          onChanged: (v) => notifier.onVelocityOverrideChanged(
            state.input.velocityOverride,
            enabled: v ?? false,
          ),
          activeColor: AppColors.accentPrimary,
        ),
        Expanded(
          child: const Text(
            'Ghi đè vận tốc (bỏ qua tính từ lưu lượng)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
        SizedBox(
          width: 80,
          child: TextField(
            controller: _velocityController,
            enabled: state.input.useVelocityOverride,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: state.input.useVelocityOverride
                  ? Colors.white
                  : AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              suffixText: isMetric ? 'm/s' : 'fpm',
              suffixStyle: const TextStyle(
                color: AppColors.accentBright,
                fontSize: 12,
              ),
            ),
            onChanged: (v) {
              final d = double.tryParse(v);
              if (d != null) {
                notifier.onVelocityOverrideChanged(
                  d,
                  enabled: state.input.useVelocityOverride,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFittingsSection(
    FittingLossState state,
    FittingLossNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('DANH SÁCH PHỤ KIỆN'),
              Row(
                children: [
                  if (state.input.fittings.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.clear_all,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      onPressed: () => _confirmClear(notifier),
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppColors.accentBright,
                      size: 24,
                    ),
                    onPressed: () => _showAddFittingDialog(notifier),
                  ),
                ],
              ),
            ],
          ),
          if (state.input.fittings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Chưa có phụ kiện nào. Nhấn + để thêm.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            )
          else
            ...state.input.fittings.asMap().entries.map((entry) {
              final idx = entry.key;
              final fitting = entry.value;
              final def = FittingCoefficients.get(fitting.type);
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(def.icon, color: AppColors.accentBright, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            def.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'K = ${def.defaultK.toStringAsFixed(2)} × ${fitting.quantity} = ${(def.defaultK * fitting.quantity).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildQuantityStepper(
                      quantity: fitting.quantity,
                      onChanged: (q) => notifier.updateFittingQuantity(idx, q),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => notifier.removeFitting(idx),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _confirmClear(FittingLossNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Xóa tất cả?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bạn có chắc muốn xóa toàn bộ danh sách phụ kiện?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              notifier.clearFittings();
              Navigator.pop(ctx);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityStepper({
    required int quantity,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (quantity > 1) onChanged(quantity - 1);
          },
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.remove, color: Colors.white, size: 14),
          ),
        ),
        SizedBox(
          width: 26,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(quantity + 1),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.accentPrimary,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.add, color: Colors.white, size: 14),
          ),
        ),
      ],
    );
  }

  void _showAddFittingDialog(FittingLossNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _FittingPickerSheet(
        onSelect: (type) {
          notifier.addFitting(type);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Widget _buildResultsSection(FittingLossState state) {
    final result = state.result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Velocity / Pressure reference card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle('ÁP SUẤT ĐỘNG & VẬN TỐC'),
                  Icon(Icons.flash_on, color: AppColors.accentBright, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    'Vận tốc',
                    '${result.velocityMs.toStringAsFixed(2)} m/s',
                    '${result.velocityFpm.toStringAsFixed(0)} fpm',
                  ),
                  Container(width: 1, height: 36, color: AppColors.divider),
                  _buildStat(
                    'Áp suất động',
                    '${result.velocityPressureInWg.toStringAsFixed(4)} in.wg',
                    '${result.velocityPressurePa.toStringAsFixed(2)} Pa',
                  ),
                ],
              ),
              if (result.warning != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.warning!,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Hero total loss
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D1B4E), Color(0xFF3A2260)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.accentPrimary.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: [
              const Text(
                'TỔN THẤT TỪ PHỤ KIỆN',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${result.totalLossInWg.toStringAsFixed(3)} in.wg',
                style: GoogleFonts.firaCode(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${result.totalLossPa.toStringAsFixed(2)} Pa · ${result.totalLossMmH2O.toStringAsFixed(2)} mmH₂O',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ΣK = ${result.totalK.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.accentBright,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (result.contributions.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(
                Icons.analytics,
                color: AppColors.accentBright,
                size: 18,
              ),
              const SizedBox(width: 8),
              _sectionTitle('PHÂN TÍCH ĐÓNG GÓP'),
            ],
          ),
          const SizedBox(height: 12),
          // Bar chart visualization
          _buildContributionChart(result),
          const SizedBox(height: 16),
          _buildContributionTable(result),
        ],
      ],
    );
  }

  Widget _buildContributionChart(FittingLossResult result) {
    final maxLoss = result.contributions.first.lossPa;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in result.contributions) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      c.nameVi,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.bgPrimary,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: maxLoss > 0 ? c.lossPa / maxLoss : 0,
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accentBright,
                                  AppColors.accentPrimary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${c.sharePercent.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.accentBright,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContributionTable(FittingLossResult result) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                _tableHeader('Phụ kiện', flex: 3),
                _tableHeader('SL', flex: 1),
                _tableHeader('K', flex: 1),
                _tableHeader('ΔP (Pa)', flex: 2),
              ],
            ),
          ),
          ...result.contributions.map((c) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      c.nameVi,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${c.quantity}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      c.totalK.toStringAsFixed(2),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      c.lossPa.toStringAsFixed(2),
                      style: GoogleFonts.firaCode(
                        color: AppColors.accentBright,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, String sub) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.firaCode(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          sub,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildErrorSection(FittingLossState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.errorMessage ?? 'Đã xảy ra lỗi',
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String suffix,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                suffixText: suffix,
                suffixStyle: const TextStyle(
                  color: AppColors.accentBright,
                  fontSize: 12,
                ),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _FittingPickerSheet extends StatefulWidget {
  final Function(FittingType) onSelect;

  const _FittingPickerSheet({required this.onSelect});

  @override
  State<_FittingPickerSheet> createState() => _FittingPickerSheetState();
}

class _FittingPickerSheetState extends State<_FittingPickerSheet> {
  String _search = '';
  int _tabIndex = 0;

  static const _tabs = ['Khuỷu', 'Tê', 'Co thu', 'Phụ kiện'];

  List<FittingDefinition> _filteredList() {
    final List<FittingDefinition> base;
    switch (_tabIndex) {
      case 0:
        base = FittingCoefficients.elbows;
        break;
      case 1:
        base = FittingCoefficients.tees;
        break;
      case 2:
        base = FittingCoefficients.transitions;
        break;
      case 3:
        base = FittingCoefficients.accessories;
        break;
      default:
        base = FittingCoefficients.all;
    }
    if (_search.isEmpty) return base;
    return base
        .where(
          (f) => f.displayName.toLowerCase().contains(_search.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chọn Phụ Kiện',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final selected = i == _tabIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accentPrimary
                            : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _tabs[i],
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Không tìm thấy',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final fitting = filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.accentPrimary.withValues(
                            alpha: 0.2,
                          ),
                          child: Icon(
                            fitting.icon,
                            color: AppColors.accentBright,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          fitting.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'K = ${fitting.defaultK.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.add,
                          color: AppColors.accentBright,
                        ),
                        onTap: () => widget.onSelect(fitting.type),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
