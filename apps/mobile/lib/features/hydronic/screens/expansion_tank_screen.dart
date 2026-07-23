import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hvac/models/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../constants/hydronic_constants.dart';
import '../formulas/expansion_tank_engine.dart';
import '../providers/expansion_tank_provider.dart';

class ExpansionTankScreen extends ConsumerStatefulWidget {
  const ExpansionTankScreen({super.key});

  @override
  ConsumerState<ExpansionTankScreen> createState() =>
      _ExpansionTankScreenState();
}

class _ExpansionTankScreenState extends ConsumerState<ExpansionTankScreen> {
  final _volumeController = TextEditingController();
  final _tempInitialController = TextEditingController();
  final _tempFinalController = TextEditingController();
  final _prechargeController = TextEditingController();
  final _reliefController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllers(ref.read(expansionTankProvider));
    });
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _tempInitialController.dispose();
    _tempFinalController.dispose();
    _prechargeController.dispose();
    _reliefController.dispose();
    super.dispose();
  }

  void _syncControllers(ExpansionTankState state) {
    _volumeController.text = state.systemVolume.toStringAsFixed(0);
    _tempInitialController.text = state.tempInitial.toStringAsFixed(0);
    _tempFinalController.text = state.tempFinal.toStringAsFixed(0);
    _prechargeController.text = state.prechargePressure.toStringAsFixed(1);
    _reliefController.text = state.reliefPressure.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expansionTankProvider);
    final notifier = ref.read(expansionTankProvider.notifier);
    final result = ref.watch(expansionTankResultProvider);

    if (_volumeController.text != state.systemVolume.toStringAsFixed(0)) {
      _syncControllers(state);
    }

    final isMetric = state.unit == UnitSystem.metric;
    final volUnit = isMetric ? 'L' : 'gal';
    final tempUnit = isMetric ? '°C' : '°F';
    final pressUnit = isMetric ? 'kPa' : 'PSI';

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
          'Expansion Tank Calculator',
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
              _syncControllers(ref.read(expansionTankProvider));
            },
          ),
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              notifier.reset();
              _syncControllers(ref.read(expansionTankProvider));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildResultCard(result, volUnit),
            const SizedBox(height: 16),
            _buildSystemSection(
              notifier: notifier,
              volUnit: volUnit,
              tempUnit: tempUnit,
            ),
            const SizedBox(height: 16),
            _buildTempPressureSection(
              notifier: notifier,
              tempUnit: tempUnit,
              pressUnit: pressUnit,
            ),
            const SizedBox(height: 16),
            _buildOptionsSection(notifier: notifier),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ExpansionTankResult? result, String volUnit) {
    if (result == null) {
      return _card(
        color: AppColors.bgSecondary,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Nhap thong so hop le de tinh binh gian no.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      );
    }

    final stdGal = result.recommendedStandardSizeGal;
    final stdL = result.recommendedStandardSizeL;

    return _card(
      color: AppColors.bgSecondary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Required Tank Size (Total)',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _metricTile(
                  label: 'Standard size',
                  value: stdGal > 0 ? stdGal.toStringAsFixed(1) : 'N/A',
                  unit: 'gal',
                  highlight: true,
                ),
                const SizedBox(width: 12),
                _metricTile(
                  label: 'Standard size',
                  value: stdL > 0 ? stdL.toStringAsFixed(0) : 'N/A',
                  unit: 'L',
                  highlight: true,
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildResultRow(
              'Effective volume (no acceptance)',
              '${result.requiredVolumeGallons.toStringAsFixed(2)} gal · '
                  '${result.requiredVolumeLiters.toStringAsFixed(1)} L',
            ),
            _buildResultRow(
              'Acceptance volume (20%)',
              '${result.acceptanceVolumeGallons.toStringAsFixed(2)} gal · '
                  '${result.acceptanceVolumeLiters.toStringAsFixed(1)} L',
            ),
            _buildResultRow(
              'Water expansion (ΔV)',
              '${result.expansionVolumeGallons.toStringAsFixed(2)} gal · '
                  '${result.expansionVolumeLiters.toStringAsFixed(1)} L',
            ),
            _buildResultRow(
              'Expansion coefficient',
              '${(result.expansionCoeff * 100).toStringAsFixed(4)} %/°C',
            ),
            _buildResultRow(
              'Precharge / relief ratio',
              '${(result.prechargeRatio * 100).toStringAsFixed(1)} %',
            ),
            _buildResultRow(
              'Temperature rise',
              '${result.tempRiseC.toStringAsFixed(1)} °C',
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
                      .map(
                        (w) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 16,
                              ),
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
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricTile({
    required String label,
    required String value,
    required String unit,
    bool highlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: highlight ? AppColors.accentPrimary : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Expanded(
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
    required ExpansionTankNotifier notifier,
    required String volUnit,
    required String tempUnit,
  }) {
    return _section(
      title: 'System',
      children: [
        _numberField(
          label: 'Water volume ($volUnit)',
          controller: _volumeController,
          onChanged: (v) => notifier.onVolumeChanged(double.tryParse(v) ?? 0),
          minValue: 0,
          maxValue: 100000,
        ),
        _slider(
          label:
              'Glycol concentration (${(ref.read(expansionTankProvider).glycolConcentration * 100).toStringAsFixed(0)}%)',
          value: ref.read(expansionTankProvider).glycolConcentration,
          min: 0,
          max: 0.5,
          divisions: 5,
          onChanged: notifier.onGlycolChanged,
        ),
      ],
    );
  }

  Widget _buildTempPressureSection({
    required ExpansionTankNotifier notifier,
    required String tempUnit,
    required String pressUnit,
  }) {
    return _section(
      title: 'Temperature & Pressure',
      children: [
        _numberField(
          label: 'Initial temperature ($tempUnit)',
          controller: _tempInitialController,
          onChanged: (v) =>
              notifier.onTempInitialChanged(double.tryParse(v) ?? 0),
          minValue: -50,
          maxValue: 500,
        ),
        _numberField(
          label: 'Final temperature ($tempUnit)',
          controller: _tempFinalController,
          onChanged: (v) =>
              notifier.onTempFinalChanged(double.tryParse(v) ?? 0),
          minValue: -50,
          maxValue: 500,
        ),
        _numberField(
          label: 'Precharge pressure ($pressUnit)',
          controller: _prechargeController,
          onChanged: (v) =>
              notifier.onPrechargeChanged(double.tryParse(v) ?? 0),
          minValue: 0,
          maxValue: 500,
        ),
        _numberField(
          label: 'Relief valve setting ($pressUnit)',
          controller: _reliefController,
          onChanged: (v) => notifier.onReliefChanged(double.tryParse(v) ?? 0),
          minValue: 0,
          maxValue: 500,
        ),
      ],
    );
  }

  Widget _buildOptionsSection({required ExpansionTankNotifier notifier}) {
    return _section(
      title: 'Tank Type',
      children: [
        _dropdown<ExpansionTankType>(
          label: 'Tank type',
          value: ref.read(expansionTankProvider).tankType,
          items: ExpansionTankType.values,
          labelFor: _tankTypeLabel,
          onChanged: notifier.onTankTypeChanged,
        ),
        const SizedBox(height: 4),
        Text(
          _tankTypeDescription(ref.read(expansionTankProvider).tankType),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  // ── Shared widgets ─────────────────────────────────────────

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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
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
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentPrimary,
              inactiveTrackColor: AppColors.bgCard,
              thumbColor: AppColors.accentPrimary,
              overlayColor: AppColors.accentPrimary.withValues(alpha: 0.2),
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
    return DropdownButtonFormField<T>(
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      style: const TextStyle(color: Colors.white),
      items: items
          .map(
            (i) => DropdownMenuItem<T>(
              value: i,
              child: Text(labelFor(i), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

String _tankTypeLabel(ExpansionTankType t) {
  switch (t) {
    case ExpansionTankType.closedDiaphragm:
      return 'Closed (Diaphragm)';
    case ExpansionTankType.closedBladder:
      return 'Closed (Bladder)';
    case ExpansionTankType.open:
      return 'Open';
  }
}

String _tankTypeDescription(ExpansionTankType t) {
  switch (t) {
    case ExpansionTankType.closedDiaphragm:
      return 'Pre-charged steel tank with fixed internal diaphragm. '
          'For sealed hydronic systems.';
    case ExpansionTankType.closedBladder:
      return 'Pre-charged tank with replaceable bladder. Common for larger '
          'commercial systems.';
    case ExpansionTankType.open:
      return 'Open atmospheric tank (often elevated). Less common in modern '
          'sealed systems.';
  }
}
