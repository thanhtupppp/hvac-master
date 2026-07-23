import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/hvac/models/enums.dart';
import '../providers/vav_sizing_provider.dart';
import '../formulas/vav_box_engine.dart';
import '../data/vav_box_catalog.dart';

class VavBoxSizingScreen extends ConsumerStatefulWidget {
  const VavBoxSizingScreen({super.key});

  @override
  ConsumerState<VavBoxSizingScreen> createState() => _VavBoxSizingScreenState();
}

class _VavBoxSizingScreenState extends ConsumerState<VavBoxSizingScreen> {
  final _coolingLoadController = TextEditingController();
  final _heatingLoadController = TextEditingController();
  final _satController = TextEditingController();
  final _roomController = TextEditingController();
  final _roomHeatController = TextEditingController();
  final _primaryController = TextEditingController();
  final _airflowController = TextEditingController();
  double _minRatio = 0.30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllersFromState(ref.read(vavSizingProvider));
    });
  }

  @override
  void dispose() {
    _coolingLoadController.dispose();
    _heatingLoadController.dispose();
    _satController.dispose();
    _roomController.dispose();
    _roomHeatController.dispose();
    _primaryController.dispose();
    _airflowController.dispose();
    super.dispose();
  }

  void _syncControllersFromState(VavSizingState state) {
    final input = state.input;
    _coolingLoadController.text = input.coolingLoadBtuHr.toStringAsFixed(0);
    _heatingLoadController.text = input.heatingLoadBtuHr.toStringAsFixed(0);
    _satController.text = input.supplyAirTempF.toStringAsFixed(0);
    _roomController.text = input.roomTempF.toStringAsFixed(0);
    _roomHeatController.text = input.roomTempFHeat.toStringAsFixed(0);
    _primaryController.text = input.primaryAirTempF.toStringAsFixed(0);
    _airflowController.text = input.directAirflowCfm.toStringAsFixed(0);
    _minRatio = input.minAirflowRatio;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vavSizingProvider);
    final notifier = ref.read(vavSizingProvider.notifier);

    ref.listen<VavSizingState>(vavSizingProvider, (prev, next) {
      if (prev?.input.unit != next.input.unit) {
        _syncControllersFromState(next);
      }
    });

    final isMetric = state.input.unit == UnitSystem.metric;
    final tempSuffix = isMetric ? '°C' : '°F';
    final loadSuffix = isMetric ? 'W' : 'Btu/h';
    final airflowSuffix = isMetric ? 'm³/h' : 'CFM';

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
          'Sizing Hộp VAV',
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
          _buildMethodSection(state, notifier, loadSuffix, airflowSuffix),
          const SizedBox(height: 16),
          _buildLoadSection(state, notifier, loadSuffix, airflowSuffix),
          const SizedBox(height: 16),
          _buildTemperatureSection(state, notifier, tempSuffix, isMetric),
          const SizedBox(height: 16),
          _buildMinRatioSection(state, notifier),
          const SizedBox(height: 16),
          _buildBoxTypeSection(state, notifier),
          if (state.status == VavSizingStatus.success && state.result != null)
            _buildResultsSection(state),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(VavSizingState state, VavSizingNotifier notifier) {
    final isMetric = state.input.unit == UnitSystem.metric;

    return Row(
      children: [
        Expanded(
          child: _buildToggleButton(
            label: 'Metric (SI)',
            isSelected: isMetric,
            onTap: () => notifier.onUnitSystemChanged(UnitSystem.metric),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildToggleButton(
            label: 'Imperial (IP)',
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

  Widget _buildMethodSection(
    VavSizingState state,
    VavSizingNotifier notifier,
    String loadSuffix,
    String airflowSuffix,
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
          _sectionTitle('PHƯƠNG PHÁP TÍNH'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  label: 'Theo Tải Lạnh',
                  isSelected: state.input.method == SizingMethod.byCoolingLoad,
                  onTap: () =>
                      notifier.onMethodChanged(SizingMethod.byCoolingLoad),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildToggleButton(
                  label: 'Theo Lưu Lượng',
                  isSelected: state.input.method == SizingMethod.byAirflow,
                  onTap: () => notifier.onMethodChanged(SizingMethod.byAirflow),
                ),
              ),
            ],
          ),
          if (state.input.method == SizingMethod.byAirflow) ...[
            const SizedBox(height: 16),
            _buildInputField(
              label: 'Lưu lượng thiết kế',
              suffix: airflowSuffix,
              controller: _airflowController,
              onChanged: (v) {
                final d = double.tryParse(v);
                if (d != null) notifier.onDirectAirflowChanged(d);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadSection(
    VavSizingState state,
    VavSizingNotifier notifier,
    String loadSuffix,
    String airflowSuffix,
  ) {
    if (state.input.method == SizingMethod.byAirflow) {
      return const SizedBox();
    }
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
          _sectionTitle('TẢI NHIỆT'),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Tải lạnh',
            suffix: loadSuffix,
            controller: _coolingLoadController,
            onChanged: (v) {
              final d = double.tryParse(v);
              if (d != null) notifier.onCoolingLoadChanged(d);
            },
          ),
          const Divider(color: AppColors.divider),
          _buildInputField(
            label: 'Tải sưởi',
            suffix: loadSuffix,
            controller: _heatingLoadController,
            onChanged: (v) {
              final d = double.tryParse(v);
              if (d != null) notifier.onHeatingLoadChanged(d);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureSection(
    VavSizingState state,
    VavSizingNotifier notifier,
    String tempSuffix,
    bool isMetric,
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
          _sectionTitle('NHIỆT ĐỘ THIẾT KẾ'),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Nhiệt độ cấp (SAT)',
            suffix: tempSuffix,
            controller: _satController,
            onChanged: (v) {
              final d = double.tryParse(v);
              if (d != null) notifier.onSupplyAirTempChanged(d);
            },
          ),
          const Divider(color: AppColors.divider),
          _buildInputField(
            label: 'Nhiệt độ phòng (mùa lạnh)',
            suffix: tempSuffix,
            controller: _roomController,
            onChanged: (v) {
              final d = double.tryParse(v);
              if (d != null) notifier.onRoomTempChanged(d);
            },
          ),
          const Divider(color: AppColors.divider),
          _buildInputField(
            label: 'Nhiệt độ phòng (mùa sưởi)',
            suffix: tempSuffix,
            controller: _roomHeatController,
            onChanged: (v) {
              final d = double.tryParse(v);
              if (d != null) notifier.onRoomTempHeatChanged(d);
            },
          ),
          if (state.input.boxType != VavBoxType.singleDuctCoolingOnly &&
              state.input.boxType != VavBoxType.fanPowered &&
              state.input.boxType != VavBoxType.seriesFanPowered) ...[
            const Divider(color: AppColors.divider),
            _buildInputField(
              label: 'Nhiệt độ gió sơ cấp',
              suffix: tempSuffix,
              controller: _primaryController,
              onChanged: (v) {
                final d = double.tryParse(v);
                if (d != null) notifier.onPrimaryAirTempChanged(d);
              },
            ),
          ],
          const SizedBox(height: 12),
          _buildPsychrometricPreview(state.input, isMetric),
        ],
      ),
    );
  }

  Widget _buildPsychrometricPreview(VavBoxSizingInput input, bool isMetric) {
    final sat = input.supplyAirTempF;
    final room = input.roomTempF;
    final roomHeat = input.roomTempFHeat;
    final deltaCool = (room - sat).abs();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTempNode(
                'SAT',
                sat,
                tempSuffix: isMetric ? '°C' : '°F',
                color: Colors.cyan,
                icon: Icons.ac_unit,
              ),
              _buildTempNode(
                'Room',
                room,
                tempSuffix: isMetric ? '°C' : '°F',
                color: Colors.green,
                icon: Icons.home,
              ),
              _buildTempNode(
                'Room (H)',
                roomHeat,
                tempSuffix: isMetric ? '°C' : '°F',
                color: Colors.orange,
                icon: Icons.local_fire_department,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ΔT (cooling) = ${deltaCool.toStringAsFixed(1)}${isMetric ? '°C' : '°F'}',
            style: const TextStyle(
              color: AppColors.accentBright,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempNode(
    String label,
    double value, {
    required String tempSuffix,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
        Text(
          '${value.toStringAsFixed(0)}$tempSuffix',
          style: GoogleFonts.firaCode(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMinRatioSection(
    VavSizingState state,
    VavSizingNotifier notifier,
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
              _sectionTitle('LƯU LƯỢNG TỐI THIỂU'),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(_minRatio * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.accentBright,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _minRatio,
            min: 0.10,
            max: 0.50,
            divisions: 40,
            activeColor: AppColors.accentPrimary,
            inactiveColor: AppColors.divider,
            onChanged: (v) {
              setState(() => _minRatio = v);
              notifier.onMinAirflowRatioChanged(v);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '10%',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
              Text(
                '30% (typical)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
              Text(
                '50% (max)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoxTypeSection(
    VavSizingState state,
    VavSizingNotifier notifier,
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
          _sectionTitle('LOẠI HỘP VAV'),
          const SizedBox(height: 12),
          ...VavBoxCatalog.definitions.map((def) {
            final selected = state.input.boxType == def.type;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => notifier.onBoxTypeChanged(def.type),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accentPrimary.withValues(alpha: 0.18)
                        : AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.accentPrimary
                          : AppColors.divider,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        def.icon,
                        color: selected
                            ? AppColors.accentBright
                            : AppColors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    def.displayName,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (def.hasReheat) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'REHEAT',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              def.application,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.accentBright,
                          size: 20,
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

  Widget _buildResultsSection(VavSizingState state) {
    final r = state.result!;
    final isMetric = state.input.unit == UnitSystem.metric;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _sectionTitle('KẾT QUẢ'),
        const SizedBox(height: 12),

        // Hero — Recommended size
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
                  'Ø ${r.selectedSize!.inletDiameterIn.toStringAsFixed(0)}"',
                  style: GoogleFonts.firaCode(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '(${r.boxDefinition.displayName})',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentBright.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Max: ${r.selectedSize!.maxCfm.toStringAsFixed(0)} CFM · Min: ${r.selectedSize!.minCfm.toStringAsFixed(0)} CFM',
                    style: const TextStyle(
                      color: AppColors.accentBright,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Operating range visualization
        Row(
          children: [
            const Icon(
              Icons.show_chart,
              color: AppColors.accentBright,
              size: 18,
            ),
            const SizedBox(width: 8),
            _sectionTitle('VÙNG VẬN HÀNH'),
          ],
        ),
        const SizedBox(height: 12),
        _buildOperatingRange(r, isMetric),

        const SizedBox(height: 20),

        // Cooling & heating summary
        Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.accentBright,
              size: 18,
            ),
            const SizedBox(width: 8),
            _sectionTitle('CHI TIẾT LƯU LƯỢNG'),
          ],
        ),
        const SizedBox(height: 12),
        _buildFlowDetails(r, isMetric),

        // Reheat capacity (if applicable)
        if (r.boxDefinition.hasReheat) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.whatshot, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              _sectionTitle('CÔNG SUẤT REHEAT'),
            ],
          ),
          const SizedBox(height: 12),
          _buildReheatDetails(r, isMetric),
        ],

        // Warnings
        if (r.sizeWarning != null || r.heatingWarning != null) ...[
          const SizedBox(height: 16),
          _buildWarnings(r),
        ],
      ],
    );
  }

  Widget _buildOperatingRange(VavBoxSizingResult r, bool isMetric) {
    final maxC = r.maxCfm;
    final minC = r.minCfm;
    final coolingC = r.coolingCfm;
    final heatingC = r.heatingCfm;
    final sizeMax = r.selectedSize?.maxCfm ?? maxC;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Operating Range',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                'Turndown: ${(r.turndownRatio * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.accentBright,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Visual range bar
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Background — selected size capacity
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Active operating region (min → max)
              FractionallySizedBox(
                widthFactor: maxC / sizeMax,
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentBright.withValues(alpha: 0.4),
                        AppColors.accentPrimary.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              // Min line marker
              Positioned(
                left:
                    (minC / sizeMax) *
                        (MediaQuery.of(context).size.width - 72) -
                    4,
                top: -4,
                bottom: -4,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              // Cooling target marker
              if (coolingC > 0)
                Positioned(
                  left:
                      (coolingC / sizeMax) *
                          (MediaQuery.of(context).size.width - 72) -
                      6,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'C ${coolingC.toStringAsFixed(0)}',
                      style: GoogleFonts.firaCode(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _legendDot('Cooling', Colors.cyan),
              if (heatingC > 0) _legendDot('Heating', Colors.orange),
              _legendDot('Min CFM', Colors.amber),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Max CFM',
            '${maxC.toStringAsFixed(0)} CFM · ${(maxC / 2118.88 * 3600).toStringAsFixed(0)} m³/h',
          ),
          _buildDetailRow(
            'Min CFM',
            '${minC.toStringAsFixed(0)} CFM · ${(minC / 2118.88 * 3600).toStringAsFixed(0)} m³/h',
          ),
          _buildDetailRow(
            'Size Capacity',
            '${sizeMax.toStringAsFixed(0)} CFM (max ${r.selectedSize?.inletDiameterIn ?? "?"}")',
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildFlowDetails(VavBoxSizingResult r, bool isMetric) {
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
            'Cooling CFM',
            '${r.coolingCfm.toStringAsFixed(0)} CFM · ${r.coolingM3h.toStringAsFixed(0)} m³/h',
          ),
          if (r.heatingCfm > 0)
            _buildDetailRow(
              'Heating CFM',
              '${r.heatingCfm.toStringAsFixed(0)} CFM · ${(r.heatingCfm / 2118.88 * 3600).toStringAsFixed(0)} m³/h',
            ),
          _buildDetailRow(
            'Design ΔT (cooling)',
            '${r.designDeltaTF.toStringAsFixed(1)}°F · ${r.designDeltaTK.toStringAsFixed(1)}°C',
          ),
          _buildDetailRow(
            'ΔT Ratio (C/H)',
            r.heatingCfm > 0
                ? (r.coolingCfm / r.heatingCfm).toStringAsFixed(2)
                : '—',
          ),
        ],
      ),
    );
  }

  Widget _buildReheatDetails(VavBoxSizingResult r, bool isMetric) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            'Reheating CFM',
            '${r.reheatingCfm.toStringAsFixed(0)} CFM',
          ),
          _buildDetailRow(
            'Reheat ΔT',
            '${r.reheatingDeltaTF.toStringAsFixed(1)}°F',
          ),
          _buildDetailRow(
            'Reheat Capacity',
            '${r.reheatCapacityBtuHr.toStringAsFixed(0)} Btu/h · ${r.reheatCapacityW.toStringAsFixed(0)} W',
          ),
        ],
      ),
    );
  }

  Widget _buildWarnings(VavBoxSizingResult r) {
    return Column(
      children: [
        if (r.sizeWarning != null)
          _buildWarningCard(
            r.sizeWarning!,
            r.isOversized ? Icons.error : Icons.info,
            r.isOversized ? Colors.red : Colors.amber,
          ),
        if (r.heatingWarning != null)
          _buildWarningCard(
            r.heatingWarning!,
            Icons.warning_amber,
            Colors.orange,
          ),
      ],
    );
  }

  Widget _buildWarningCard(String text, IconData icon, Color color) {
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
