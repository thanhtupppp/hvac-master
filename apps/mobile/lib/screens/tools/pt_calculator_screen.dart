import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/refrigerant_model.dart';
import '../../services/coolprop.dart';
import 'refrigerant_selector_screen.dart';

class PTCalculatorScreen extends StatefulWidget {
  const PTCalculatorScreen({super.key});

  @override
  State<PTCalculatorScreen> createState() => _PTCalculatorScreenState();
}

class _PTCalculatorScreenState extends State<PTCalculatorScreen> {
  // Currently selected refrigerant (default R32)
  RefrigerantModel _refrigerant = defaultRefrigerants.first;

  bool _isDew = false; // Dew point (Đọng sương) vs Bubble point (Bọt)
  bool _isGauge = false; // Gauge (Tương đối) vs Absolute (Tuyệt đối) - default absolute matching screenshot (bar(a))
  final String _pressureUnit = 'Bar';
  final String _tempUnit = '°C';

  double _tempValue = -25.46; // Matches screenshot value
  double _pressureValue = 3.29; // Matches screenshot value

  late ScrollController _scrollController;
  bool _isScrollingFromRuler = false;

  // Ruler config
  final double _minTemp = -70.0;
  final double _maxTemp = 70.0;
  final double _itemHeight = 15.0; // Height per 1°C

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _calculateValues(fromTemp: true);
    
    // Jump ruler to the initial temperature
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncRulerToTemp();
      _scrollController.addListener(_onRulerScroll);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onRulerScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Calculate matching values
  void _calculateValues({required bool fromTemp}) {
    if (fromTemp) {
      _pressureValue = CoolProp.getPressureFromTemp(
        refrigerant: _refrigerant.name,
        tempCelsius: _tempValue,
        pressureUnit: _pressureUnit,
        isGauge: _isGauge,
        isDew: _isDew,
      );
    } else {
      _tempValue = CoolProp.getTempFromPressure(
        refrigerant: _refrigerant.name,
        pressure: _pressureValue,
        pressureUnit: _pressureUnit,
        isGauge: _isGauge,
        isDew: _isDew,
      );
    }
  }

  // Ruler scroll listener
  void _onRulerScroll() {
    if (!_scrollController.hasClients) return;
    
    // If the scroll is triggered by user dragging the ruler
    if (_scrollController.position.isScrollingNotifier.value) {
      _isScrollingFromRuler = true;
    }

    if (_isScrollingFromRuler) {
      final double offset = _scrollController.offset;
      final double temp = _minTemp + (offset / _itemHeight);
      setState(() {
        _tempValue = temp.clamp(_minTemp, _maxTemp);
        _calculateValues(fromTemp: true);
      });
    }
  }

