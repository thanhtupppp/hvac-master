import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/hvac/models/enums.dart';
import '../constants/air_distribution_constants.dart';
import '../providers/equal_friction_provider.dart';
import '../formulas/equal_friction_engine.dart';

class EqualFrictionScreen extends ConsumerStatefulWidget {
  const EqualFrictionScreen({super.key});

  @override
  ConsumerState<EqualFrictionScreen> createState() =>
      _EqualFrictionScreenState();
}

class _EqualFrictionScreenState extends ConsumerState<EqualFrictionScreen> {
  final _airflowController = TextEditingController();
  final _frictionController = TextEditingController();
  final _lengthController = TextEditingController();
  final _maxVelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllersFromState(ref.read(equalFrictionProvider));
    });
  }

  @override
  void dispose() {
    _airflowController.dispose();
    _frictionController.dispose();
    _lengthController.dispose();
    _maxVelController.dispose();
    super.dispose();
  }

  void _syncControllersFromState(EqualFrictionState state) {
    final i = state.input;
    _airflowController.text = i.airflowCfm.toStringAsFixed(0);
    _frictionController.text = i.frictionRateInWg100ft.toStringAsFixed(3);
    _lengthController.text = i.lengthFt.toStringAsFixed(0);
    _maxVelController.text = i.maxVelocityFpm.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(equalFrictionProvider);
    final notifier = ref.read(equalFrictionProvider.notifier);

    ref.listen<EqualFrictionState>(equalFrictionProvider, (prev, next) {
      if (prev?.input.unit != next.input.unit) {
        _syncControllersFromState(next);
      }
    });

    final isMetric = state.input.unit == UnitSystem.metric;
    final volSuffix = isMetric ? 'm³/h' : 'CFM';
    final lenSuffix = isMetric ? 'm' : 'ft';
    final frictionSuffix = isMetric ? 'Pa/m' : 'in.wg/100ft';
    final velSuffix = isMetric ? 'm/s' : 'FPM';

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
          'Sizing Ống Gió — Equal Friction',
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
          _buildShapeSection(state, notifier),
          const SizedBox(height: 16),
          _buildDuctTypeSection(state, notifier),
          const SizedBox(height: 16),
          _buildAirflowSection(state, notifier, volSuffix, lenSuffix),
          const SizedBox(height: 16),
          _buildFrictionSection(state, notifier, frictionSuffix),
          const SizedBox(height: 16),
          _buildMaterialSection(state, notifier),
          const SizedBox(height: 16),
          _buildAdvancedSection(state, notifier, velSuffix),
          if (state.status == EqualFrictionStatus.success &&
              state.result != null)
            _buildResultsSection(state),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(
    EqualFrictionState state,
    EqualFrictionNotifier notifier,
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

  Widget _buildShapeSection(
    EqualFrictionState state,
    EqualFrictionNotifier notifier,
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
          _sectionTitle('HÌNH DẠNG ỐNG'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _shapeCard(
                  'Tròn (Round)',
                  Icons.circle_outlined,
                  state.input.shape == DuctShape.round,
                  () => notifier.onShapeChanged(DuctShape.round),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _shapeCard(
                  'Chữ nhật (Rect.)',
                  Icons.crop_square,
                  state.input.shape == DuctShape.rectangular,
                  () => notifier.onShapeChanged(DuctShape.rectangular),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shapeCard(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentPrimary.withValues(alpha: 0.2)
              : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accentPrimary : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.accentBright : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDuctTypeSection(
    EqualFrictionState state,
    EqualFrictionNotifier notifier,
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
          _sectionTitle('LOẠI ỐNG'),
          const SizedBox(height: 12),
          ...DuctType.values.map((type) {
            final selected = state.input.ductType == type;
            final limits = AirDistributionConstants.ductVelocityLimits[type];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => notifier.onDuctTypeChanged(type),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accentPrimary.withValues(alpha: 0.18)
                        : AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppColors.accentPrimary
                          : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AirDistributionConstants.getDuctTypeName(type),
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (limits != null)
                        Text(
                          '${limits.recommended.toStringAsFixed(0)} FPM',
                          style: TextStyle(
                            color: selected
                                ? AppColors.accentBright
                                : AppColors.textMuted,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      if (selected)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.check_circle,
                            color: AppColors.accentBright,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAirflowSection(
    EqualFrictionState state,
    EqualFrictionNotifier notifier,
    String volSuffix,
    String lenSuffix,
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
          _sectionTitle('LƯU LƯỢNG & ĐỘ DÀI'),
          const SizedBox(height: 16),
          _inputField('Lưu lượng', volSuffix, _airflowController, (v) {
            final d = double.tryParse(v);
            if (d != null) notifier.onAirflowChanged(d);
          }),
          const Divider(color: AppColors.divider),
          _inputField('Chiều dài ống', lenSuffix, _lengthController, (v) {
            final d = double.tryParse(v);
            if (d != null) notifier.onLengthChanged(d);
          }),
        ],
      ),
    );
  }

  Widget _buildFrictionSection(
    EqualFrictionState state,
    EqualFrictionNotifier notifier,
    String frictionSuffix,
  ) {
    final value = state.input.frictionRateInWg100ft;
    final recommended = AirDistributionConstants.frictionRecommendedInWg100ft;
    final min = AirDistributionConstants.frictionMinInWg100ft;
    final max = AirDistributionConstants.frictionMaxInWg100ft;

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
          _sectionTitle('FRICTION RATE MỤC TIÊU'),
          const SizedBox(height: 16),
          // Slider visualization
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Background bar with min/recommended/max markers
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: ((recommended - min) * 100).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            bottomLeft: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: ((max - recommended) * 100).round().clamp(1, 100),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Target marker
              Positioned(
                left:
                    ((value - min) / (max - min)).clamp(0.0, 1.0) *
                        (MediaQuery.of(context).size.width - 88) -
                    4,
                top: -4,
                bottom: -4,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: AppColors.accentBright,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              // Value bubble
              Positioned(
                left:
                    ((value - min) / (max - min)).clamp(0.05, 0.95) *
                        (MediaQuery.of(context).size.width - 120) -
                    16,
                top: -32,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentBright,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value.toStringAsFixed(3),
                    style: GoogleFonts.firaCode(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          // Slider
          Slider(
            value: value.clamp(0.01, 0.50),
            min: 0.01,
            max: 0.50,
            divisions: 49,
            activeColor: AppColors.accentPrimary,
            inactiveColor: AppColors.divider,
            onChanged: (v) {
              _frictionController.text = v.toStringAsFixed(3);
              notifier.onFrictionRateChanged(v);
            },
          ),
          // Markers row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Min ${min.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green, fontSize: 10),
                ),
                Text(
                  'Typical ${recommended.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.accentBright,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Max ${max.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.amber, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Friction rate input field (editable)
          _inputField('Friction rate', frictionSuffix, _frictionController, (
            v,
          ) {
            final d = double.tryParse(v);
            if (d != null) notifier.onFrictionRateChanged(d);
          }),
          const SizedBox(height: 8),
          _frictionExplanations(value),
        ],
      ),
    );
  }

  Widget _frictionExplanations(double value) {
    final recommended = AirDistributionConstants.frictionRecommendedInWg100ft;
    String explanation;
    Color color;
    if (value < recommended * 0.7) {
      explanation =
          'Friction rate thấp → ống lớn, ít ồn, chi phí cao. Phù hợp thư viện, bệnh viện.';
      color = Colors.cyan;
    } else if (value < recommended * 1.3) {
      explanation =
          'Friction rate điển hình → cân bằng giữa kích thước ống và chi phí quạt.';
      color = Colors.green;
    } else if (value < recommended * 2.5) {
      explanation =
          'Friction rate cao → ống nhỏ, tiết kiệm không gian, nhưng cần quạt áp cao.';
      color = Colors.amber;
    } else {
      explanation =
          'Friction rate rất cao → có thể gây ồn. Cân nhắc giảm tốc độ gió.';
      color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              explanation,
              style: TextStyle(color: color, fontSize: 11, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialSection(
    EqualFrictionState state,
    EqualFrictionNotifier notifier,
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
          _sectionTitle('VẬT LIỆU ỐNG'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DuctMaterial.values.map((m) {
              final selected = state.input.material == m;
              return GestureDetector(
                onTap: () => notifier.onMaterialChanged(m),
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
                  child: Text(
                    AirDistributionConstants.getDuctMaterialName(m),
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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
    EqualFrictionState state,
    EqualFrictionNotifier notifier,
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
              _sectionTitle('TIÊU CHÍ VẬN TỐC'),
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
            _inputField('Vận tốc tối đa', velSuffix, _maxVelController, (v) {
              final d = double.tryParse(v);
              if (d != null) notifier.onMaxVelocityChanged(d);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsSection(EqualFrictionState state) {
    final r = state.result!;
    final isRound = r.input.shape == DuctShape.round;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _sectionTitle('KẾT QUẢ'),
        const SizedBox(height: 12),

        // Hero card
        if (isRound && r.selectedRoundSize != null)
          _roundHeroCard(r)
        else if (!isRound && r.selectedRectangular != null)
          _rectHeroCard(r),

        const SizedBox(height: 16),

        // Summary
        _buildSummaryCard(r),

        // Candidates table
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(
              Icons.table_chart,
              color: AppColors.accentBright,
              size: 18,
            ),
            const SizedBox(width: 8),
            _sectionTitle('BẢNG SIZE ỨNG VIÊN'),
          ],
        ),
        const SizedBox(height: 12),
        isRound ? _buildRoundTable(r) : _buildRectangularTable(r),

        if (r.sizeWarning != null || r.velocityWarning != null) ...[
          const SizedBox(height: 16),
          _buildWarnings(r),
        ],
      ],
    );
  }

  Widget _roundHeroCard(EqualFrictionResult r) {
    final size = r.selectedRoundSize!;
    final candidate = r.roundCandidates.firstWhere(
      (c) => c.size == size,
      orElse: () => r.roundCandidates.first,
    );

    return Container(
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
            'SIZE TRÒN ĐỀ XUẤT',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ø ${size.diameterIn.toStringAsFixed(0)}"',
            style: GoogleFonts.firaCode(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${candidate.actualFrictionRateInWg100ft.toStringAsFixed(3)} in.wg/100ft',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _statBadge('Velocity', candidate.velocityFpm.toStringAsFixed(0)),
              _statBadge(
                'VP',
                candidate.velocityPressureInWg.toStringAsFixed(3),
              ),
              _statBadge(
                'ΔP total',
                (r.totalFrictionLossInWg).toStringAsFixed(3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rectHeroCard(EqualFrictionResult r) {
    final sel = r.selectedRectangular!;
    return Container(
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
            'SIZE CHỮ NHẬT ĐỀ XUẤT',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${sel.widthIn.toStringAsFixed(0)}" × ${sel.heightIn.toStringAsFixed(0)}"',
            style: GoogleFonts.firaCode(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'De = ${sel.equivalentDiameterIn.toStringAsFixed(1)}" · ${sel.actualFrictionRateInWg100ft.toStringAsFixed(3)} in.wg/100ft',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _statBadge('Velocity', sel.velocityFpm.toStringAsFixed(0)),
              _statBadge('VP', sel.velocityPressureInWg.toStringAsFixed(3)),
              _statBadge(
                'ΔP total',
                (r.totalFrictionLossInWg).toStringAsFixed(3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(EqualFrictionResult r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _detailRow(
            'Lưu lượng',
            '${r.airflowCfm.toStringAsFixed(0)} CFM · ${r.airflowM3h.toStringAsFixed(0)} m³/h',
          ),
          _detailRow(
            'Chiều dài ống',
            '${r.input.lengthFt.toStringAsFixed(0)} ft',
          ),
          _detailRow(
            'Friction rate mục tiêu',
            '${r.targetFrictionRateInWg100ft.toStringAsFixed(3)} in.wg/100ft',
          ),
          _detailRow(
            'Tổng ΔP friction',
            '${r.totalFrictionLossInWg.toStringAsFixed(3)} in.wg · ${r.totalFrictionLossPa.toStringAsFixed(1)} Pa',
          ),
        ],
      ),
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
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundTable(EqualFrictionResult r) {
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
                _tableHeader('Size', flex: 1),
                _tableHeader('V', flex: 2),
                _tableHeader('Friction', flex: 2),
                _tableHeader('Δ', flex: 1),
                _tableHeader('', flex: 1),
              ],
            ),
          ),
          ...r.roundCandidates.asMap().entries.map((entry) {
            final idx = entry.key;
            final c = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.isSelected
                    ? AppColors.accentPrimary.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: idx == r.roundCandidates.length - 1
                        ? Colors.transparent
                        : AppColors.divider.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Ø${c.size.diameterIn.toStringAsFixed(0)}"',
                      style: TextStyle(
                        color: c.isSelected
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
                      c.velocityFpm.toStringAsFixed(0),
                      style: TextStyle(
                        color: c.meetsVelocity == 1
                            ? Colors.white
                            : Colors.redAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      c.actualFrictionRateInWg100ft.toStringAsFixed(3),
                      style: TextStyle(
                        color: c.meetsFriction == 1
                            ? Colors.white
                            : Colors.amber,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: c.frictionDeviationPct != null
                        ? Text(
                            '${c.frictionDeviationPct!.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: c.frictionDeviationPct! > 50
                                  ? Colors.amber
                                  : AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Expanded(
                    flex: 1,
                    child: c.isSelected
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

  Widget _buildRectangularTable(EqualFrictionResult r) {
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
                _tableHeader('W×H', flex: 2),
                _tableHeader('V', flex: 2),
                _tableHeader('Friction', flex: 2),
                _tableHeader('Δ', flex: 1),
                _tableHeader('', flex: 1),
              ],
            ),
          ),
          // Limit to first 30 for display
          ...r.rectangularCandidates.take(30).toList().asMap().entries.map((
            entry,
          ) {
            final idx = entry.key;
            final c = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.isSelected
                    ? AppColors.accentPrimary.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: idx == r.rectangularCandidates.take(30).length - 1
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
                      '${c.widthIn.toStringAsFixed(0)}×${c.heightIn.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: c.isSelected
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
                      c.velocityFpm.toStringAsFixed(0),
                      style: TextStyle(
                        color: c.meetsVelocity
                            ? Colors.white
                            : Colors.redAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      c.actualFrictionRateInWg100ft.toStringAsFixed(3),
                      style: TextStyle(
                        color: c.meetsFriction ? Colors.white : Colors.amber,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: c.frictionDeviationPct != null
                        ? Text(
                            '${c.frictionDeviationPct!.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: c.frictionDeviationPct! > 50
                                  ? Colors.amber
                                  : AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Expanded(
                    flex: 1,
                    child: c.isSelected
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

  Widget _buildWarnings(EqualFrictionResult r) {
    return Column(
      children: [
        if (r.sizeWarning != null)
          _warningCard(r.sizeWarning!, Icons.error, Colors.red),
        if (r.velocityWarning != null)
          _warningCard(r.velocityWarning!, Icons.warning, Colors.amber),
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
            width: 120,
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
