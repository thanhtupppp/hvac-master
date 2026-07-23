import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/hvac/models/enums.dart';
import '../providers/fan_selection_provider.dart';
import '../formulas/fan_selection_engine.dart';

class FanSelectionScreen extends ConsumerStatefulWidget {
  const FanSelectionScreen({super.key});

  @override
  ConsumerState<FanSelectionScreen> createState() => _FanSelectionScreenState();
}

class _FanSelectionScreenState extends ConsumerState<FanSelectionScreen> {
  final _flowController = TextEditingController();
  final _pressureController = TextEditingController();
  final _altitudeController = TextEditingController();
  final _motorEffController = TextEditingController();
  final _safetyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllersFromState(ref.read(fanSelectionProvider));
    });
  }

  @override
  void dispose() {
    _flowController.dispose();
    _pressureController.dispose();
    _altitudeController.dispose();
    _motorEffController.dispose();
    _safetyController.dispose();
    super.dispose();
  }

  void _syncControllersFromState(FanSelectionState state) {
    final input = state.input;
    _flowController.text = input.flowRate.toStringAsFixed(0);
    _pressureController.text = input.staticPressure.toStringAsFixed(2);
    _altitudeController.text = input.altitude.toStringAsFixed(0);
    _motorEffController.text = (input.motorEfficiency * 100).toStringAsFixed(0);
    _safetyController.text = input.safetyFactor.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fanSelectionProvider);
    final notifier = ref.read(fanSelectionProvider.notifier);

    ref.listen<FanSelectionState>(fanSelectionProvider, (prev, next) {
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
          'Chọn Quạt & Motor',
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
          _buildOperatingPointSection(state, notifier),
          const SizedBox(height: 16),
          _buildFanConfigSection(state, notifier),
          const SizedBox(height: 16),
          _buildAdvancedSection(state, notifier),
          if (state.status == FanSelectionStatus.success &&
              state.result != null)
            _buildResultsSection(state),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(
    FanSelectionState state,
    FanSelectionNotifier notifier,
  ) {
    final isMetric = state.input.unit == UnitSystem.metric;

    return Row(
      children: [
        Expanded(
          child: _buildToggleButton(
            label: 'Metric (Pa)',
            isSelected: isMetric,
            onTap: () => notifier.onUnitSystemChanged(UnitSystem.metric),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildToggleButton(
            label: 'Imperial (in.wg)',
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

  Widget _buildOperatingPointSection(
    FanSelectionState state,
    FanSelectionNotifier notifier,
  ) {
    final isMetric = state.input.unit == UnitSystem.metric;

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
              _sectionTitle('ĐIỂM VẬN HÀNH'),
              const Icon(
                Icons.flash_on,
                color: AppColors.accentBright,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Lưu lượng',
            suffix: isMetric ? 'm³/h' : 'CFM',
            controller: _flowController,
            onChanged: (v) {
              final d = double.tryParse(v);
              if (d != null) notifier.onFlowRateChanged(d);
            },
          ),
          const Divider(color: AppColors.divider),
          _buildInputField(
            label: 'Cột áp tĩnh',
            suffix: isMetric ? 'Pa' : 'in.wg',
            controller: _pressureController,
            onChanged: (v) {
              final d = double.tryParse(v);
              if (d != null) notifier.onStaticPressureChanged(d);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFanConfigSection(
    FanSelectionState state,
    FanSelectionNotifier notifier,
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
          _sectionTitle('CẤU HÌNH QUẠT'),
          const SizedBox(height: 16),

          // Fan type grid
          _sectionSubtitle('Loại quạt'),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.4,
            children: FanType.values.map((type) {
              final selected = state.input.fanType == type;
              return _buildFanTypeCard(type, selected, () {
                notifier.onFanTypeChanged(type);
              });
            }).toList(),
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 8),

          // Drive type
          _sectionSubtitle('Truyền động'),
          const SizedBox(height: 8),
          Row(
            children: DriveType.values.map((type) {
              final selected = state.input.driveType == type;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: type == DriveType.values.last ? 0 : 8,
                  ),
                  child: _buildSmallToggle(
                    label: type == DriveType.belt ? 'Dây đai' : 'Trực tiếp',
                    isSelected: selected,
                    onTap: () => notifier.onDriveTypeChanged(type),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFanTypeCard(FanType type, bool selected, VoidCallback onTap) {
    final maxEff = FanSelectionEngine.getMaxEfficiency(type);
    String label;
    IconData icon;
    switch (type) {
      case FanType.centrifugalForward:
        label = 'Centrifugal\nForward Curved';
        icon = Icons.rotate_right;
        break;
      case FanType.centrifugalBackward:
        label = 'Centrifugal\nBackward Inclined';
        icon = Icons.refresh;
        break;
      case FanType.axial:
        label = 'Axial\n(Tube)';
        icon = Icons.swap_horiz;
        break;
      case FanType.vaneAxial:
        label = 'Vane Axial';
        icon = Icons.air;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentPrimary.withValues(alpha: 0.25)
              : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accentPrimary : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? AppColors.accentBright
                      : AppColors.textMuted,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentBright.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(maxEff * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.accentBright,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallToggle({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPrimary : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedSection(
    FanSelectionState state,
    FanSelectionNotifier notifier,
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
              _sectionTitle('THÔNG SỐ NÂNG CAO'),
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
            _buildInputField(
              label: 'Độ cao so mực nước biển',
              suffix: 'm',
              controller: _altitudeController,
              onChanged: (v) {
                final d = double.tryParse(v);
                if (d != null) notifier.onAltitudeChanged(d);
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Mật độ không khí ước tính: ${state.input.density.toStringAsFixed(3)} kg/m³',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            const Divider(color: AppColors.divider),
            _buildInputField(
              label: 'Hiệu suất motor',
              suffix: '%',
              controller: _motorEffController,
              onChanged: (v) {
                final d = double.tryParse(v);
                if (d != null) notifier.onMotorEfficiencyChanged(d / 100);
              },
            ),
            const Divider(color: AppColors.divider),
            _buildInputField(
              label: 'Hệ số an toàn',
              suffix: '×',
              controller: _safetyController,
              onChanged: (v) {
                final d = double.tryParse(v);
                if (d != null) notifier.onSafetyFactorChanged(d);
              },
            ),
          ],
        ],
      ),
    );
  }

  bool _advancedExpanded = false;

  Widget _buildResultsSection(FanSelectionState state) {
    final r = state.result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _sectionTitle('KẾT QUẢ'),
        const SizedBox(height: 12),

        // Hero — Recommended motor
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.electric_bolt,
                    color: AppColors.accentBright,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'MOTOR KHUYẾN NGHỊ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${r.recommendedMotorHp} HP',
                style: GoogleFonts.firaCode(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '(${r.recommendedMotorKw} kW)',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${r.fanTypeName} · ${r.driveTypeName}',
                  style: const TextStyle(
                    color: AppColors.accentBright,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildPressureClassBadge(r.pressureClass),
            ],
          ),
        ),

        const SizedBox(height: 20),
        // Power cascade
        Row(
          children: [
            const Icon(
              Icons.analytics,
              color: AppColors.accentBright,
              size: 18,
            ),
            const SizedBox(width: 8),
            _sectionTitle('CÔNG SUẤT THEO TẦNG'),
          ],
        ),
        const SizedBox(height: 12),
        _buildPowerCascade(r),

        const SizedBox(height: 20),
        // Operating point info
        Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.accentBright,
              size: 18,
            ),
            const SizedBox(width: 8),
            _sectionTitle('CHI TIẾT ĐIỂM VẬN HÀNH'),
          ],
        ),
        const SizedBox(height: 12),
        _buildOperatingPointDetails(r),

        // Warnings
        if (r.efficiencyWarning != null ||
            r.altitudeWarning != null ||
            r.motorSizeWarning != null) ...[
          const SizedBox(height: 16),
          _buildWarnings(r),
        ],
      ],
    );
  }

  Widget _buildPressureClassBadge(PressureClass pc) {
    final color = pc == PressureClass.low
        ? Colors.green
        : pc == PressureClass.medium
        ? Colors.orange
        : Colors.red;
    final label = pc == PressureClass.low
        ? 'Áp suất thấp (<500 Pa)'
        : pc == PressureClass.medium
        ? 'Áp suất trung bình (500-1500 Pa)'
        : 'Áp suất cao (>1500 Pa)';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPowerCascade(FanOperatingPoint r) {
    final maxHp = r.motorPowerHp;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _buildCascadeBar(
            label: 'AIR POWER',
            desc: 'Công suất khí lý thuyết',
            hp: r.airPowerHp,
            maxHp: maxHp,
            color: Colors.cyan,
          ),
          const SizedBox(height: 8),
          _buildCascadeBar(
            label: 'SHAFT POWER',
            desc: 'η_quạt = ${(r.fanEfficiency * 100).toStringAsFixed(0)}%',
            hp: r.shaftPowerHp,
            maxHp: maxHp,
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildCascadeBar(
            label: 'BRAKE POWER',
            desc: 'Truyền động (drive loss)',
            hp: r.brakePowerHp,
            maxHp: maxHp,
            color: Colors.purple,
          ),
          const SizedBox(height: 8),
          _buildCascadeBar(
            label: 'MOTOR INPUT',
            desc: 'η_motor = ${(r.motorEfficiency * 100).toStringAsFixed(0)}%',
            hp: r.motorPowerHp,
            maxHp: maxHp,
            color: Colors.deepOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildCascadeBar({
    required String label,
    required String desc,
    required double hp,
    required double maxHp,
    required Color color,
  }) {
    final fraction = maxHp > 0 ? hp / maxHp : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.6), color],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${hp.toStringAsFixed(2)} HP',
                    style: GoogleFonts.firaCode(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperatingPointDetails(FanOperatingPoint r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            'Lưu lượng',
            '${r.flowCfm.toStringAsFixed(0)} CFM · ${r.flowM3h.toStringAsFixed(0)} m³/h',
          ),
          _buildDetailRow(
            'Cột áp (đầu vào)',
            '${r.staticPressureInWg.toStringAsFixed(3)} in.wg · ${r.staticPressurePa.toStringAsFixed(0)} Pa',
          ),
          _buildDetailRow(
            'Cột áp (sau hiệu chỉnh)',
            '${r.densityCorrectedInWg.toStringAsFixed(3)} in.wg · ${r.densityCorrectedPa.toStringAsFixed(0)} Pa',
          ),
          _buildDetailRow(
            'Brake Power',
            '${r.brakePowerHp.toStringAsFixed(2)} HP · ${r.brakePowerKw.toStringAsFixed(2)} kW',
          ),
          _buildDetailRow(
            'Motor (đầu vào)',
            '${r.motorPowerHp.toStringAsFixed(2)} HP · ${r.motorPowerKw.toStringAsFixed(2)} kW',
          ),
          _buildDetailRow(
            'Hiệu suất quạt',
            '${(r.fanEfficiency * 100).toStringAsFixed(1)}%',
          ),
          _buildDetailRow(
            'Hiệu suất motor',
            '${(r.motorEfficiency * 100).toStringAsFixed(1)}%',
          ),
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

  Widget _buildWarnings(FanOperatingPoint r) {
    return Column(
      children: [
        if (r.altitudeWarning != null)
          _buildWarning(r.altitudeWarning!, Icons.terrain, Colors.amber),
        if (r.efficiencyWarning != null)
          _buildWarning(r.efficiencyWarning!, Icons.eco, Colors.cyan),
        if (r.motorSizeWarning != null)
          _buildWarning(
            r.motorSizeWarning!,
            Icons.warning_amber,
            Colors.orange,
          ),
      ],
    );
  }

  Widget _buildWarning(String text, IconData icon, Color color) {
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

  Widget _sectionSubtitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
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
}