  // Syncs scroll controller position to matches _tempValue
  void _syncRulerToTemp() {
    if (!_scrollController.hasClients) return;
    final double targetOffset = (_tempValue - _minTemp) * _itemHeight;
    _isScrollingFromRuler = false;
    _scrollController.jumpTo(targetOffset);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _refrigerant.color;

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
          // Filter indicator / settings button
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Colors.white, size: 20),
              onPressed: () async {
                // Navigate to refrigerant list to choose
                final result = await Navigator.push<RefrigerantModel>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RefrigerantSelectorScreen(selectedRefrigerant: _refrigerant),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _refrigerant = result;
                    _calculateValues(fromTemp: true);
                  });
                  _syncRulerToTemp();
                }
              },
            ),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final rulerHeight = constraints.maxHeight;
          final halfRulerHeight = rulerHeight / 2;

          return Row(
            children: [
              // Left Side: Vertical Sliding Ruler
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Scrollable ticks list
                      ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(vertical: halfRulerHeight - (_itemHeight / 2)),
                        itemCount: (_maxTemp - _minTemp).toInt() + 1,
                        itemExtent: _itemHeight,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final currentTemp = _minTemp + index;
                          final isMajorTemp = currentTemp % 10 == 0;
                          final isMediumTemp = currentTemp % 5 == 0;

                          // Saturation pressure at this temperature
                          final double currentPress = CoolProp.getPressureFromTemp(
                            refrigerant: _refrigerant.name,
                            tempCelsius: currentTemp,
                            pressureUnit: _pressureUnit,
                            isGauge: _isGauge,
                            isDew: _isDew,
                          );

                          return SizedBox(
                            height: _itemHeight,
                            child: Row(
                              children: [
                                // Left side: Pressure values
                                Expanded(
                                  child: isMajorTemp
                                      ? Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            currentPress.toStringAsFixed(1),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                const SizedBox(width: 8),

                                // Center: Ticks
                                SizedBox(
                                  width: 40,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Vertical center line
                                      Container(
                                        width: 1,
                                        color: Colors.white10,
                                      ),
                                      // Tick lines
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Left (Pressure side) tick
                                            Container(
                                              width: isMajorTemp ? 12 : (isMediumTemp ? 8 : 4),
                                              height: 1,
                                              color: Colors.white30,
                                            ),
                                            // Right (Temp side) tick
                                            Container(
                                              width: isMajorTemp ? 12 : (isMediumTemp ? 8 : 4),
                                              height: 1,
                                              color: Colors.white30,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Right side: Temp values
                                Expanded(
                                  child: isMajorTemp
                                      ? Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            currentTemp.toInt().toString(),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Ruler top header indicators
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_pressureUnit.toLowerCase()}${_isGauge ? '(g)' : '(a)'}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _tempUnit,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      // Viewfinder overlay in the center
                      IgnorePointer(
                        child: Container(
                          height: 48,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(width: 16, height: 1, color: accentColor),
                              Container(width: 16, height: 1, color: accentColor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right Side: Control Panels & Readouts
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Refrigerant Name & List Icon
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push<RefrigerantModel>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RefrigerantSelectorScreen(selectedRefrigerant: _refrigerant),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              _refrigerant = result;
                              _calculateValues(fromTemp: true);
                            });
                            _syncRulerToTemp();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _refrigerant.name,
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
                                  value: _isDew,
                                  activeThumbColor: accentColor,
                                  activeTrackColor: accentColor.withValues(alpha: 0.5),
                                  onChanged: (val) {
                                    setState(() {
                                      _isDew = val;
                                      _calculateValues(fromTemp: true);
                                    });
                                  },
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
                                  value: !_isGauge, // Absolute = !Gauge
                                  activeThumbColor: accentColor,
                                  activeTrackColor: accentColor.withValues(alpha: 0.5),
                                  onChanged: (val) {
                                    setState(() {
                                      _isGauge = !val;
                                      _calculateValues(fromTemp: true);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Digital Display 1: Pressure
                      _buildDisplayCard(
                        value: _pressureValue.toStringAsFixed(2),
                        unit: '${_pressureUnit.toLowerCase()} (${_isGauge ? 'g' : 'a'})',
                        onTap: () => _showInputDialog(
                          title: 'Nhập áp suất',
                          defaultValue: _pressureValue.toStringAsFixed(2),
                          onSubmitted: (val) {
                            final double? d = double.tryParse(val);
                            if (d != null && d > 0) {
                              setState(() {
                                _pressureValue = d;
                                _calculateValues(fromTemp: false);
                              });
                              _syncRulerToTemp();
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Digital Display 2: Temperature
                      _buildDisplayCard(
                        value: _tempValue.toStringAsFixed(2),
                        unit: _tempUnit,
                        onTap: () => _showInputDialog(
                          title: 'Nhập nhiệt độ',
                          defaultValue: _tempValue.toStringAsFixed(2),
                          onSubmitted: (val) {
                            final double? d = double.tryParse(val);
                            if (d != null && d >= _minTemp && d <= _maxTemp) {
                              setState(() {
                                _tempValue = d;
                                _calculateValues(fromTemp: true);
                              });
                              _syncRulerToTemp();
                            }
                          },
                        ),
                      ),
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
                            _buildDetailRow('Nhóm an toàn', _refrigerant.safetyGroup),
                            const SizedBox(height: 8),
                            _buildDetailRow('GWP-AR4', _refrigerant.gwp.toInt().toString()),
                            const SizedBox(height: 8),
                            _buildDetailRow('ODP', _refrigerant.odp.toString()),
                            const SizedBox(height: 8),
                            _buildDetailRow('Nhiệt độ tới hạn', '${_refrigerant.criticalTemp} °C'),
                            const SizedBox(height: 8),
                            _buildDetailRow('Điểm sôi (0 bar (g))', '${_refrigerant.boilingPoint} °C'),
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
                                    color: accentColor,
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDisplayCard({
    required String value,
    required String unit,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              unit,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Double click or tap digital readout helper dialog
  void _showInputDialog({
    required String title,
    required String defaultValue,
    required ValueChanged<String> onSubmitted,
  }) {
    final controller = TextEditingController(text: defaultValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentPrimary)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary),
            onPressed: () {
              onSubmitted(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
