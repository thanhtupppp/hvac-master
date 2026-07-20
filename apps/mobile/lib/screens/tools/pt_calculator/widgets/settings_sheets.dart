import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../pt_calculator_controller.dart';

class SettingsBottomSheet extends StatelessWidget {
  final PTCalculatorController controller;

  const SettingsBottomSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cài đặt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Material(
                    color: const Color(0xFF334155),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Item 1: Pressure unit dropdown
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Áp suất',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.pressureUnit.toLowerCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.pressureUnit,
                        dropdownColor: AppColors.bgCard,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white54,
                        ),
                        items: ['Bar', 'PSI', 'kPa'].map((String val) {
                          return DropdownMenuItem<String>(
                            value: val,
                            child: Text(
                              val.toLowerCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            controller.updatePressureUnit(val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Item 2: Temperature Unit
              _buildSegmentedSettingRow(
                label: 'Nhiệt độ',
                value: controller.tempUnit,
                options: ['°C', '°F'],
                onChanged: (val) => controller.updateTempUnit(val),
              ),
              const SizedBox(height: 16),

              // Item 3: Distance Unit
              _buildSegmentedSettingRow(
                label: 'Đơn vị đo khoảng cách',
                value: controller.distanceUnit,
                options: ['m', 'ft'],
                onChanged: (val) => controller.updateDistanceUnit(val),
              ),
              const SizedBox(height: 24),

              const Text(
                'Thước kéo tra môi chất Lạnh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Item 4: GWP Standard
              _buildSegmentedSettingRow(
                label: 'GWP',
                value: controller.gwpStandard,
                options: ['AR4', 'AR5', 'AR6'],
                onChanged: (val) => controller.updateGwpStandard(val),
              ),
              const SizedBox(height: 16),

              // Item 5: Reverse Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.swap_vert, color: Colors.white70, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Đảo ngược thanh trượt',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                  Switch(
                    value: controller.reverseSlider,
                    activeThumbColor: Colors.amber,
                    activeTrackColor: Colors.amber.withValues(alpha: 0.5),
                    onChanged: (val) => controller.updateReverseSlider(val),
                  ),
                ],
              ),
              const Divider(color: AppColors.divider, height: 24),

              // Item 6: Environmental Pressure Settings link
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.pop(context); // Close Settings sheet
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          AmbientPressureBottomSheet(controller: controller),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.landscape,
                              color: Colors.white70,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Áp suất môi trường và máy đo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white30,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegmentedSettingRow({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: options.map((opt) {
              final isSelected = opt == value;
              return Material(
                color: isSelected
                    ? const Color(0xFF334155)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onChanged(opt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: Text(
                      opt,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white30,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class AmbientPressureBottomSheet extends StatefulWidget {
  final PTCalculatorController controller;

  const AmbientPressureBottomSheet({super.key, required this.controller});

  @override
  State<AmbientPressureBottomSheet> createState() =>
      _AmbientPressureBottomSheetState();
}

class _AmbientPressureBottomSheetState
    extends State<AmbientPressureBottomSheet> {
  late String _tempGaugeType;
  late bool _tempUseBarometer;
  late double _tempElevation;

  @override
  void initState() {
    super.initState();
    _tempGaugeType = widget.controller.gaugeType;
    _tempUseBarometer = widget.controller.useBarometer;
    _tempElevation = widget.controller.elevation;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Áp suất môi trường và máy đo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Material(
                color: const Color(0xFF334155),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close, color: Colors.white70, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Gauge Type
          const Text(
            'Loại máy đo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildGaugeTypeSegmentedControl(_tempGaugeType, (val) {
            setState(() {
              _tempGaugeType = val;
            });
          }),
          const SizedBox(height: 24),

          // Barometer Use
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sử dụng áp kế',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: _tempUseBarometer,
                activeThumbColor: Colors.amber,
                activeTrackColor: Colors.amber.withValues(alpha: 0.5),
                onChanged: (val) {
                  setState(() {
                    _tempUseBarometer = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Elevation Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Độ cao',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _tempElevation.round().toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'm',
                      style: TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Elevation Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.amber,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              overlayColor: Colors.amber.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _tempElevation,
              min: 0.0,
              max: 5500.0,
              onChanged: (val) {
                setState(() {
                  _tempElevation = val;
                });
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0 m',
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
                Text(
                  '5500 m',
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Bottom Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _tempGaugeType = 'Khô';
                      _tempUseBarometer = false;
                      _tempElevation = 100.0;
                    });
                  },
                  child: const Text(
                    'CÀI ĐẶT LẠI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF334155),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    widget.controller.updateAtmosphericSettings(
                      gaugeType: _tempGaugeType,
                      useBarometer: _tempUseBarometer,
                      elevation: _tempElevation,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'ĐÃ THỰC HIỆN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeTypeSegmentedControl(
    String selectedType,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: ['Khô', 'Đầy chất lỏng'].map((type) {
          final isSelected = type == selectedType;
          return Expanded(
            child: Material(
              color: isSelected ? const Color(0xFF334155) : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onChanged(type),
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white30,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
