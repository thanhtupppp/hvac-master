import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/hvac/models/enums.dart';
import '../constants/hydronic_constants.dart';
import '../data/fitting_coefficients.dart';
import '../formulas/pipe_pressure_loss_engine.dart';
import '../providers/pipe_pressure_loss_provider.dart';

class PipePressureLossScreen extends ConsumerStatefulWidget {
  const PipePressureLossScreen({super.key});

  @override
  ConsumerState<PipePressureLossScreen> createState() =>
      _PipePressureLossScreenState();
}

class _PipePressureLossScreenState
    extends ConsumerState<PipePressureLossScreen> {
  final _flowController = TextEditingController();
  final _diameterController = TextEditingController();
  final _lengthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(pipePressureLossProvider);
      _syncControllers(state);
    });
  }

  @override
  void dispose() {
    _flowController.dispose();
    _diameterController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  void _syncControllers(PipePressureLossState state) {
    _flowController.text = state.input.flowRate.toStringAsFixed(1);
    _diameterController.text = state.input.diameterIn.toStringAsFixed(1);
    _lengthController.text = state.input.lengthFt.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pipePressureLossProvider);
    final notifier = ref.read(pipePressureLossProvider.notifier);

    final isMetric = state.input.unit == UnitSystem.metric;
    final flowUnit = isMetric ? 'm³/h' : 'GPM';
    final lengthUnit = isMetric ? 'm' : 'ft';
    final diamUnit = isMetric ? 'mm' : 'in';

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
          'Tổn Thất Áp Suất',
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
                'Darcy-Weisbach',
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
          _buildInputCard(state, notifier, flowUnit, lengthUnit, diamUnit),
          const SizedBox(height: 16),
          _buildMethodCard(state, notifier),
          const SizedBox(height: 16),
          _buildFittingsCard(state, notifier),
          if (state.status == PipePressureLossStatus.success &&
              state.result != null) ...[
            const SizedBox(height: 16),
            _buildResultsSection(state),
          ],
          if (state.status == PipePressureLossStatus.error) ...[
            const SizedBox(height: 16),
            _buildErrorSection(state),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitToggle(
    PipePressureLossState state,
    PipePressureLossNotifier notifier,
  ) {
    final isMetric = state.input.unit == UnitSystem.metric;
    return Row(
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
    PipePressureLossState state,
    PipePressureLossNotifier notifier,
    String flowUnit,
    String lengthUnit,
    String diamUnit,
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
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
          _buildInputField('Lưu lượng', flowUnit, _flowController, (v) {
            final d = double.tryParse(v);
            if (d != null && d > 0) notifier.onFlowRateChanged(d);
          }),
          const Divider(color: AppColors.divider),
          _buildInputField('Đường kính trong', diamUnit, _diameterController, (
            v,
          ) {
            final d = double.tryParse(v);
            if (d != null && d > 0) notifier.onDiameterChanged(d);
          }),
          const Divider(color: AppColors.divider),
          _buildInputField('Chiều dài ống', lengthUnit, _lengthController, (v) {
            final d = double.tryParse(v);
            if (d != null && d > 0) notifier.onLengthChanged(d);
          }),
          const SizedBox(height: 8),
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
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
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
                suffixText: suffix,
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
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(
    PipePressureLossState state,
    PipePressureLossNotifier notifier,
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.settings, color: AppColors.accentBright, size: 18),
                SizedBox(width: 8),
                Text(
                  'PHƯƠNG PHÁP & VẬT LIỆU',
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Phương pháp tính',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                SegmentedButton<FrictionMethod>(
                  segments: const [
                    ButtonSegment(
                      value: FrictionMethod.darcyWeisbach,
                      label: Text('Darcy', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: FrictionMethod.hazenWilliams,
                      label: Text('H-W', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  selected: {state.input.method},
                  onSelectionChanged: (s) => notifier.onMethodChanged(s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.accentPrimary;
                      }
                      return AppColors.bgSecondary;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return AppColors.textSecondary;
                    }),
                  ),
                ),
              ],
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
              'Dịch vụ',
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nồng độ Glycol',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${(state.input.glycolConcentration * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: state.input.glycolConcentration,
              min: 0,
              max: 0.4,
              divisions: 8,
              activeColor: AppColors.accentBright,
              inactiveColor: AppColors.bgSecondary,
              onChanged: (v) => notifier.onGlycolChanged(v),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFittingsCard(
    PipePressureLossState state,
    PipePressureLossNotifier notifier,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: AppColors.accentBright,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'CỘT ĐỒNG HÌNH (FITTINGS)',
                      style: TextStyle(
                        color: AppColors.accentBright,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add,
                    color: AppColors.accentBright,
                    size: 20,
                  ),
                  onPressed: () => _showAddFittingDialog(context, notifier),
                ),
              ],
            ),
          ),
          if (state.input.fittings.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Chưa có fittings nào. Nhấn + để thêm.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else ...[
            const Divider(color: AppColors.divider),
            ...state.input.fittings.asMap().entries.map((e) {
              final idx = e.key;
              final fit = e.value;
              return Dismissible(
                key: ValueKey('fitting_$idx'),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red.withValues(alpha: 0.3),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.red, size: 20),
                ),
                onDismissed: (_) => notifier.removeFitting(idx),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.plumbing,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${getFittingNameVi(fit.type)} × ${fit.quantity} @ ${fit.nominalSizeIn}"',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        'K = ${fittingCatalog[fit.type]!.kFor(fit.nominalSizeIn, fit.connectionType).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showAddFittingDialog(
    BuildContext context,
    PipePressureLossNotifier notifier,
  ) {
    FittingType selectedType = FittingType.elbow90Threaded;
    double selectedSize = 2.0;
    int quantity = 1;
    String connectionType = 'threaded';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thêm Fitting',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loại fitting',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              DropdownButton<FittingType>(
                value: selectedType,
                isExpanded: true,
                dropdownColor: AppColors.bgCard,
                underline: const SizedBox(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: FittingType.values.take(15).map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(
                      getFittingNameVi(t),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (v) =>
                    setModalState(() => selectedType = v ?? selectedType),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kích thước (in)',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            suffixText: 'in',
                            filled: true,
                            fillColor: AppColors.bgSecondary,
                          ),
                          controller: TextEditingController(
                            text: selectedSize.toStringAsFixed(1),
                          ),
                          onChanged: (v) =>
                              selectedSize = double.tryParse(v) ?? selectedSize,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số lượng',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        TextField(
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: AppColors.bgSecondary,
                          ),
                          controller: TextEditingController(
                            text: quantity.toString(),
                          ),
                          onChanged: (v) => quantity = int.tryParse(v) ?? 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    notifier.addFitting(
                      FittingEntry(
                        type: selectedType,
                        nominalSizeIn: selectedSize,
                        quantity: quantity,
                        connectionType: connectionType,
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Thêm',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection(PipePressureLossState state) {
    final r = state.result!;
    return Column(
      children: [
        // Big total loss
        Container(
          decoration: BoxDecoration(
            color: AppColors.accentPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accentPrimary.withValues(alpha: 0.5),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.trending_down,
                    color: AppColors.accentPrimary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tổng tổn thất ma sát',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${r.totalFrictionFt.toStringAsFixed(2)} ft H₂O',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLossChip(
                    '${r.totalFrictionPsi.toStringAsFixed(2)} PSI',
                    r.totalFrictionPsi > 5 ? Colors.red : Colors.white,
                  ),
                  _buildLossChip(
                    '${r.totalFrictionKpa.toStringAsFixed(1)} kPa',
                    Colors.white,
                  ),
                  _buildLossChip(
                    '${r.totalFrictionBar.toStringAsFixed(2)} bar',
                    Colors.white,
                  ),
                  _buildLossChip(
                    '${r.totalFrictionM.toStringAsFixed(3)} m',
                    Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Details
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.speed, color: AppColors.accentBright, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'CHI TIẾT',
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
                    _buildResultRow(
                      'Chiều dài ống',
                      '${r.input.lengthFt.toStringAsFixed(0)} ft (${(r.input.lengthFt * 0.3048).toStringAsFixed(1)} m)',
                    ),
                    _buildResultRow(
                      'Đường kính trong',
                      '${r.input.diameterIn.toStringAsFixed(3)} in (${(r.input.diameterIn * 25.4).toStringAsFixed(1)} mm)',
                    ),
                    _buildResultRow(
                      'Vận tốc',
                      '${r.velocityMs.toStringAsFixed(2)} m/s (${r.velocityFps.toStringAsFixed(2)} ft/s)',
                    ),
                    _buildResultRow(
                      'Reynolds',
                      'Re = ${r.reynolds.toStringAsFixed(0)}',
                    ),
                    _buildResultRow(
                      'Hệ số ma sát Darcy',
                      'f = ${r.darcyFrictionFactor.toStringAsFixed(5)}',
                    ),
                    _buildResultRow(
                      'Độ nhám tương đối',
                      'ε/D = ${r.relativeRoughness.toStringAsFixed(5)}',
                    ),
                    _buildResultRow(
                      'Tỷ lệ ma sát (ống thẳng)',
                      '${r.frictionRateFth.toStringAsFixed(2)} ft/100ft',
                    ),
                    _buildResultRow(
                      'Tổn thất ống thẳng',
                      '${r.pipeFrictionFt.toStringAsFixed(3)} ft H₂O',
                    ),
                    _buildResultRow(
                      'Tổn thất fittings',
                      '${r.fittingFrictionFt.toStringAsFixed(3)} ft H₂O',
                    ),
                    if (r.hazenWilliamsC != null)
                      _buildResultRow(
                        'Hazen-Williams C',
                        r.hazenWilliamsC!.toStringAsFixed(0),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (r.fittingBreakdown.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'CHI TIẾT FITTINGS',
                    style: TextStyle(
                      color: AppColors.accentBright,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Divider(color: AppColors.divider),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Loại',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'K',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Số lượng',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Tổn thất ft',
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
                const Divider(color: AppColors.divider),
                ...r.fittingBreakdown.map(
                  (f) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            f.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            f.kValue.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            f.quantity.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            f.totalLossFt.toStringAsFixed(4),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLossChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(PipePressureLossState state) {
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
