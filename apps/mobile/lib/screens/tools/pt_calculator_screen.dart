import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/refrigerant_model.dart';
import 'refrigerant_selector_screen.dart';
import 'pt_calculator/pt_calculator_controller.dart';
import 'pt_calculator/widgets/measurement_cards.dart';
import 'pt_calculator/widgets/pressure_ruler.dart';
import 'pt_calculator/widgets/settings_sheets.dart';

class PTCalculatorScreen extends StatefulWidget {
  const PTCalculatorScreen({super.key});

  @override
  State<PTCalculatorScreen> createState() => _PTCalculatorScreenState();
}

class _PTCalculatorScreenState extends State<PTCalculatorScreen> {
  final PTCalculatorController _controller = PTCalculatorController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Thước kéo tra môi chất Lạnh',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Colors.white, size: 20),
              onPressed: () => _showSettingsBottomSheet(context),
            ),
          )
        ],
      ),
      body: Row(
        children: [
          // Left Side: Vertical Sliding Ruler (Self-updating, not affected by global AnimatedBuilder)
          Expanded(
            flex: 4,
            child: PressureRuler(controller: _controller),
          ),

          // Right Side: Control Panels & Readouts (Rebuilds only when global config changes)
          Expanded(
            flex: 5,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return _RightPanel(
                  data: _controller.panelData,
                  measurementSection: MeasurementCards(
                    tempNotifier: _controller.tempNotifier,
                    pressureNotifier: _controller.pressureNotifier,
                    tempUnitLabel: _controller.tempUnitLabel,
                    pressureUnitLabel: _controller.pressureUnitLabel,
                    validateTemp: _controller.validateTempInput,
                    validatePressure: _controller.validatePressureInput,
                    onTempSubmitted: _controller.submitTempInput,
                    onPressureSubmitted: _controller.submitPressureInput,
                    getTempDisplayValue: _controller.getTempDisplayValue,
                    getPressureDisplayValue: _controller.getPressureDisplayValue,
                  ),
                  onSelectRefrigerant: () async {
                    final result = await Navigator.push<RefrigerantModel>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RefrigerantSelectorScreen(
                          selectedRefrigerant: _controller.refrigerant,
                        ),
                      ),
                    );
                    if (result != null) {
                      _controller.updateRefrigerant(result);
                    }
                  },
                  onToggleDew: _controller.updateIsDew,
                  onToggleAbsolute: (val) => _controller.updateIsGauge(!val),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsBottomSheet(controller: _controller),
    );
  }
}

class _RightPanel extends StatelessWidget {
  final PTCalculatorPanelData data;
  final Widget measurementSection;
  final VoidCallback onSelectRefrigerant;
  final ValueChanged<bool> onToggleDew;
  final ValueChanged<bool> onToggleAbsolute;

  const _RightPanel({
    required this.data,
    required this.measurementSection,
    required this.onSelectRefrigerant,
    required this.onToggleDew,
    required this.onToggleAbsolute,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Refrigerant Select Button
          Material(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: onSelectRefrigerant,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data.refrigerantName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.list, color: Colors.white60),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Toggles: Dew Point & Absolute
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                // Dew Point (Đọng sương)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Đọng sương',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    Switch(
                      value: data.isDew,
                      activeThumbColor: data.accentColor,
                      activeTrackColor: data.accentColor.withValues(alpha: 0.5),
                      onChanged: onToggleDew,
                    ),
                  ],
                ),
                const Divider(color: AppColors.divider, height: 12),
                // Absolute (Tuyệt đối)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tuyệt đối',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    Switch(
                      value: !data.isGauge,
                      activeThumbColor: data.accentColor,
                      activeTrackColor: data.accentColor.withValues(alpha: 0.5),
                      onChanged: onToggleAbsolute,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Digital displays for Pressure & Temperature
          measurementSection,

          const Spacer(),

          // Details Card (Bottom Right)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Nhóm an toàn', data.safetyGroup),
                const SizedBox(height: 8),
                _buildDetailRow(
                  data.gwpLabel,
                  data.gwpValue,
                ),
                const SizedBox(height: 8),
                _buildDetailRow('ODP', data.odpValue),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Nhiệt độ tới hạn',
                  data.criticalTempText,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Điểm sôi (0 bar (g))',
                  data.boilingPointText,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Màu',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: data.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
