import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hvac/models/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../constants/hydronic_constants.dart';
import '../data/fitting_coefficients.dart';
import '../formulas/pipe_pressure_loss_engine.dart';
import '../providers/pump_head_provider.dart';

class PumpHeadScreen extends ConsumerStatefulWidget {
  const PumpHeadScreen({super.key});

  @override
  ConsumerState<PumpHeadScreen> createState() => _PumpHeadScreenState();
}

class _PumpHeadScreenState extends ConsumerState<PumpHeadScreen> {
  final _flowController = TextEditingController();
  final _diameterController = TextEditingController();
  final _lengthController = TextEditingController();
  final _staticHeadController = TextEditingController();
  final _suctionController = TextEditingController();
  final _dischargeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllers(ref.read(pumpHeadProvider));
    });
  }

  @override
  void dispose() {
    _flowController.dispose();
    _diameterController.dispose();
    _lengthController.dispose();
    _staticHeadController.dispose();
    _suctionController.dispose();
    _dischargeController.dispose();
    super.dispose();
  }

  void _syncControllers(PumpHeadState state) {
    _flowController.text = state.flowRate.toStringAsFixed(1);
    _diameterController.text = state.pipeDiameterIn.toStringAsFixed(2);
    _lengthController.text = state.pipeLengthFt.toStringAsFixed(0);
    _staticHeadController.text = state.staticHeadFt.toStringAsFixed(1);
    _suctionController.text = state.suctionPressurePsi.toStringAsFixed(1);
    _dischargeController.text = state.dischargePressurePsi.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pumpHeadProvider);
    final notifier = ref.read(pumpHeadProvider.notifier);
    final result = ref.watch(pumpHeadResultProvider);

    // Sync controllers when state changes from non-text sources (sliders, etc.)
    if (_flowController.text != state.flowRate.toStringAsFixed(1)) {
      _syncControllers(state);
    }

    final isMetric = state.unit == UnitSystem.metric;
    final flowUnit = isMetric ? 'm³/h' : 'GPM';
    final lengthUnit = isMetric ? 'm' : 'ft';
    final diamUnit = isMetric ? 'mm' : 'in';
    final headUnit = isMetric ? 'm' : 'ft';
    final pressUnit = isMetric ? 'kPa' : 'PSI';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pump Head Calculator',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: state.unit == UnitSystem.imperial
                ? 'Switch to Metric'
                : 'Switch to Imperial',
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            onPressed: () {
              notifier.onUnitToggled();
              _syncControllers(ref.read(pumpHeadProvider));
            },
          ),
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              notifier.reset();
              _syncControllers(ref.read(pumpHeadProvider));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildResultCard(result, headUnit, pressUnit),
            const SizedBox(height: 16),
            _buildSystemSection(
              context: context,
              notifier: notifier,
              state: state,
              flowUnit: flowUnit,
              lengthUnit: lengthUnit,
              diamUnit: diamUnit,
              pressUnit: pressUnit,
              headUnit: headUnit,
            ),
            const SizedBox(height: 16),
            _buildPipeSection(
              context: context,
              notifier: notifier,
              state: state,
              diamUnit: diamUnit,
              lengthUnit: lengthUnit,
            ),
            const SizedBox(height: 16),
            _buildStaticHeadSection(
              notifier: notifier,
              headUnit: headUnit,
              pressUnit: pressUnit,
            ),
            const SizedBox(height: 16),
            _buildFittingsSection(context, notifier, state),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(PumpHeadResult? result, String headUnit, String pressUnit) {
    if (result == null) {
      return _card(
        color: AppColors.bgSecondary,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Nhập thông số hợp lệ để tính cột áp bơm.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      );
    }

    return _card(
      color: AppColors.bgSecondary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Dynamic Head (TDH)',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  result.totalHeadFt.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppColors.accentPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ft ($headUnit)',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  result.totalHeadM.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'm',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${result.totalHeadPsi.toStringAsFixed(2)} PSI · '
              '${result.totalHeadKpa.toStringAsFixed(1)} kPa · '
              '${result.totalHeadBar.toStringAsFixed(2)} bar',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildResultRow(
              'Static head',
              '${result.staticHeadFt.toStringAsFixed(2)} ft · '
                  '${result.staticHeadM.toStringAsFixed(2)} m',
            ),
            _buildResultRow(
              'Pipe + fitting friction',
              '${result.frictionHeadFt.toStringAsFixed(2)} ft · '
                  '${result.frictionHeadM.toStringAsFixed(2)} m',
            ),
            _buildResultRow(
              '  Pipe friction',
              '${result.pipeFrictionFt.toStringAsFixed(2)} ft',
            ),
            _buildResultRow(
              '  Fitting loss',
              '${result.fittingFrictionFt.toStringAsFixed(2)} ft',
            ),
            _buildResultRow(
              'Velocity head',
              '${result.velocityHeadFt.toStringAsFixed(3)} ft · '
                  '${result.velocityHeadM.toStringAsFixed(3)} m',
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildResultRow(
              'Hydraulic power',
              '${result.waterPowerHp.toStringAsFixed(2)} HP · '
                  '${result.waterPowerKw.toStringAsFixed(2)} kW',
            ),
            _buildResultRow(
              'Brake power (motor)',
              '${result.brakePowerHp.toStringAsFixed(2)} HP · '
                  '${result.brakePowerKw.toStringAsFixed(2)} kW',
            ),
            _buildResultRow(
              'Motor efficiency',
              '${(result.motorEfficiency * 100).toStringAsFixed(0)} %',
            ),
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: result.warnings
                      .map((w) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Colors.orange, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    w,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
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
          Flexible(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSection({
    required BuildContext context,
    required PumpHeadNotifier notifier,
    required state,
    required String flowUnit,
    required String lengthUnit,
    required String diamUnit,
    required String pressUnit,
    required String headUnit,
  }) {
    return _section(
      title: 'System Inputs',
      children: [
        _numberField(
          label: 'Flow Rate ($flowUnit)',
          controller: _flowController,
          onChanged: (v) =>
              notifier.onFlowChanged(double.tryParse(v) ?? 0),
          minValue: 0,
          maxValue: 100000,
        ),
        _dropdown<PipeService>(
          label: 'Service',
          value: state.service,
          items: PipeService.values,
          labelFor: HydronicConstants.getServiceNameVi,
          onChanged: notifier.onServiceChanged,
        ),
        _slider(
          label: 'Glycol concentration '
              '(${(state.glycolConcentration * 100).toStringAsFixed(0)}%)',
          value: state.glycolConcentration,
          min: 0,
          max: 0.4,
          divisions: 4,
          onChanged: notifier.onGlycolChanged,
        ),
      ],
    );
  }

  Widget _buildPipeSection({
    required BuildContext context,
    required PumpHeadNotifier notifier,
    required state,
    required String diamUnit,
    required String lengthUnit,
  }) {
    return _section(
      title: 'Pipe',
      children: [
        _dropdown<PipeMaterial>(
          label: 'Material',
          value: state.material,
          items: PipeMaterial.values,
          labelFor: HydronicConstants.getMaterialNameVi,
          onChanged: notifier.onMaterialChanged,
        ),
        _numberField(
          label: 'Diameter ($diamUnit)',
          controller: _diameterController,
          onChanged: (v) =>
              notifier.onDiameterChanged(double.tryParse(v) ?? 0),
          minValue: 0,
          maxValue: 1000,
        ),
        _numberField(
          label: 'Length ($lengthUnit)',
          controller: _lengthController,
          onChanged: (v) =>
              notifier.onLengthChanged(double.tryParse(v) ?? 0),
          minValue: 0,
          maxValue: 100000,
        ),
        _dropdown<FrictionMethod>(
          label: 'Friction method',
          value: state.method,
          items: FrictionMethod.values,
          labelFor: _methodLabel,
          onChanged: notifier.onMethodChanged,
        ),
      ],
    );
  }

  Widget _buildStaticHeadSection({
    required PumpHeadNotifier notifier,
    required String headUnit,
    required String pressUnit,
  }) {
    return _section(
      title: 'Static Head',
      children: [
        _numberField(
          label: 'Elevation difference ($headUnit)',
          controller: _staticHeadController,
          onChanged: (v) =>
              notifier.onStaticHeadChanged(double.tryParse(v) ?? 0),
          minValue: -1000,
          maxValue: 1000,
        ),
        _numberField(
          label: 'Suction pressure ($pressUnit)',
          controller: _suctionController,
          onChanged: (v) =>
              notifier.onSuctionPressureChanged(double.tryParse(v) ?? 0),
          minValue: -1000,
          maxValue: 1000,
        ),
        _numberField(
          label: 'Discharge pressure ($pressUnit)',
          controller: _dischargeController,
          onChanged: (v) =>
              notifier.onDischargePressureChanged(double.tryParse(v) ?? 0),
          minValue: -1000,
          maxValue: 1000,
        ),
      ],
    );
  }

  Widget _buildFittingsSection(
    BuildContext context,
    PumpHeadNotifier notifier,
    state,
  ) {
    return _section(
      title: 'Fittings (optional)',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: state.fittings
              .asMap()
              .entries
              .map((e) => Chip(
                    label: Text(
                      '${e.value.quantity}× '
                      '${getFittingNameVi(e.value.type)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onDeleted: () => notifier.removeFitting(e.key),
                    backgroundColor: AppColors.bgCard,
                    labelStyle: const TextStyle(color: Colors.white),
                    deleteIconColor: Colors.white70,
                  ))
              .toList(),
        ),
        if (state.fittings.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: notifier.clearFittings,
              child: const Text('Clear all'),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add fitting'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bgCard,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _showAddFittingDialog(context, notifier),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddFittingDialog(BuildContext context, PumpHeadNotifier notifier) {
    FittingType selected = FittingType.elbow90Threaded;
    int count = 1;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: AppColors.bgSecondary,
              title: const Text(
                'Add fitting',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<FittingType>(
                    initialValue: selected,
                    dropdownColor: AppColors.bgSecondary,
                    decoration: const InputDecoration(
                      labelText: 'Fitting type',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                    items: FittingType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                getFittingNameVi(t),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => selected = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Count',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    controller: TextEditingController(text: '$count'),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n > 0) setState(() => count = n);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    notifier.addFitting(selected, count);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────

  Widget _section({required String title, required List<Widget> children}) {
    return _card(
      color: AppColors.bgSecondary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.accentPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _card({required Color color, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    double minValue = 0,
    double maxValue = 1000,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
        ],
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: AppColors.bgCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentPrimary,
              inactiveTrackColor: AppColors.bgCard,
              thumbColor: AppColors.accentPrimary,
              overlayColor:
                  AppColors.accentPrimary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) labelFor,
    required ValueChanged<T> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        dropdownColor: AppColors.bgSecondary,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: AppColors.bgCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        style: const TextStyle(color: Colors.white),
        items: items
            .map((i) => DropdownMenuItem<T>(
                  value: i,
                  child: Text(
                    labelFor(i),
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

String _methodLabel(FrictionMethod m) {
  switch (m) {
    case FrictionMethod.darcyWeisbach:
      return 'Darcy-Weisbach';
    case FrictionMethod.hazenWilliams:
      return 'Hazen-Williams';
  }
}
