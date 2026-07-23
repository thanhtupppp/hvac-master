import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hvac/models/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../data/pump_catalog.dart';
import '../formulas/pump_selection_engine.dart';
import '../providers/pump_selection_provider.dart';

class PumpSelectionScreen extends ConsumerStatefulWidget {
  const PumpSelectionScreen({super.key});

  @override
  ConsumerState<PumpSelectionScreen> createState() =>
      _PumpSelectionScreenState();
}

class _PumpSelectionScreenState extends ConsumerState<PumpSelectionScreen> {
  final _flowController = TextEditingController();
  final _headController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllers(ref.read(pumpSelectionProvider));
    });
  }

  @override
  void dispose() {
    _flowController.dispose();
    _headController.dispose();
    super.dispose();
  }

  void _syncControllers(PumpSelectionState state) {
    _flowController.text = state.flowRate.toStringAsFixed(1);
    _headController.text = state.headFt.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pumpSelectionProvider);
    final notifier = ref.read(pumpSelectionProvider.notifier);
    final result = ref.watch(pumpSelectionResultProvider);

    if (_flowController.text != state.flowRate.toStringAsFixed(1)) {
      _syncControllers(state);
    }

    final isMetric = state.unit == UnitSystem.metric;
    final flowUnit = isMetric ? 'm³/h' : 'GPM';
    final headUnit = isMetric ? 'm' : 'ft';

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
          'Pump Selection',
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
              _syncControllers(ref.read(pumpSelectionProvider));
            },
          ),
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              notifier.reset();
              _syncControllers(ref.read(pumpSelectionProvider));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRequiredPointCard(result, flowUnit, headUnit),
            const SizedBox(height: 16),
            _buildInputCard(notifier, state, flowUnit, headUnit),
            const SizedBox(height: 16),
            _buildFilterCard(notifier, state),
            const SizedBox(height: 16),
            _buildCandidatesCard(result),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredPointCard(
    PumpSelectionResult? result,
    String flowUnit,
    String headUnit,
  ) {
    if (result == null) {
      return _card(
        color: AppColors.bgSecondary,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Nhap luu luong va cot ap yeu cau.',
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
              'Operating Point (Required)',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _metricTile(
                  label: 'Flow',
                  value: result.requiredFlowGpm.toStringAsFixed(1),
                  unit: 'GPM',
                  highlight: true,
                ),
                const SizedBox(width: 12),
                _metricTile(
                  label: 'Head',
                  value: result.requiredHeadFt.toStringAsFixed(1),
                  unit: 'ft',
                  highlight: true,
                ),
              ],
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

  Widget _buildInputCard(
    PumpSelectionNotifier notifier,
    PumpSelectionState state,
    String flowUnit,
    String headUnit,
  ) {
    return _card(
      color: AppColors.bgSecondary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Required Point',
              style: TextStyle(
                color: AppColors.accentPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _numberField(
              label: 'Flow rate ($flowUnit)',
              controller: _flowController,
              onChanged: (v) => notifier.onFlowChanged(double.tryParse(v) ?? 0),
            ),
            _numberField(
              label: 'Head ($headUnit)',
              controller: _headController,
              onChanged: (v) => notifier.onHeadChanged(double.tryParse(v) ?? 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard(
    PumpSelectionNotifier notifier,
    PumpSelectionState state,
  ) {
    return _card(
      color: AppColors.bgSecondary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pump Type Filter (optional)',
              style: TextStyle(
                color: AppColors.accentPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap to toggle. Empty = all types.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PumpType.values
                  .map(
                    (t) => FilterChip(
                      label: Text(PumpCatalog.getPumpTypeVi(t)),
                      selected: state.pumpTypeFilter.contains(t),
                      onSelected: (_) => notifier.togglePumpType(t),
                      selectedColor: AppColors.accentPrimary,
                      backgroundColor: AppColors.bgCard,
                      labelStyle: TextStyle(
                        color: state.pumpTypeFilter.contains(t)
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidatesCard(PumpSelectionResult? result) {
    if (result == null) return const SizedBox.shrink();
    if (result.candidates.isEmpty) {
      return _card(
        color: AppColors.bgSecondary,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No matching pump in catalog. Adjust the operating point or '
            'expand filters.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return _card(
      color: AppColors.bgSecondary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommended Pumps (${result.candidates.length})',
              style: const TextStyle(
                color: AppColors.accentPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...result.candidates.asMap().entries.map(
              (entry) => _buildPumpCard(entry.key, entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPumpCard(int rank, PumpSelectionCandidate c) {
    final eff = c.efficiencyAtPoint * 100;
    final isTop = rank == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: isTop
            ? Border.all(color: AppColors.accentPrimary, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isTop
                      ? AppColors.accentPrimary
                      : AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${rank + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  c.pump.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            PumpCatalog.getPumpTypeVi(c.pump.type),
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const Divider(color: Colors.white12, height: 16),
          _buildPumpSpec('Efficiency at point', '${eff.toStringAsFixed(1)} %'),
          _buildPumpSpec(
            'Max flow',
            '${c.pump.maxFlowGpm.toStringAsFixed(0)} GPM',
          ),
          _buildPumpSpec(
            'Shutoff head',
            '${c.pump.maxHeadFt.toStringAsFixed(0)} ft',
          ),
          _buildPumpSpec(
            'Head margin',
            '+${c.headMarginFt.toStringAsFixed(1)} ft '
                '(${(c.headMarginPct * 100).toStringAsFixed(0)}%)',
          ),
          _buildPumpSpec(
            'Brake power',
            '${c.brakePowerHp.toStringAsFixed(2)} HP',
          ),
          _buildPumpSpec(
            'Operating at',
            '${(c.flowOperatingRatio * 100).toStringAsFixed(0)}% of max flow',
          ),
          if (isTop) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.green, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Best efficiency choice',
                    style: TextStyle(color: Colors.green, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPumpSpec(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

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
}
