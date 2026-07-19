import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/duct/models/enums.dart';
import '../../services/duct/models/rectangle_option.dart';
import '../../services/duct/models/duct_calculator_state.dart';
import '../../services/duct/providers/duct_calculator_notifier.dart';

class DuctCalculatorScreen extends ConsumerStatefulWidget {
  const DuctCalculatorScreen({super.key});

  @override
  ConsumerState<DuctCalculatorScreen> createState() => _DuctCalculatorScreenState();
}

class _DuctCalculatorScreenState extends ConsumerState<DuctCalculatorScreen> {
  final _flowController = TextEditingController();
  final _velocityController = TextEditingController();
  final _frictionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controller values from current state to ensure consistency
    final initialState = ref.read(ductCalculatorProvider);
    final isMetric = initialState.input.unitSystem == UnitSystem.metric;
    _flowController.text = initialState.input.flowRate.toStringAsFixed(0);
    _velocityController.text = initialState.input.targetVelocity.toStringAsFixed(isMetric ? 1 : 0);
    _frictionController.text = initialState.input.frictionRate.toStringAsFixed(isMetric ? 2 : 4);
  }

  @override
  void dispose() {
    _flowController.dispose();
    _velocityController.dispose();
    _frictionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ductCalculatorProvider);
    final notifier = ref.read(ductCalculatorProvider.notifier);

    // Listen for system/method state changes to update inputs without cursor jumping
    ref.listen<DuctCalculatorState>(ductCalculatorProvider, (previous, next) {
      if (previous == null || previous.input.unitSystem != next.input.unitSystem) {
        final nextIsMetric = next.input.unitSystem == UnitSystem.metric;
        _flowController.text = next.input.flowRate.toStringAsFixed(0);
        _velocityController.text = next.input.targetVelocity.toStringAsFixed(nextIsMetric ? 1 : 0);
        _frictionController.text = next.input.frictionRate.toStringAsFixed(nextIsMetric ? 2 : 4);
      }
      if (previous != null && previous.input.ductType != next.input.ductType) {
        final nextIsMetric = next.input.unitSystem == UnitSystem.metric;
        _velocityController.text = next.input.targetVelocity.toStringAsFixed(nextIsMetric ? 1 : 0);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Tính Toán Thiết Kế Ống Gió',
          style: GoogleFonts.firaCode(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Segmented controls
            _buildSegmentControls(state, notifier),
            const SizedBox(height: 20),

            // Inputs card
            _buildInputCard(state, notifier),
            const SizedBox(height: 20),

            // Results layout
            if (state.status == CalculationStatus.success && state.result != null) ...[
              _buildRoundHeroCard(state),
              const SizedBox(height: 20),
              _buildRectangleSection(state),
            ] else if (state.status == CalculationStatus.calculating) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: AppColors.accentPrimary),
                ),
              )
            ] else if (state.status == CalculationStatus.error) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  state.errorMessage ?? 'Lỗi tính toán',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentControls(DuctCalculatorState state, DuctCalculatorNotifier notifier) {
    final isMetric = state.input.unitSystem == UnitSystem.metric;
    final isVelocity = state.input.method == CalculationMethod.velocity;

    return Row(
      children: [
        // Unit System Segmented Control
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => notifier.onUnitSystemChanged(UnitSystem.metric),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isMetric ? AppColors.accentPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Metric',
                        style: TextStyle(
                          color: isMetric ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => notifier.onUnitSystemChanged(UnitSystem.imperial),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !isMetric ? AppColors.accentPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Imperial',
                        style: TextStyle(
                          color: !isMetric ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Method Segmented Control
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => notifier.onMethodChanged(CalculationMethod.velocity),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isVelocity ? AppColors.accentPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Velocity',
                        style: TextStyle(
                          color: isVelocity ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => notifier.onMethodChanged(CalculationMethod.equalFriction),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !isVelocity ? AppColors.accentPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Friction',
                        style: TextStyle(
                          color: !isVelocity ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard(DuctCalculatorState state, DuctCalculatorNotifier notifier) {
    final isMetric = state.input.unitSystem == UnitSystem.metric;
    final isVelocity = state.input.method == CalculationMethod.velocity;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<DuctType>(
            key: const Key('ductTypeDropdown'),
            value: state.input.ductType,
            dropdownColor: AppColors.bgCard,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: const InputDecoration(
              labelText: 'Loại đường ống',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
            ),
            items: DuctType.values.map((t) {
              String name = '';
              switch (t) {
                case DuctType.supplyMain:
                  name = 'Supply Main';
                  break;
                case DuctType.supplyBranch:
                  name = 'Supply Branch';
                  break;
                case DuctType.returnMain:
                  name = 'Return Main';
                  break;
                case DuctType.exhaust:
                  name = 'Exhaust';
                  break;
                case DuctType.custom:
                  name = 'Custom';
                  break;
              }
              return DropdownMenuItem(value: t, child: Text(name));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                notifier.onDuctTypeChanged(val);
              }
            },
          ),
          const Divider(color: AppColors.divider),
          _buildField(
            key: const Key('flowRateField'),
            label: 'Lưu lượng gió',
            suffix: isMetric ? 'm³/h' : 'CFM',
            controller: _flowController,
            onChanged: (val) {
              final d = double.tryParse(val);
              if (d != null) notifier.onFlowRateChanged(d);
            },
          ),
          if (isVelocity) ...[
            const Divider(color: AppColors.divider),
            _buildField(
              key: const Key('velocityField'),
              label: 'Vận tốc thiết kế',
              suffix: isMetric ? 'm/s' : 'fpm',
              controller: _velocityController,
              onChanged: (val) {
                final d = double.tryParse(val);
                if (d != null) notifier.onTargetVelocityChanged(d);
              },
            ),
          ] else ...[
            const Divider(color: AppColors.divider),
            _buildField(
              key: const Key('frictionField'),
              label: 'Độ tổn thất ma sát',
              suffix: isMetric ? 'Pa/m' : 'in.wg/100ft',
              controller: _frictionController,
              onChanged: (val) {
                final d = double.tryParse(val);
                if (d != null) notifier.onFrictionRateChanged(d);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField({
    required Key key,
    required String label,
    required String suffix,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              key: key,
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
              ),
              onChanged: onChanged,
            ),
          ),
          Text(
            suffix,
            style: const TextStyle(color: AppColors.accentPrimary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundHeroCard(DuctCalculatorState state) {
    final round = state.result!.roundDuct;
    final isMetric = state.input.unitSystem == UnitSystem.metric;
    final suffix = isMetric ? 'mm' : '"';

    return Container(
      key: const Key('roundHeroCard'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.bgSecondary, AppColors.bgCard],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'ỐNG TRÒN GỢI Ý (HERO)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Ø ${round.standardDiameter.toStringAsFixed(0)} $suffix',
            style: GoogleFonts.firaCode(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '(Tính toán: ${round.calculatedDiameter.toStringAsFixed(1)} $suffix)',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSpecItem('Vận tốc', '${round.velocity.toStringAsFixed(1)} ${isMetric ? 'm/s' : 'fpm'}'),
              _buildSpecItem('Ma sát', '${round.frictionRate.toStringAsFixed(2)} ${isMetric ? 'Pa/m' : 'in/100ft'}'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildRectangleSection(DuctCalculatorState state) {
    final List<RectangleOption> options = state.result!.rectangleOptions;
    if (options.isEmpty) return const SizedBox();

    final top = options.first;
    final others = options.skip(1).take(5).toList();
    final isMetric = state.input.unitSystem == UnitSystem.metric;
    final suffix = isMetric ? 'mm' : '"';

    return Column(
      key: const Key('rectangleSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ỐNG CHỮ NHẬT ĐỀ XUẤT (BEST)',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${top.width.toStringAsFixed(0)} × ${top.height.toStringAsFixed(0)} $suffix',
                    style: GoogleFonts.firaCode(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < top.stars ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 18,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Vận tốc: ${top.velocity.toStringAsFixed(1)} ${isMetric ? 'm/s' : 'fpm'}', style: const TextStyle(color: AppColors.textSecondary)),
                  const Text('✓ RECOMMENDED SIZE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'PHƯƠNG ÁN KHÁC (MORE OPTIONS)',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...others.map((opt) {
          return Card(
            key: ValueKey('option_${opt.width}_${opt.height}'),
            color: AppColors.bgSecondary,
            child: ListTile(
              title: Text(
                '${opt.width.toStringAsFixed(0)} × ${opt.height.toStringAsFixed(0)} $suffix',
                style: GoogleFonts.firaCode(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Vận tốc: ${opt.velocity.toStringAsFixed(1)} ${isMetric ? 'm/s' : 'fpm'}'),
              trailing: Text('${opt.stars} Sao', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ],
    );
  }
}
