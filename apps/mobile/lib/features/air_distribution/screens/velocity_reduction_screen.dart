import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/hvac/models/enums.dart';
import '../constants/air_distribution_constants.dart';
import '../providers/velocity_reduction_provider.dart';
import '../formulas/velocity_reduction_engine.dart';

class VelocityReductionScreen extends ConsumerStatefulWidget {
  const VelocityReductionScreen({super.key});

  @override
  ConsumerState<VelocityReductionScreen> createState() =>
      _VelocityReductionScreenState();
}

class _VelocityReductionScreenState
    extends ConsumerState<VelocityReductionScreen> {
  final _airflowController = TextEditingController();
  final _velocityController = TextEditingController();
  final _lengthController = TextEditingController();
  final _maxFrictionController = TextEditingController();
  int _numberOfSections = 4;
  double _reductionRatio = 0.8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllersFromState(ref.read(velocityReductionProvider));
    });
  }

  @override
  void dispose() {
    _airflowController.dispose();
    _velocityController.dispose();
    _lengthController.dispose();
    _maxFrictionController.dispose();
    super.dispose();
  }

  void _syncControllersFromState(VelocityReductionState state) {
    final i = state.input;
    _airflowController.text = i.airflowCfm.toStringAsFixed(0);
    _velocityController.text = i.initialVelocityFpm.toStringAsFixed(0);
    _lengthController.text = i.lengthFt.toStringAsFixed(0);
    _maxFrictionController.text = i.maxFrictionRateInWg100ft.toStringAsFixed(2);
    _numberOfSections = i.numberOfSections;
    _reductionRatio = i.reductionRatio;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(velocityReductionProvider);
    final notifier = ref.read(velocityReductionProvider.notifier);

    ref.listen<VelocityReductionState>(velocityReductionProvider, (prev, next) {
      if (prev?.input.unit != next.input.unit) {
        _syncControllersFromState(next);
      }
    });

    final isMetric = state.input.unit == UnitSystem.metric;
    final volSuffix = isMetric ? 'm³/h' : 'CFM';
    final lenSuffix = isMetric ? 'm' : 'ft';
    final velSuffix = isMetric ? 'm/s' : 'FPM';
    final fricSuffix = isMetric ? 'Pa/m' : 'in.wg/100ft';

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
          'Velocity Reduction Sizing',
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
          _buildAirflowSection(
            state,
            notifier,
            volSuffix,
            velSuffix,
            lenSuffix,
          ),
          const SizedBox(height: 16),
          _buildSectionsSection(state, notifier),
          const SizedBox(height: 16),
          _buildMaterialSection(state, notifier),
          const SizedBox(height: 16),
          _buildLimitSection(state, notifier, fricSuffix),
          if (state.status == VelocityReductionStatus.success &&
              state.result != null)
            _buildResultsSection(state),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(
    VelocityReductionState state,
    VelocityReductionNotifier notifier,
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
    VelocityReductionState state,
    VelocityReductionNotifier notifier,
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
    VelocityReductionState state,
    VelocityReductionNotifier notifier,
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
    VelocityReductionState state,
    VelocityReductionNotifier notifier,
    String volSuffix,
    String velSuffix,
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
          _sectionTitle('LƯU LƯỢNG & VẬN TỐC'),
          const SizedBox(height: 16),
          _inputField('Lưu lượng đầu vào', volSuffix, _airflowController, (v) {
            final d = double.tryParse(v);
            if (d != null) notifier.onAirflowChanged(d);
          }),
          const Divider(color: AppColors.divider),
          _inputField('Vận tốc khởi đầu', velSuffix, _velocityController, (v) {
            final d = double.tryParse(v);
            if (d != null) notifier.onInitialVelocityChanged(d);
          }),
          const Divider(color: AppColors.divider),
          _inputField('Chiều dài mỗi section', lenSuffix, _lengthController, (
            v,
          ) {
            final d = double.tryParse(v);
            if (d != null) notifier.onLengthChanged(d);
          }),
        ],
      ),
    );
  }

  Widget _buildSectionsSection(
    VelocityReductionState state,
    VelocityReductionNotifier notifier,
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
          _sectionTitle('SỐ SECTION & REDUCTION RATIO'),
          const SizedBox(height: 16),
          // Number of sections stepper
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Số section (nhánh)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              _stepper(
                _numberOfSections.toString(),
                () {
                  if (_numberOfSections > 1) {
                    setState(() => _numberOfSections--);
                    notifier.onNumberOfSectionsChanged(_numberOfSections);
                  }
                },
                () {
                  if (_numberOfSections < 10) {
                    setState(() => _numberOfSections++);
                    notifier.onNumberOfSectionsChanged(_numberOfSections);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Reduction ratio slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reduction ratio',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentBright.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(_reductionRatio * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.firaCode(
                    color: AppColors.accentBright,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _reductionRatio,
            min: 0.3,
            max: 0.95,
            divisions: 65,
            activeColor: AppColors.accentPrimary,
            inactiveColor: AppColors.divider,
            onChanged: (v) {
              setState(() => _reductionRatio = v);
              notifier.onReductionRatioChanged(v);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Aggressive\n(30%)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 9),
                ),
                Text(
                  'Typical\n(70%)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.accentBright,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Mild\n(95%)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ratioExplanation(_reductionRatio),
        ],
      ),
    );
  }

  Widget _ratioExplanation(double ratio) {
    String explanation;
    Color color;
    if (ratio < 0.6) {
      explanation =
          'Reduction aggressive → velocity giảm nhanh, nhiều section, kích thước đồng đều hơn. Tiết kiệm năng lượng nhưng nhiều transitions.';
      color = Colors.cyan;
    } else if (ratio < 0.85) {
      explanation =
          'Reduction typical → cân bằng giữa kích thước ống, chi phí và hiệu suất. Khuyến nghị cho hầu hết hệ thống.';
      color = Colors.green;
    } else {
      explanation =
          'Reduction nhẹ → size các nhánh gần nhau, ít transitions. Phù hợp hệ thống ngắn.';
      color = Colors.amber;
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
    VelocityReductionState state,
    VelocityReductionNotifier notifier,
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

  Widget _buildLimitSection(
    VelocityReductionState state,
    VelocityReductionNotifier notifier,
    String fricSuffix,
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
          _sectionTitle('GIỚI HẠN FRICTION'),
          const SizedBox(height: 16),
          _inputField(
            'Friction rate tối đa',
            fricSuffix,
            _maxFrictionController,
            (v) {
              final d = double.tryParse(v);
              if (d != null) notifier.onMaxFrictionChanged(d);
            },
          ),
        ],
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

  Widget _buildResultsSection(VelocityReductionState state) {
    final r = state.result!;
    final isRound = r.input.shape == DuctShape.round;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _sectionTitle('KẾT QUẢ — PROFILE THEO SECTION'),
        const SizedBox(height: 12),

        // Hero card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D1B4E), Color(0xFF3A2260)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accentPrimary.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _heroStat(
                    r.input.initialVelocityFpm.toStringAsFixed(0),
                    'V khởi đầu\nFPM',
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: AppColors.accentBright,
                    size: 24,
                  ),
                  _heroStat(
                    r.finalVelocityFpm.toStringAsFixed(0),
                    'V cuối\nFPM',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _heroStat('${r.sections.length}', 'Số\nsection'),
                  _heroStat(
                    '${r.totalReductionPct.toStringAsFixed(0)}%',
                    'Tổng\ngiảm',
                  ),
                  _heroStat(
                    r.totalFrictionLossInWg.toStringAsFixed(2),
                    'ΔP tổng\nin.wg',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Velocity profile visualization
        _buildVelocityProfile(r),

        const SizedBox(height: 16),
        // Per-section cards
        _sectionTitle('CHI TIẾT TỪNG SECTION'),
        const SizedBox(height: 12),
        ...r.sections.asMap().entries.map((entry) {
          final idx = entry.key;
          final s = entry.value;
          return _buildSectionCard(idx, s, isRound);
        }),

        if (r.warning != null) ...[
          const SizedBox(height: 16),
          _warningCard(r.warning!, Icons.warning, Colors.amber),
        ],
      ],
    );
  }

  Widget _heroStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.firaCode(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildVelocityProfile(VelocityReductionResult r) {
    if (r.sections.isEmpty) return const SizedBox.shrink();
    final maxVel = r.input.initialVelocityFpm;

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
          Row(
            children: [
              const Icon(
                Icons.show_chart,
                color: AppColors.accentBright,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'VELOCITY PROFILE',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: r.sections.map((s) {
                final ratio = s.velocityFpm / maxVel;
                final heightPx = (ratio * 100).clamp(10.0, 110.0);
                final isLast = s.sectionIndex == r.sections.length - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          s.velocityFpm.toStringAsFixed(0),
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: heightPx,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isLast
                                  ? [
                                      Colors.green.shade400,
                                      Colors.green.shade700,
                                    ]
                                  : [
                                      AppColors.accentBright,
                                      AppColors.accentPrimary,
                                    ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${s.sectionIndex + 1}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mỗi cột = 1 section. Cao = velocity cao. Gradient cam→xanh = section trước→sau.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(int idx, VelocitySectionResult s, bool isRound) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: idx == 0
              ? AppColors.accentBright.withValues(alpha: 0.4)
              : AppColors.divider,
          width: idx == 0 ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: idx == 0
                      ? AppColors.accentBright
                      : AppColors.accentPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${idx + 1}',
                  style: GoogleFonts.firaCode(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isRound
                          ? 'Ø${s.roundDiameterIn?.toStringAsFixed(0)}" · ${s.airflowCfm.toStringAsFixed(0)} CFM'
                          : '${s.rectWidthIn?.toStringAsFixed(0)}×${s.rectHeightIn?.toStringAsFixed(0)}" · ${s.airflowCfm.toStringAsFixed(0)} CFM',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (s.reductionPct > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-${s.reductionPct.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat('Velocity', s.velocityFpm.toStringAsFixed(0)),
              _miniStat('VP', s.velocityPressureInWg.toStringAsFixed(3)),
              _miniStat('Friction', s.frictionRateInWg100ft.toStringAsFixed(3)),
              _miniStat('ΔP', s.frictionLossInWg.toStringAsFixed(2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.firaCode(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _warningCard(String text, IconData icon, Color color) {
    return Container(
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
