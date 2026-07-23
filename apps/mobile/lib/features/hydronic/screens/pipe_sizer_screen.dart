import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/hvac/models/enums.dart';
import '../constants/hydronic_constants.dart';
import '../formulas/pipe_sizer_engine.dart';
import '../providers/pipe_sizer_provider.dart';

class PipeSizerScreen extends ConsumerStatefulWidget {
  const PipeSizerScreen({super.key});

  @override
  ConsumerState<PipeSizerScreen> createState() => _PipeSizerScreenState();
}

class _PipeSizerScreenState extends ConsumerState<PipeSizerScreen> {
  final _flowController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(pipeSizerProvider);
      _flowController.text = state.input.flowRate.toStringAsFixed(1);
    });
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pipeSizerProvider);
    final notifier = ref.read(pipeSizerProvider.notifier);

    ref.listen<PipeSizerState>(pipeSizerProvider, (prev, next) {
      if (prev?.input.unit != next.input.unit) {
        _flowController.text = next.input.flowRate.toStringAsFixed(1);
      }
    });

    final isMetric = state.input.unit == UnitSystem.metric;
    final flowUnit = isMetric ? 'm³/h' : 'GPM';

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
          'Pipe Sizer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: const Text(
                'ASHRAE Ch.22',
                style: TextStyle(fontSize: 10, color: Colors.white70),
              ),
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
          _buildInputCard(state, notifier, flowUnit),
          const SizedBox(height: 16),
          _buildMaterialCard(state, notifier),
          if (state.status == PipeSizerStatus.success &&
              state.result != null) ...[
            const SizedBox(height: 16),
            _buildResultsSection(state),
          ],
          if (state.status == PipeSizerStatus.error) ...[
            const SizedBox(height: 16),
            _buildErrorSection(state),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitToggle(PipeSizerState state, PipeSizerNotifier notifier) {
    final isMetric = state.input.unit == UnitSystem.metric;
    return Row(
      children: [
        Expanded(
          child: _buildToggleButton(
            label: 'Metric (m³/h)',
            isSelected: isMetric,
            onTap: () => notifier.onUnitSystemChanged(UnitSystem.metric),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildToggleButton(
            label: 'Imperial (GPM)',
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

  Widget _buildInputCard(
    PipeSizerState state,
    PipeSizerNotifier notifier,
    String flowUnit,
  ) {
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
                Text(
                  'ĐẦU VÀO',
                  style: TextStyle(
                    color: AppColors.accentBright,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 180,
                  child: Text(
                    'Lưu lượng thiết kế',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _flowController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      suffixText: flowUnit,
                      suffixStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.bgSecondary,
                    ),
                    onChanged: (v) {
                      final d = double.tryParse(v);
                      if (d != null && d > 0) notifier.onFlowRateChanged(d);
                    },
                  ),
                ),
              ],
            ),
          ),
          if (state.result != null) ...[
            const Divider(color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Giới hạn vận tốc (${state.input.service.name})',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${state.result!.minVelocityMs.toStringAsFixed(1)} – ${state.result!.maxVelocityMs.toStringAsFixed(1)} m/s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(PipeSizerState state, PipeSizerNotifier notifier) {
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
                Text(
                  'VẬT LIỆU & DỊCH VỤ',
                  style: TextStyle(
                    color: AppColors.accentBright,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: const Text(
              'Loại dịch vụ',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
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
                return DropdownMenuItem(
                  value: s,
                  child: Text(HydronicConstants.getServiceNameVi(s)),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) notifier.onServiceChanged(v);
              },
            ),
          ),
          const Divider(color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: const Text(
              'Vật liệu ống',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
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
                return DropdownMenuItem(
                  value: m,
                  child: Text(HydronicConstants.getMaterialNameVi(m)),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) notifier.onMaterialChanged(v);
              },
            ),
          ),
          const Divider(color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: const Text(
              'Schedule (Steel)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<PipeSchedule>(
              value: state.input.schedule,
              isExpanded: true,
              dropdownColor: AppColors.bgCard,
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: const [
                DropdownMenuItem(
                  value: PipeSchedule.schedule40,
                  child: Text('Schedule 40'),
                ),
                DropdownMenuItem(
                  value: PipeSchedule.schedule80,
                  child: Text('Schedule 80'),
                ),
              ],
              onChanged: (v) {
                if (v != null) notifier.onScheduleChanged(v);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildResultsSection(PipeSizerState state) {
    final r = state.result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        // Primary recommendation
        Container(
          decoration: BoxDecoration(
            color: AppColors.accentPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accentPrimary.withValues(alpha: 0.5),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.accentPrimary,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kích thước ống khuyến nghị',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${r.nominalSizeIn.toStringAsFixed(r.nominalSizeIn % 1 == 0 ? 0 : 2)}" '
                      '(${r.actualIdIn.toStringAsFixed(3)}" ID)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${r.actualIdM.toStringAsFixed(4)} m  |  ${(r.actualIdM * 1000).toStringAsFixed(1)} mm',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
                    Text(
                      'KẾT QUẢ CHI TIẾT',
                      style: TextStyle(
                        color: AppColors.accentBright,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
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
                      label: 'Vận tốc thực tế',
                      value: '${r.velocityMs.toStringAsFixed(2)} m/s',
                      subValue:
                          '${r.velocityFps.toStringAsFixed(2)} ft/s  |  ${r.velocityFpm.toStringAsFixed(0)} FPM',
                    ),
                    const Divider(color: AppColors.divider),
                    _buildResultRow(
                      'Lưu lượng',
                      '${state.input.flowRate.toStringAsFixed(1)} ${state.input.unit == UnitSystem.metric ? 'm³/h' : 'GPM'} '
                          '(${r.input.flowRateGpm.toStringAsFixed(1)} GPM)',
                    ),
                    _buildResultRow(
                      'Đường kính tính toán',
                      '${r.calculatedDiameterM.toStringAsFixed(4)} m '
                          '(${(r.calculatedDiameterM * 1000).toStringAsFixed(1)} mm)',
                    ),
                    const Divider(color: AppColors.divider),
                    _buildResultRow(
                      'Reynolds Number',
                      'Re = ${r.reynolds.toStringAsFixed(0)}',
                    ),
                    _buildResultRow(
                      'Chế độ dòng chảy',
                      HydronicConstants.getRegimeNameVi(r.regime),
                      valueColor: _regimeColor(r.regime),
                    ),
                    _buildResultRow(
                      'Hệ số ma sát Darcy',
                      'f = ${r.darcyFrictionFactor.toStringAsFixed(4)}',
                    ),
                    _buildResultRow(
                      'Tỷ lệ ma sát',
                      '${r.frictionRateFth.toStringAsFixed(2)} ft/100ft  '
                          '(${r.frictionRateMperM.toStringAsFixed(4)} m/m)',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Candidates table
        _buildCandidatesTable(r),
      ],
    );
  }

  Color _regimeColor(FlowRegime regime) {
    switch (regime) {
      case FlowRegime.laminar:
        return Colors.blue;
      case FlowRegime.transitional:
        return Colors.orange;
      case FlowRegime.turbulent:
        return Colors.green;
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
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subValue != null)
                  Text(
                    subValue,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
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
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidatesTable(PipeSizerResult r) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'BẢNG KÍCH THƯỚC ỐNG',
              style: TextStyle(
                color: AppColors.accentBright,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const Divider(color: AppColors.divider),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: const [
                SizedBox(
                  width: 50,
                  child: Text(
                    'Nominal',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'ID (in)',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'V (m/s)',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                Expanded(
                  child: Text(
                    'f (Darcy)',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          ...r.candidates.map((c) {
            final isSelected = c.nominalIn == r.nominalSizeIn;
            return Container(
              color: isSelected
                  ? AppColors.accentPrimary.withValues(alpha: 0.1)
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${c.nominalIn.toStringAsFixed(c.nominalIn % 1 == 0 ? 0 : 2)}"',
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.accentPrimary
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      c.idIn.toStringAsFixed(3),
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.accentPrimary
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      c.velocityMs.toStringAsFixed(2),
                      style: TextStyle(
                        color: c.velocityMs > r.maxVelocityMs
                            ? Colors.red
                            : c.velocityMs < r.minVelocityMs
                            ? Colors.orange
                            : Colors.green,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      c.darcyFrictionFactor.toStringAsFixed(4),
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.accentPrimary
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildErrorSection(PipeSizerState state) {
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
}
