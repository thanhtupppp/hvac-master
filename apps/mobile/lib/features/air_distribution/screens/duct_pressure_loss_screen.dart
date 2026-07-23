import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/hvac/models/enums.dart';
import '../constants/air_distribution_constants.dart';
import '../providers/pressure_loss_provider.dart';
import '../formulas/duct_pressure_loss_engine.dart';
import '../data/fitting_coefficients.dart';

class DuctPressureLossScreen extends ConsumerStatefulWidget {
  const DuctPressureLossScreen({super.key});

  @override
  ConsumerState<DuctPressureLossScreen> createState() =>
      _DuctPressureLossScreenState();
}

class _DuctPressureLossScreenState
    extends ConsumerState<DuctPressureLossScreen> {
  final _flowController = TextEditingController();
  final _diameterController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _lengthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllersFromState(ref.read(pressureLossProvider));
    });
  }

  @override
  void dispose() {
    _flowController.dispose();
    _diameterController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  void _syncControllersFromState(PressureLossState state) {
    final input = state.input;
    final isMetric = input.unit == UnitSystem.metric;

    _flowController.text = input.flowRate.toStringAsFixed(isMetric ? 0 : 0);

    if (input.shape == DuctShapeForLoss.round) {
      _diameterController.text = (input.ductDiameter ?? 0).toStringAsFixed(
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

    _lengthController.text = input.length.toStringAsFixed(isMetric ? 1 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pressureLossProvider);
    final notifier = ref.read(pressureLossProvider.notifier);

    ref.listen<PressureLossState>(pressureLossProvider, (prev, next) {
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
          'Tổn Thất Áp Suất Ống Gió',
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
          _buildInputSection(state, notifier),
          const SizedBox(height: 16),
          _buildFittingsSection(state, notifier),
          const SizedBox(height: 16),
          if (state.status == PressureLossStatus.success &&
              state.result != null)
            _buildResultsSection(state),
          if (state.status == PressureLossStatus.error)
            _buildErrorSection(state),
        ],
      ),
    );
  }

  Widget _buildSegmentControls(
    PressureLossState state,
    PressureLossNotifier notifier,
  ) {
    final isMetric = state.input.unit == UnitSystem.metric;
    final isRound = state.input.shape == DuctShapeForLoss.round;

    return Column(
      children: [
        // Unit system
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
        // Duct shape
        Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                label: 'Ống Tròn',
                isSelected: isRound,
                onTap: () => notifier.onShapeChanged(DuctShapeForLoss.round),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildToggleButton(
                label: 'Ống Chữ Nhật',
                isSelected: !isRound,
                onTap: () =>
                    notifier.onShapeChanged(DuctShapeForLoss.rectangular),
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

  Widget _buildInputSection(
    PressureLossState state,
    PressureLossNotifier notifier,
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
          _sectionTitle('THÔNG SỐ ĐƯỜNG ỐNG'),
          const SizedBox(height: 16),

          // Flow rate
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

          // Duct size
          if (input.shape == DuctShapeForLoss.round) ...[
            _buildInputField(
              label: 'Đường kính ống',
              suffix: isMetric ? 'mm' : 'inch',
              controller: _diameterController,
              onChanged: (v) {
                final d = double.tryParse(v);
                if (d != null && d > 0) {
                  notifier.onDuctDiameterChanged(d);
                }
              },
            ),
          ] else ...[
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
          ],
          const Divider(color: AppColors.divider),

          // Length
          _buildInputField(
            label: 'Chiều dài ống',
            suffix: isMetric ? 'm' : 'ft',
            controller: _lengthController,
            onChanged: (v) {
              final d = double.tryParse(v);
              if (d != null && d > 0) notifier.onLengthChanged(d);
            },
          ),
          const Divider(color: AppColors.divider),

          // Material
          _buildMaterialDropdown(input, notifier),
        ],
      ),
    );
  }

  Widget _buildMaterialDropdown(
    DuctPressureLossInput input,
    PressureLossNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vật liệu ống',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<DuctMaterial>(
          initialValue: input.material,
          dropdownColor: AppColors.bgSecondary,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          items: DuctMaterial.values.map((m) {
            return DropdownMenuItem(
              value: m,
              child: Text(
                AirDistributionConstants.getDuctMaterialName(m),
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) notifier.onMaterialChanged(val);
          },
        ),
      ],
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

  Widget _buildFittingsSection(
    PressureLossState state,
    PressureLossNotifier notifier,
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
              _sectionTitle('PHỤ KIỆN (FITTINGS)'),
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
          if (state.input.fittings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Chưa thêm phụ kiện nào. Nhấn + để thêm.',
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
                            'K = ${def.defaultK.toStringAsFixed(2)} × ${fitting.quantity}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quantity stepper
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.remove, color: Colors.white, size: 16),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(quantity + 1),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.accentPrimary,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.add, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  void _showAddFittingDialog(PressureLossNotifier notifier) {
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

  Widget _buildResultsSection(PressureLossState state) {
    final result = state.result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('KẾT QUẢ TÍNH TOÁN'),
        const SizedBox(height: 12),

        // Main result card
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
                'TỔN THẤT ÁP SUẤT TỔNG CỘNG',
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
                '(${result.totalLossPa.toStringAsFixed(1)} Pa)',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Velocity card
        _buildResultCard(
          title: 'VẬN TỐC',
          value: '${result.velocityFpm.toStringAsFixed(0)} FPM',
          subtitle: '${result.velocityMs.toStringAsFixed(2)} m/s',
          icon: Icons.speed,
          color: result.isHighVelocity || result.isLowVelocity
              ? Colors.orange
              : Colors.green,
          warning: result.velocityWarning,
        ),
        const SizedBox(height: 12),

        // Friction loss card
        _buildResultCard(
          title: 'TỔN THẤT MA SÁT',
          value:
              '${result.frictionLossInWgPer100ft.toStringAsFixed(4)} in.wg/100ft',
          subtitle: '${result.frictionLossPaPerM.toStringAsFixed(3)} Pa/m',
          icon: Icons.compress,
          color: result.isHighFriction ? Colors.red : AppColors.accentPrimary,
          warning: result.frictionWarning,
        ),
        const SizedBox(height: 12),

        // Fitting loss card
        _buildResultCard(
          title: 'TỔN THẤT PHỤ KIỆN',
          value: '${result.fittingLossInWg.toStringAsFixed(4)} in.wg',
          subtitle: '${result.fittingLossPa.toStringAsFixed(2)} Pa',
          icon: Icons.account_tree,
          color: AppColors.accentBright,
        ),
        const SizedBox(height: 12),

        // Details card
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
              const Text(
                'CHI TIẾT',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Reynolds Number',
                _formatNumber(result.reynoldsNumber),
              ),
              _buildDetailRow(
                'Friction Factor (f)',
                result.darcyFrictionFactor.toStringAsFixed(5),
              ),
              _buildDetailRow(
                'Roughness Ratio (ε/D)',
                result.roughnessRatio.toStringAsExponential(2),
              ),
              if (result.aspectRatio != 1.0)
                _buildDetailRow(
                  'Aspect Ratio (W/H)',
                  result.aspectRatio.toStringAsFixed(2),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? warning,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.firaCode(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (warning != null) ...[
            const SizedBox(height: 8),
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
                      warning,
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.firaCode(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(PressureLossState state) {
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

  String _formatNumber(double n) {
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(2)}M';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
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

  @override
  Widget build(BuildContext context) {
    final all = FittingCoefficients.all;
    final filtered = all
        .where(
          (f) => f.displayName.toLowerCase().contains(_search.toLowerCase()),
        )
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
            'Thêm Phụ Kiện',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
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
                    style: const TextStyle(color: Colors.white, fontSize: 14),
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
