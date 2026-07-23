import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/hvac/models/enums.dart';
import '../constants/hydronic_constants.dart';
import '../formulas/water_flow_engine.dart';
import '../providers/water_flow_provider.dart';

class WaterFlowScreen extends ConsumerStatefulWidget {
  const WaterFlowScreen({super.key});

  @override
  ConsumerState<WaterFlowScreen> createState() => _WaterFlowScreenState();
}

class _WaterFlowScreenState extends ConsumerState<WaterFlowScreen> {
  final _flowController = TextEditingController();
  final _diameterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllersFromState(ref.read(waterFlowProvider));
    });
  }

  @override
  void dispose() {
    _flowController.dispose();
    _diameterController.dispose();
    super.dispose();
  }

  void _syncControllersFromState(WaterFlowState state) {
    final input = state.input;
    _flowController.text = input.flowRate.toStringAsFixed(1);
    _diameterController.text = input.diameter.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(waterFlowProvider);
    final notifier = ref.read(waterFlowProvider.notifier);

    ref.listen<WaterFlowState>(waterFlowProvider, (prev, next) {
      if (prev?.input.unit != next.input.unit) {
        _syncControllersFromState(next);
      }
    });

    final isMetric = state.input.unit == UnitSystem.metric;
    final flowUnit = isMetric ? 'm³/h' : 'GPM';
    final diamUnit = isMetric ? 'mm' : 'in';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Lưu Lượng Nước',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: const Text('ASHRAE Ch.22', style: TextStyle(fontSize: 10, color: Colors.white70)),
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildUnitToggle(state, notifier),
          const SizedBox(height: 16),
          _buildInputCard(state, notifier, flowUnit, diamUnit),
          const SizedBox(height: 16),
          _buildMaterialServiceCard(state, notifier),
          if (state.status == WaterFlowStatus.success && state.result != null) ...[
            const SizedBox(height: 16),
            _buildResultsSection(state),
          ],
          if (state.status == WaterFlowStatus.error) ...[
            const SizedBox(height: 16),
            _buildErrorSection(state),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitToggle(WaterFlowState state, WaterFlowNotifier notifier) {
    final isMetric = state.input.unit == UnitSystem.metric;
    return Row(
      children: [
        Expanded(
          child: _buildToggleButton(
            label: 'Metric (m³/h, mm)',
            isSelected: isMetric,
            onTap: () => notifier.onUnitSystemChanged(UnitSystem.metric),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildToggleButton(
            label: 'Imperial (GPM, in)',
            isSelected: !isMetric,
            onTap: () => notifier.onUnitSystemChanged(UnitSystem.imperial),
          ),
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

  Widget _buildInputCard(WaterFlowState state, WaterFlowNotifier notifier, String flowUnit, String diamUnit) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: const [
                Icon(Icons.input, color: AppColors.accentBright, size: 18),
                SizedBox(width: 8),
                Text('Đầu vào', style: TextStyle(color: AppColors.accentBright, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
          const Divider(color: AppColors.divider),
          _buildInputField('Đường kính trong ống', diamUnit, _diameterController, (v) {
            final d = double.tryParse(v);
            if (d != null && d > 0) notifier.onDiameterChanged(d);
          }),
          const Divider(color: AppColors.divider),
          _buildInputField('Lưu lượng', flowUnit, _flowController, (v) {
            final d = double.tryParse(v);
            if (d != null && d > 0) notifier.onFlowRateChanged(d);
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMaterialServiceCard(WaterFlowState state, WaterFlowNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: const [
                Icon(Icons.settings, color: AppColors.accentBright, size: 18),
                SizedBox(width: 8),
                Text('VẬT LIỆU & DỊCH VỤ', style: TextStyle(color: AppColors.accentBright, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
          const Divider(color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: const Text('Vật liệu ống', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<PipeMaterial>(
              value: state.input.material,
              isExpanded: true,
              dropdownColor: AppColors.bgCard,
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: PipeMaterial.values.map((m) {
                return DropdownMenuItem(value: m, child: Text(HydronicConstants.getMaterialNameVi(m)));
              }).toList(),
              onChanged: (v) {
                if (v != null) notifier.onMaterialChanged(v);
              },
            ),
          ),
          const Divider(color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: const Text('Loại dịch vụ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<PipeService>(
              value: state.input.service,
              isExpanded: true,
              dropdownColor: AppColors.bgCard,
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: PipeService.values.map((s) {
                return DropdownMenuItem(value: s, child: Text(HydronicConstants.getServiceNameVi(s)));
              }).toList(),
              onChanged: (v) {
                if (v != null) notifier.onServiceChanged(v);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildResultsSection(WaterFlowState state) {
    final r = state.result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Warning banner
        if (r.warning != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.warning!,
                    style: const TextStyle(color: Colors.amber, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Velocity result
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: const [
                    Icon(Icons.speed, color: AppColors.accentBright, size: 18),
                    SizedBox(width: 8),
                    Text('KẾT QUẢ', style: TextStyle(color: AppColors.accentBright, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),
              const Divider(color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildBigResultRow(
                      icon: Icons.speed,
                      label: 'Vận tốc dòng chảy',
                      value: '${r.velocityMs.toStringAsFixed(2)} m/s',
                      subValue: '${r.velocityFps.toStringAsFixed(2)} ft/s  |  ${r.velocityFpm.toStringAsFixed(0)} FPM',
                    ),
                    const Divider(color: AppColors.divider),
                    _buildResultRow('Lưu lượng (GPM)', '${r.flowRateGpm.toStringAsFixed(1)} GPM'),
                    _buildResultRow('Lưu lượng (L/s)', '${r.flowRateLs.toStringAsFixed(2)} L/s'),
                    _buildResultRow('Lưu lượng (m³/h)', '${r.flowRateM3h.toStringAsFixed(1)} m³/h'),
                    const Divider(color: AppColors.divider),
                    _buildResultRow('Reynolds Number', 'Re = ${r.reynolds.toStringAsFixed(0)}'),
                    _buildResultRow(
                      'Chế độ dòng chảy',
                      HydronicConstants.getRegimeNameVi(r.regime),
                      valueColor: _regimeColor(r.regime),
                    ),
                    const Divider(color: AppColors.divider),
                    _buildResultRow('Hệ số ma sát Darcy', 'f = ${r.darcyFrictionFactor.toStringAsFixed(4)}'),
                    _buildResultRow('Độ nhám tương đối', 'ε/D = ${r.relativeRoughness.toStringAsFixed(5)}'),
                    _buildResultRow('Áp suất vận tốc (vp)', '${r.velocityPressurePa.toStringAsFixed(1)} Pa'),
                    _buildResultRow('Đường kính trong', '${r.diameterIn.toStringAsFixed(3)} in  |  ${(r.diameterM * 1000).toStringAsFixed(1)} mm'),
                    _buildResultRow('Diện tích mặt cắt', '${r.areaM2.toStringAsFixed(5)} m²  |  ${r.areaFt2.toStringAsFixed(4)} ft²'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Velocity gauge
        _buildVelocityGauge(r),
      ],
    );
  }

  Color _regimeColor(FlowRegime regime) {
    switch (regime) {
      case FlowRegime.laminar: return Colors.blue;
      case FlowRegime.transitional: return Colors.orange;
      case FlowRegime.turbulent: return Colors.green;
    }
  }

  Widget _buildBigResultRow({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentBright, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                if (subValue != null)
                  Text(subValue, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildVelocityGauge(WaterFlowResult r) {
    final limits = HydronicConstants.velocityLimitsMps[r.input.service]!;
    final pct = ((r.velocityMs - limits.min) / (limits.max - limits.min)).clamp(0.0, 1.0);
    final color = pct > 0.85
        ? Colors.red
        : pct > 0.6
            ? Colors.amber
            : Colors.green;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Đồng hồ vận tốc', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Text(
                'Giới hạn: ${limits.min.toStringAsFixed(1)}–${limits.max.toStringAsFixed(1)} m/s',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: AppColors.bgSecondary,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${limits.min} m/s', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              Text(
                '${r.velocityMs.toStringAsFixed(2)} m/s',
                style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text('${limits.max} m/s', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(WaterFlowState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.errorMessage ?? 'Lỗi tính toán.',
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String suffix,
    TextEditingController controller,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                suffixText: suffix,
                suffixStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                filled: true,
                fillColor: AppColors.bgSecondary,
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
