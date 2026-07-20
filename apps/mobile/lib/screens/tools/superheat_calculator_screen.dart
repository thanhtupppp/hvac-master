import 'package:flutter/material.dart';
import '../../core/hvac/standards/diagnostic_thresholds.dart';
import '../../core/hvac/thermo/thermo.dart';
import '../../core/hvac/units/pressure.dart';
import '../../core/theme/app_colors.dart';
import '../../models/refrigerant_model.dart';

class SuperheatCalculatorScreen extends StatefulWidget {
  const SuperheatCalculatorScreen({super.key});

  @override
  State<SuperheatCalculatorScreen> createState() =>
      _SuperheatCalculatorScreenState();
}

class _SuperheatCalculatorScreenState extends State<SuperheatCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Thermodynamics _thermo = Thermodynamics();
  RefrigerantModel _refrigerant = defaultRefrigerants.first; // R32

  String _pressureUnit = 'PSI';
  final String _tempUnit = '°C';
  final bool _isGauge = true;

  // Superheat inputs
  final _suctionPressureController = TextEditingController(text: '115');
  final _suctionTempController = TextEditingController(text: '8');
  double _suctionPressure = 115.0;
  double _suctionTemp = 8.0;

  // Subcooling inputs
  final _liquidPressureController = TextEditingController(text: '335');
  final _liquidTempController = TextEditingController(text: '30');
  double _liquidPressure = 335.0;
  double _liquidTemp = 30.0;

  // Calculated results
  double _satTemp = 0.0;
  double _resultVal = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_recalculate);
    _recalculate();
  }

  @override
  void dispose() {
    _tabController.removeListener(_recalculate);
    _tabController.dispose();
    _suctionPressureController.dispose();
    _suctionTempController.dispose();
    _liquidPressureController.dispose();
    _liquidTempController.dispose();
    super.dispose();
  }

  void _recalculate() {
    setState(() {
      if (_tabController.index == 0) {
        // Superheat = Suction Line Temp - Suction Sat Temp
        final satTempC = _thermo.getTempFromPressure(
          refrigerant: _refrigerant.name,
          pressure: _suctionPressure,
          pressureUnit: _pressureUnit,
          isGauge: _isGauge,
        );
        _satTemp = satTempC;
        _resultVal = _suctionTemp - _satTemp;
      } else {
        // Subcooling = Liquid Sat Temp - Liquid Line Temp
        final satTempC = _thermo.getTempFromPressure(
          refrigerant: _refrigerant.name,
          pressure: _liquidPressure,
          pressureUnit: _pressureUnit,
          isGauge: _isGauge,
        );
        _satTemp = satTempC;
        _resultVal = _satTemp - _liquidTemp;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFFFF9800);

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
          'Độ Quá Nhiệt / Quá Lạnh',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Refrigerant Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _refrigerant.name,
                        dropdownColor: AppColors.bgSecondary,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white70,
                        ),
                        items: ['R32', 'R22', 'R134a', 'R410A', 'R404A'].map((
                          String key,
                        ) {
                          return DropdownMenuItem<String>(
                            value: key,
                            child: Text(
                              key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _refrigerant = defaultRefrigerants.firstWhere(
                                (r) => r.name == val,
                              );
                            });
                            _recalculate();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Pressure Unit Toggle
                GestureDetector(
                  onTap: () {
                    final pSuction =
                        double.tryParse(_suctionPressureController.text) ?? 0.0;
                    final pLiquid =
                        double.tryParse(_liquidPressureController.text) ?? 0.0;
                    setState(() {
                      if (_pressureUnit == 'PSI') {
                        // Switching to Bar: convert PSI → Bar
                        _pressureUnit = 'Bar';
                        _suctionPressure = PressureConverter.convert(
                          pSuction,
                          PressureUnit.psi,
                          PressureUnit.bar,
                        );
                        _liquidPressure = PressureConverter.convert(
                          pLiquid,
                          PressureUnit.psi,
                          PressureUnit.bar,
                        );
                      } else {
                        // Switching to PSI: convert Bar → PSI
                        _pressureUnit = 'PSI';
                        _suctionPressure = PressureConverter.convert(
                          pSuction,
                          PressureUnit.bar,
                          PressureUnit.psi,
                        );
                        _liquidPressure = PressureConverter.convert(
                          pLiquid,
                          PressureUnit.bar,
                          PressureUnit.psi,
                        );
                      }
                      _suctionPressureController.text = _suctionPressure
                          .toStringAsFixed(1);
                      _liquidPressureController.text = _liquidPressure
                          .toStringAsFixed(1);
                    });
                    _recalculate();
                  },
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Center(
                      child: Text(
                        _pressureUnit,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Độ Quá Nhiệt (SH)'),
                  Tab(text: 'Độ Quá Lạnh (SC)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tab content area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Superheat Panel
                _buildCalculatorTab(
                  pressureLabel: 'Áp suất đầu hút (Suction Pressure)',
                  tempLabel: 'Nhiệt độ đường hút (Suction Line Temp)',
                  pressureController: _suctionPressureController,
                  tempController: _suctionTempController,
                  satTempLabel: 'Nhiệt độ bão hòa (Sat Temp):',
                  resultLabel: 'Độ quá nhiệt (Superheat):',
                  accentColor: accentColor,
                  onPressureChanged: (val) {
                    final double? d = double.tryParse(val);
                    if (d != null && d > 0) {
                      _suctionPressure = d;
                      _recalculate();
                    }
                  },
                  onTempChanged: (val) {
                    final double? d = double.tryParse(val);
                    if (d != null) {
                      _suctionTemp = d;
                      _recalculate();
                    }
                  },
                ),

                // Subcooling Panel
                _buildCalculatorTab(
                  pressureLabel: 'Áp suất đường lỏng (Liquid Pressure)',
                  tempLabel: 'Nhiệt độ đường lỏng (Liquid Line Temp)',
                  pressureController: _liquidPressureController,
                  tempController: _liquidTempController,
                  satTempLabel: 'Nhiệt độ bão hòa (Sat Temp):',
                  resultLabel: 'Độ quá lạnh (Subcooling):',
                  accentColor: accentColor,
                  onPressureChanged: (val) {
                    final double? d = double.tryParse(val);
                    if (d != null && d > 0) {
                      _liquidPressure = d;
                      _recalculate();
                    }
                  },
                  onTempChanged: (val) {
                    final double? d = double.tryParse(val);
                    if (d != null) {
                      _liquidTemp = d;
                      _recalculate();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorTab({
    required String pressureLabel,
    required String tempLabel,
    required TextEditingController pressureController,
    required TextEditingController tempController,
    required String satTempLabel,
    required String resultLabel,
    required Color accentColor,
    required ValueChanged<String> onPressureChanged,
    required ValueChanged<String> onTempChanged,
  }) {
    // Determine feedback/diagnosis based on result
    String diagnosisText = '';
    Color diagnosisColor = Colors.grey;

    if (_resultVal.isNaN || _satTemp.isNaN) {
      diagnosisText = 'Ngoài giới hạn tính toán (Trạng thái siêu tới hạn)';
      diagnosisColor = Colors.redAccent;
    } else if (_tabController.index == 0) {
      // Superheat diagnosis (in Kelvin)
      if (_resultVal < DiagnosticThresholds.superheatLowK) {
        diagnosisText =
            'Quá nhiệt thấp - Nguy cơ ngập dịch nén (Liquid Floodback)';
        diagnosisColor = Colors.redAccent;
      } else if (_resultVal > DiagnosticThresholds.superheatHighK) {
        diagnosisText =
            'Quá nhiệt cao - Thiếu ga hoặc nghẹt cáp/expansion valve';
        diagnosisColor = Colors.orange;
      } else {
        diagnosisText = 'Độ quá nhiệt lý tưởng - Hệ thống hoạt động tốt';
        diagnosisColor = Colors.green;
      }
    } else {
      // Subcooling diagnosis (in Kelvin)
      if (_resultVal < DiagnosticThresholds.subcoolingLowK) {
        diagnosisText = 'Quá lạnh thấp - Thiếu ga hoặc ngưng tụ kém';
        diagnosisColor = Colors.redAccent;
      } else if (_resultVal > DiagnosticThresholds.subcoolingHighK) {
        diagnosisText =
            'Quá lạnh cao - Dư ga hoặc tắc nghẽn phin lọc/đường lỏng';
        diagnosisColor = Colors.orange;
      } else {
        diagnosisText = 'Độ quá lạnh lý tưởng - Hệ thống hoạt động tốt';
        diagnosisColor = Colors.green;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _buildInputField(
                  label: pressureLabel,
                  unit: _pressureUnit,
                  controller: pressureController,
                  onChanged: onPressureChanged,
                ),
                const Divider(color: AppColors.divider, height: 28),
                _buildInputField(
                  label: tempLabel,
                  unit: _tempUnit,
                  controller: tempController,
                  onChanged: onTempChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mid sat temp card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  satTempLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  _satTemp.isNaN
                      ? '--'
                      : '${_satTemp.toStringAsFixed(1)} $_tempUnit',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Output Result Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  resultLabel,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _resultVal.isNaN
                      ? '--'
                      : '${_resultVal.toStringAsFixed(1)} K',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _resultVal.isNaN
                      ? ''
                      : '(${_resultVal.toStringAsFixed(1)} $_tempUnit)',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: diagnosisColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: diagnosisColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    diagnosisText,
                    style: TextStyle(
                      color: diagnosisColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String unit,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              unit,
              style: const TextStyle(
                color: Color(0xFFFF9800),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
