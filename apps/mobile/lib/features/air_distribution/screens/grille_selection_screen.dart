import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/hvac/models/enums.dart';
import '../providers/grille_selection_provider.dart';
import '../formulas/grille_selection_engine.dart';

class GrilleSelectionScreen extends ConsumerStatefulWidget {
  const GrilleSelectionScreen({super.key});

  @override
  ConsumerState<GrilleSelectionScreen> createState() =>
      _GrilleSelectionScreenState();
}

class _GrilleSelectionScreenState extends ConsumerState<GrilleSelectionScreen> {
  final _cfmController = TextEditingController();
  final _areaController = TextEditingController();
  final _ceilingController = TextEditingController();
  final _achController = TextEditingController();
  int _grilleCount = 2;
  bool _byRoomArea = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllersFromState(ref.read(grilleSelectionProvider));
    });
  }

  @override
  void dispose() {
    _cfmController.dispose();
    _areaController.dispose();
    _ceilingController.dispose();
    _achController.dispose();
    super.dispose();
  }

  void _syncControllersFromState(GrilleSelectionState state) {
    final i = state.input;
    _cfmController.text = i.totalCfm.toStringAsFixed(0);
    _areaController.text = i.roomAreaSqFt.toStringAsFixed(0);
    _ceilingController.text = i.ceilingHeightFt.toStringAsFixed(0);
    _achController.text = i.ach.toStringAsFixed(1);
    _grilleCount = i.grilleCount;
    _byRoomArea = i.byRoomArea;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(grilleSelectionProvider);
    final notifier = ref.read(grilleSelectionProvider.notifier);

    ref.listen<GrilleSelectionState>(grilleSelectionProvider, (prev, next) {
      if (prev?.input.unit != next.input.unit ||
          prev?.input.byRoomArea != next.input.byRoomArea) {
        _syncControllersFromState(next);
      }
    });

    final isMetric = state.input.unit == UnitSystem.metric;
    final lengthSuffix = isMetric ? 'm' : 'ft';
    final areaSuffix = isMetric ? 'm²' : 'sqft';
    final volSuffix = isMetric ? 'm³/h' : 'CFM';

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
          'Chọn Cửa Gió Hồi/Xả',
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
          _buildApplicationSection(state, notifier),
          const SizedBox(height: 16),
          _buildInputSection(
            state,
            notifier,
            volSuffix,
            areaSuffix,
            lengthSuffix,
          ),
          const SizedBox(height: 16),
          _buildGrilleTypeSection(state, notifier),
          const SizedBox(height: 16),
          _buildCriteriaSection(state, notifier),
          if (state.status == GrilleSelectionStatus.success &&
              state.result != null)
            _buildResultsSection(state),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(
    GrilleSelectionState state,
    GrilleSelectionNotifier notifier,
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

  Widget _buildApplicationSection(
    GrilleSelectionState state,
    GrilleSelectionNotifier notifier,
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
          _sectionTitle('ỨNG DỤNG'),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.6,
            children: GrilleApplication.values.map((app) {
              final selected = state.input.application == app;
              return _buildAppCard(app, selected, () {
                notifier.onApplicationChanged(app);
              });
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(
    GrilleApplication app,
    bool selected,
    VoidCallback onTap,
  ) {
    String label;
    IconData icon;
    Color color;
    switch (app) {
      case GrilleApplication.returnAir:
        label = 'Hồi gió\n(Return)';
        icon = Icons.wind_power;
        color = Colors.blue;
        break;
      case GrilleApplication.exhaustAir:
        label = 'Xả\n(Exhaust)';
        icon = Icons.outbond;
        color = Colors.grey;
        break;
      case GrilleApplication.transferAir:
        label = 'Chuyển phòng\n(Transfer)';
        icon = Icons.swap_horiz;
        color = Colors.purple;
        break;
      case GrilleApplication.supplyAirWall:
        label = 'Cấp gió tường\n(Wall Supply)';
        icon = Icons.air;
        color = Colors.teal;
        break;
    }
    final maxFace = GrilleSelectionEngine.getDefaultFaceVelocity(app);

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
                  size: 16,
                  color: selected
                      ? AppColors.accentBright
                      : color.withValues(alpha: 0.7),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$maxFace fpm',
                    style: TextStyle(
                      color: color,
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

  Widget _buildInputSection(
    GrilleSelectionState state,
    GrilleSelectionNotifier notifier,
    String volSuffix,
    String areaSuffix,
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
          _sectionTitle('THÔNG SỐ ĐẦU VÀO'),
          const SizedBox(height: 12),
          // Method toggle
          Row(
            children: [
              Expanded(
                child: _toggleButton('Theo CFM', !_byRoomArea, () {
                  setState(() => _byRoomArea = false);
                  notifier.onByRoomAreaChanged(false);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _toggleButton('Theo Phòng', _byRoomArea, () {
                  setState(() => _byRoomArea = true);
                  notifier.onByRoomAreaChanged(true);
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_byRoomArea) ...[
            _inputField('Diện tích phòng', areaSuffix, _areaController, (v) {
              final d = double.tryParse(v);
              if (d != null) notifier.onRoomAreaChanged(d);
            }),
            const Divider(color: AppColors.divider),
            _inputField('Chiều cao trần', lengthSuffix, _ceilingController, (
              v,
            ) {
              final d = double.tryParse(v);
              if (d != null) notifier.onCeilingHeightChanged(d);
            }),
            const Divider(color: AppColors.divider),
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
          ] else
            _inputField('Tổng lưu lượng', volSuffix, _cfmController, (v) {
              final d = double.tryParse(v);
              if (d != null) notifier.onTotalCfmChanged(d);
            }),

          const Divider(color: AppColors.divider),
          // Grille count stepper
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Số lượng grille',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              _stepper(
                _grilleCount.toString(),
                () {
                  if (_grilleCount > 1) {
                    setState(() => _grilleCount--);
                    notifier.onGrilleCountChanged(_grilleCount);
                  }
                },
                () {
                  setState(() => _grilleCount++);
                  notifier.onGrilleCountChanged(_grilleCount);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrilleTypeSection(
    GrilleSelectionState state,
    GrilleSelectionNotifier notifier,
  ) {
    // Map GrilleType → DiffuserDefinition for display
    final types = GrilleType.values;
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
          _sectionTitle('LOẠI GRILLE'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: types.map((type) {
              final selected = state.input.grilleType == type;
              return GestureDetector(
                onTap: () => notifier.onGrilleTypeChanged(type),
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
                    _grilleLabel(type),
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
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

  String _grilleLabel(GrilleType type) {
    switch (type) {
      case GrilleType.returnGrille:
        return 'Miệng gió hồi';
      case GrilleType.eggCrate:
        return 'Lưới trứng (Egg Crate)';
      case GrilleType.linearBar:
        return 'Thanh khe';
      case GrilleType.supplyRegister:
        return 'Register (tường)';
    }
  }

  bool _criteriaExpanded = false;

  Widget _buildCriteriaSection(
    GrilleSelectionState state,
    GrilleSelectionNotifier notifier,
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
                  _criteriaExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textMuted,
                ),
                onPressed: () =>
                    setState(() => _criteriaExpanded = !_criteriaExpanded),
              ),
            ],
          ),
          if (_criteriaExpanded) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Vận tốc mặt tối đa',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: _inputField('', 'FPM', null, (v) {
                    final d = double.tryParse(v);
                    if (d != null) notifier.onMaxFaceVelocityChanged(d);
                  }, inline: true),
                ),
              ],
            ),
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

  Widget _ncSlider(double value, GrilleSelectionNotifier notifier) {
    return SizedBox(
      width: 120,
      child: Slider(
        value: value,
        min: 15,
        max: 45,
        divisions: 30,
        activeColor: AppColors.accentPrimary,
        inactiveColor: AppColors.divider,
        label: 'NC ${value.toStringAsFixed(0)}',
        onChanged: (v) => notifier.onMaxNcChanged(v),
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

  Widget _buildResultsSection(GrilleSelectionState state) {
    final r = state.result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _sectionTitle('KẾT QUẢ'),
        const SizedBox(height: 12),

        // App badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accentBright.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accentBright.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.label, color: AppColors.accentBright, size: 14),
              const SizedBox(width: 6),
              Text(
                r.applicationLabel,
                style: const TextStyle(
                  color: AppColors.accentBright,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
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
                  '${r.selectedSize!.width.toStringAsFixed(0)}" × ${r.selectedSize!.length.toStringAsFixed(0)}"',
                  style: GoogleFonts.firaCode(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  r.grilleDefinition.displayName,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _statBadge('CFM/grille', r.cfmPerGrille.toStringAsFixed(0)),
                    _statBadge('Tổng', r.totalCfm.toStringAsFixed(0)),
                    _statBadge('Số lượng', '${r.grilleCount}'),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Comparison table
        Row(
          children: [
            const Icon(
              Icons.compare_arrows,
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
            r.velocityWarning != null) ...[
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

  Widget _buildAlternativesTable(GrilleSelectionResult r) {
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
                _tableHeader('Size', flex: 2),
                _tableHeader('V_mặt', flex: 2),
                _tableHeader('V_cổ', flex: 2),
                _tableHeader('NC', flex: 1),
                _tableHeader('ΔP', flex: 2),
                _tableHeader('', flex: 1),
              ],
            ),
          ),
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
                      c.faceVelocityFpm.toStringAsFixed(0),
                      style: TextStyle(
                        color: c.meetsFaceVelocity
                            ? Colors.white
                            : Colors.redAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      c.neckVelocityFpm.toStringAsFixed(0),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
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

  Widget _buildWarnings(GrilleSelectionResult r) {
    return Column(
      children: [
        if (r.sizeWarning != null)
          _warningCard(r.sizeWarning!, Icons.error, Colors.red),
        if (r.achWarning != null)
          _warningCard(r.achWarning!, Icons.info, Colors.cyan),
        if (r.velocityWarning != null)
          _warningCard(r.velocityWarning!, Icons.swap_horiz, Colors.amber),
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
    ValueChanged<String> onChanged, {
    bool inline = false,
  }) {
    if (inline) {
      return TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          suffixText: suffix,
          suffixStyle: const TextStyle(
            color: AppColors.accentBright,
            fontSize: 11,
          ),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.divider),
          ),
        ),
        onChanged: onChanged,
      );
    }
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
