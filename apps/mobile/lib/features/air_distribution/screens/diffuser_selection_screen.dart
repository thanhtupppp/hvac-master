import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/hvac/models/enums.dart';
import '../providers/diffuser_selection_provider.dart';
import '../formulas/diffuser_selection_engine.dart';
import '../data/diffuser_catalog.dart';

class DiffuserSelectionScreen extends ConsumerStatefulWidget {
  const DiffuserSelectionScreen({super.key});

  @override
  ConsumerState<DiffuserSelectionScreen> createState() =>
      _DiffuserSelectionScreenState();
}

class _DiffuserSelectionScreenState
    extends ConsumerState<DiffuserSelectionScreen> {
  final _cfmController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _ceilingController = TextEditingController();
  final _achController = TextEditingController();
  final _throwController = TextEditingController();
  final _mountController = TextEditingController();

  int _diffuserCount = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllersFromState(ref.read(diffuserSelectionProvider));
    });
  }

  @override
  void dispose() {
    _cfmController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _ceilingController.dispose();
    _achController.dispose();
    _throwController.dispose();
    _mountController.dispose();
    super.dispose();
  }

  void _syncControllersFromState(DiffuserSelectionState state) {
    final i = state.input;
    _cfmController.text = i.totalCfm.toStringAsFixed(0);
    _lengthController.text = i.roomLengthFt.toStringAsFixed(0);
    _widthController.text = i.roomWidthFt.toStringAsFixed(0);
    _ceilingController.text = i.ceilingHeightFt.toStringAsFixed(0);
    _achController.text = i.ach.toStringAsFixed(1);
    _throwController.text = i.throwDistanceFt.toStringAsFixed(0);
    _mountController.text = i.mountingHeightFt.toStringAsFixed(0);
    _diffuserCount = i.diffuserCount;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diffuserSelectionProvider);
    final notifier = ref.read(diffuserSelectionProvider.notifier);

    ref.listen<DiffuserSelectionState>(diffuserSelectionProvider, (prev, next) {
      if (prev?.input.unit != next.input.unit) {
        _syncControllersFromState(next);
      }
    });

    final isMetric = state.input.unit == UnitSystem.metric;
    final lengthSuffix = isMetric ? 'm' : 'ft';
    final volSuffix = isMetric ? 'm³/h' : 'CFM';
    final velSuffix = isMetric ? 'm/s' : 'fpm';

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
          'Chọn Diffuser / Miệng Gió',
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
          _buildUnitToggle(state, notifier),
          const SizedBox(height: 16),
          _buildMethodSection(state, notifier, volSuffix, lengthSuffix),
          const SizedBox(height: 16),
          _buildRoomSection(state, notifier, lengthSuffix),
          const SizedBox(height: 16),
          _buildAirflowSection(state, notifier, volSuffix, lengthSuffix),
          const SizedBox(height: 16),
          _buildDiffuserTypeSection(state, notifier),
          const SizedBox(height: 16),
          _buildAdvancedSection(state, notifier, velSuffix),
          if (state.status == DiffuserSelectionStatus.success &&
              state.result != null)
            _buildResultsSection(state),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(
    DiffuserSelectionState state,
    DiffuserSelectionNotifier notifier,
  ) {
    final isMetric = state.input.unit == UnitSystem.metric;
    return Row(
      children: [
        Expanded(
          child: _toggleButton(
            'Metric (SI)',
            isMetric,
            () => notifier.onUnitSystemChanged(UnitSystem.metric),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _toggleButton(
            'Imperial (IP)',
            !isMetric,
            () => notifier.onUnitSystemChanged(UnitSystem.imperial),
          ),
        ),
      ],
    );
  }

  Widget _toggleButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentPrimary : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accentPrimary : AppColors.divider,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMethodSection(
    DiffuserSelectionState state,
    DiffuserSelectionNotifier notifier,
    String volSuffix,
    String lengthSuffix,
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
          _sectionTitle('PHƯƠNG PHÁP'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _toggleButton(
                  'Theo Lưu Lượng',
                  state.input.method == DiffuserSizingMethod.byAirflow,
                  () =>
                      notifier.onMethodChanged(DiffuserSizingMethod.byAirflow),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _toggleButton(
                  'Theo Phòng',
                  state.input.method == DiffuserSizingMethod.byRoom,
                  () => notifier.onMethodChanged(DiffuserSizingMethod.byRoom),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _toggleButton(
                  'Theo ACH',
                  state.input.method == DiffuserSizingMethod.byAch,
                  () => notifier.onMethodChanged(DiffuserSizingMethod.byAch),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSection(
    DiffuserSelectionState state,
    DiffuserSelectionNotifier notifier,
    String lengthSuffix,
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
          _sectionTitle('KÍCH THƯỚC PHÒNG'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _inputField('Dài', lengthSuffix, _lengthController, (v) {
                  final d = double.tryParse(v);
                  if (d != null) notifier.onRoomLengthChanged(d);
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _inputField('Rộng', lengthSuffix, _widthController, (v) {
                  final d = double.tryParse(v);
                  if (d != null) notifier.onRoomWidthChanged(d);
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _inputField('Chiều cao trần', lengthSuffix, _ceilingController, (v) {
            final d = double.tryParse(v);
            if (d != null) notifier.onCeilingHeightChanged(d);
          }),
        ],
      ),
    );
  }

  Widget _buildAirflowSection(
    DiffuserSelectionState state,
    DiffuserSelectionNotifier notifier,
    String volSuffix,
    String lengthSuffix,
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
          _sectionTitle('LƯU LƯỢNG & ACH'),
          const SizedBox(height: 16),
          if (state.input.method == DiffuserSizingMethod.byAirflow)
            _inputField('Tổng lưu lượng', volSuffix, _cfmController, (v) {
              final d = double.tryParse(v);
              if (d != null) notifier.onTotalCfmChanged(d);
            }),
          if (state.input.method == DiffuserSizingMethod.byAch) ...[
            _inputField('ACH mục tiêu', 'lần/giờ', _achController, (v) {
              final d = double.tryParse(v);
              if (d != null) notifier.onAchChanged(d);
            }),
            const Divider(color: AppColors.divider),
            _inputField('Tổng lưu lượng (kết quả)', volSuffix, _cfmController, (
              v,
            ) {
              final d = double.tryParse(v);
              if (d != null) notifier.onTotalCfmChanged(d);
            }),
          ],
          if (state.input.method == DiffuserSizingMethod.byRoom) ...[
            _inputField(
              'Tổng lưu lượng (cho phòng)',
              volSuffix,
              _cfmController,
              (v) {
                final d = double.tryParse(v);
                if (d != null) notifier.onTotalCfmChanged(d);
              },
            ),
          ],
          const Divider(color: AppColors.divider),
          // Diffuser count stepper
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Số lượng diffuser',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              _stepper(
                _diffuserCount.toString(),
                () {
                  if (_diffuserCount > 1) {
                    setState(() => _diffuserCount--);
                    notifier.onDiffuserCountChanged(_diffuserCount);
                  }
                },
                () {
                  setState(() => _diffuserCount++);
                  notifier.onDiffuserCountChanged(_diffuserCount);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiffuserTypeSection(
    DiffuserSelectionState state,
    DiffuserSelectionNotifier notifier,
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
          _sectionTitle('LOẠI DIFFUSER'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DiffuserCatalog.supplyDiffusers.map((def) {
              final selected = state.input.diffuserType == def.type;
              return GestureDetector(
                onTap: () => notifier.onDiffuserTypeChanged(def.type),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accentPrimary.withValues(alpha: 0.2)
                        : AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.accentPrimary
                          : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        def.icon,
                        size: 14,
                        color: selected
                            ? AppColors.accentBright
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        def.displayName,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  bool _advancedExpanded = false;

  Widget _buildAdvancedSection(
    DiffuserSelectionState state,
    DiffuserSelectionNotifier notifier,
    String velSuffix,
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
              _sectionTitle('TIÊU CHÍ THIẾT KẾ'),
              IconButton(
                icon: Icon(
                  _advancedExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textMuted,
                ),
                onPressed: () =>
                    setState(() => _advancedExpanded = !_advancedExpanded),
              ),
            ],
          ),
          if (_advancedExpanded) ...[
            const SizedBox(height: 8),
            _inputField('Throw distance (mục tiêu)', 'ft', _throwController, (
              v,
            ) {
              final d = double.tryParse(v);
              if (d != null) notifier.onThrowDistanceChanged(d);
            }),
            const Divider(color: AppColors.divider),
            _inputField('Chiều cao lắp đặt', 'ft', _mountController, (v) {
              final d = double.tryParse(v);
              if (d != null) notifier.onMountingHeightChanged(d);
            }),
            const Divider(color: AppColors.divider),
            _inputField('Vận tốc cổ tối đa', velSuffix, null, (v) {
              final d = double.tryParse(v);
              if (d != null) notifier.onMaxNeckVelocityChanged(d);
            }),
            const Divider(color: AppColors.divider),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'NC rating tối đa',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                _ncSlider(state.input.maxNcRating, notifier),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _ncSlider(double value, DiffuserSelectionNotifier notifier) {
    return SizedBox(
      width: 120,
      child: Slider(
        value: value,
        min: 20,
        max: 50,
        divisions: 30,
        activeColor: AppColors.accentPrimary,
        inactiveColor: AppColors.divider,
        label: 'NC ${value.toStringAsFixed(0)}',
        onChanged: (v) => notifier.onMaxNcRatingChanged(v),
      ),
    );
  }

  Widget _stepper(String value, VoidCallback onMinus, VoidCallback onPlus) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepperBtn(Icons.remove, onMinus),
        SizedBox(
          width: 36,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        _stepperBtn(Icons.add, onPlus),
      ],
    );
  }

  Widget _stepperBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildResultsSection(DiffuserSelectionState state) {
    final r = state.result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _sectionTitle('KẾT QUẢ'),
        const SizedBox(height: 12),

        // Hero card
        if (r.selectedSize != null)
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
                  'SIZE ĐỀ XUẤT',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  r.selectedSize!.width == r.selectedSize!.length
                      ? '${r.selectedSize!.width.toStringAsFixed(0)}" × ${r.selectedSize!.length.toStringAsFixed(0)}"'
                      : '${r.selectedSize!.width.toStringAsFixed(0)}" × ${r.selectedSize!.length.toStringAsFixed(0)}"',
                  style: GoogleFonts.firaCode(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  r.diffuserDefinition.displayName,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _statBadge(
                      'CFM/chiếc',
                      r.cfmPerDiffuser.toStringAsFixed(0),
                    ),
                    _statBadge('Tổng CFM', r.totalCfm.toStringAsFixed(0)),
                    _statBadge('Số lượng', '${r.diffuserCount}'),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Room summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              _detailRow(
                'Diện tích phòng',
                '${r.roomAreaSqFt.toStringAsFixed(0)} sqft · ${r.roomAreaM2.toStringAsFixed(1)} m²',
              ),
              _detailRow(
                'Thể tích phòng',
                '${r.roomVolumeFt3.toStringAsFixed(0)} ft³ · ${r.roomVolumeM3.toStringAsFixed(1)} m³',
              ),
              if (r.effectiveAch > 0)
                _detailRow('ACH thực tế', r.effectiveAch.toStringAsFixed(1)),
            ],
          ),
        ),

        const SizedBox(height: 16),
        // Alternatives table
        Row(
          children: [
            const Icon(
              Icons.grid_view,
              color: AppColors.accentBright,
              size: 18,
            ),
            const SizedBox(width: 8),
            _sectionTitle('BẢNG SO SÁNH SIZE'),
          ],
        ),
        const SizedBox(height: 12),
        _buildAlternativesTable(r),

        // Warnings
        if (r.sizeWarning != null ||
            r.achWarning != null ||
            r.throwWarning != null) ...[
          const SizedBox(height: 16),
          _buildWarnings(r),
        ],
      ],
    );
  }

  Widget _statBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentBright.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentBright.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.accentBright,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.firaCode(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativesTable(DiffuserSelectionResult r) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                _tableHeader('Size', flex: 2),
                _tableHeader('V_cổ', flex: 2),
                _tableHeader('Throw', flex: 2),
                _tableHeader('NC', flex: 1),
                _tableHeader('ΔP', flex: 2),
                _tableHeader('', flex: 1),
              ],
            ),
          ),
          // Rows
          ...r.alternatives.asMap().entries.map((entry) {
            final idx = entry.key;
            final c = entry.value;
            final isSelected = r.selectedSize == c.size;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentPrimary.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: idx == r.alternatives.length - 1
                        ? Colors.transparent
                        : AppColors.divider.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${c.size.width.toStringAsFixed(0)}×${c.size.length.toStringAsFixed(0)}"',
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.accentBright
                            : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      c.neckVelocityFpm.toStringAsFixed(0),
                      style: TextStyle(
                        color: c.meetsNeckVelocity
                            ? Colors.white
                            : Colors.redAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${c.throwDistanceFt.toStringAsFixed(1)} ft',
                      style: TextStyle(
                        color: c.meetsThrow ? Colors.white : Colors.amber,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      c.ncRating.toString(),
                      style: TextStyle(
                        color: c.meetsNc ? Colors.white : Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      c.pressureDropInWg.toStringAsFixed(3),
                      style: GoogleFonts.firaCode(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: isSelected
                        ? const Icon(
                            Icons.star,
                            color: AppColors.accentBright,
                            size: 16,
                          )
                        : const SizedBox.shrink(),
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
          color: AppColors.textMuted,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildWarnings(DiffuserSelectionResult r) {
    return Column(
      children: [
        if (r.sizeWarning != null)
          _warningCard(r.sizeWarning!, Icons.error, Colors.red),
        if (r.achWarning != null)
          _warningCard(r.achWarning!, Icons.info, Colors.cyan),
        if (r.throwWarning != null)
          _warningCard(r.throwWarning!, Icons.swap_horiz, Colors.amber),
      ],
    );
  }

  Widget _warningCard(String text, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
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

  Widget _inputField(
    String label,
    String suffix,
    TextEditingController? controller,
    ValueChanged<String> onChanged,
  ) {
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
