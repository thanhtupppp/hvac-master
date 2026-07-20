import 'package:flutter/material.dart';
import '../../core/hvac/models/enums.dart';
import '../../core/theme/app_colors.dart';

enum AirflowMode { flowRate, airVelocity, ach }

class AirflowCalculatorScreen extends StatefulWidget {
  const AirflowCalculatorScreen({super.key});

  @override
  State<AirflowCalculatorScreen> createState() =>
      _AirflowCalculatorScreenState();
}

class _AirflowCalculatorScreenState extends State<AirflowCalculatorScreen> {
  final _value1Controller = TextEditingController();
  final _value2Controller = TextEditingController();
  final _value3Controller = TextEditingController();
  final _achTargetController = TextEditingController(text: '6');
  String _result = '';
  UnitSystem _unit = UnitSystem.metric;
  AirflowMode _mode = AirflowMode.flowRate;

  @override
  void initState() {
    super.initState();
    _value1Controller.text = '1700';
    _value2Controller.text = '4.5';
    _value3Controller.text = '3.0';
    _recalculate();
    _value1Controller.addListener(_recalculate);
    _value2Controller.addListener(_recalculate);
    _value3Controller.addListener(_recalculate);
    _achTargetController.addListener(_recalculate);
  }

  @override
  void dispose() {
    _value1Controller.dispose();
    _value2Controller.dispose();
    _value3Controller.dispose();
    _achTargetController.dispose();
    super.dispose();
  }

  String get _dimUnit => _unit == UnitSystem.imperial ? 'ft' : 'm';

  void _recalculate() {
    final v1 = double.tryParse(_value1Controller.text);
    final v2 = double.tryParse(_value2Controller.text);
    final v3 = double.tryParse(_value3Controller.text);
    final achTarget = double.tryParse(_achTargetController.text);
    if (v1 == null || v2 == null || v3 == null || achTarget == null) return;

    switch (_mode) {
      case AirflowMode.flowRate:
        final cfm = _unit == UnitSystem.metric ? v1 / 1.699 : v1;
        final areaSqFt = _unit == UnitSystem.metric ? v2 * 10.764 : v2;
        if (areaSqFt <= 0) return;
        final fpm = cfm / areaSqFt;
        final ms = fpm / 196.85;
        final flowCMH = cfm * 1.699;
        setState(
          () => _result =
              '${fpm.toStringAsFixed(1)} FPM\n${ms.toStringAsFixed(2)} m/s\n${flowCMH.toStringAsFixed(1)} m³/h',
        );
        break;
      case AirflowMode.airVelocity:
        final cfm = _unit == UnitSystem.metric ? v1 / 1.699 : v1;
        final fpm = v2;
        if (fpm <= 0) return;
        final areaSqFt = cfm / fpm;
        final diameterIn = v3;
        if (diameterIn <= 0) return;
        final areaFromDia = 3.14159 * diameterIn * diameterIn / 4 / 144;
        final cfmFromDia = fpm * areaFromDia;
        final flowCMH = cfmFromDia * 1.699;
        setState(
          () => _result =
              'Diện tích: ${areaSqFt.toStringAsFixed(2)} ft²\n${(areaSqFt * 929.03).toStringAsFixed(1)} cm²\nLưu lượng (Ø${diameterIn.toStringAsFixed(1)}"): ${cfmFromDia.toStringAsFixed(1)} CFM / ${flowCMH.toStringAsFixed(1)} m³/h',
        );
        break;
      case AirflowMode.ach:
        final length = v1;
        final width = v2;
        final height = v3;
        if (length <= 0 || width <= 0 || height <= 0 || achTarget <= 0) return;

        // Dimensions are always entered in the selected unit system.
        // Volume in ft³: if imperial, dimensions are already in ft; if metric, convert from m³.
        final volCuFt = _unit == UnitSystem.imperial
            ? length * width * height
            : length * width * height * 35.3147;
        final volCuM = volCuFt / 35.3147;

        // Required flow (ACH → CFM)
        final requiredCFM = (achTarget * volCuFt) / 60.0;
        final requiredCMH = requiredCFM * 1.699;

        setState(
          () => _result =
              'Thể tích: ${volCuM.toStringAsFixed(1)} m³ (${volCuFt.toStringAsFixed(1)} ft³)\n'
              'ACH mục tiêu: ${achTarget.toStringAsFixed(1)} lần/giờ\n'
              'Lưu lượng cần: ${requiredCFM.toStringAsFixed(0)} CFM / ${requiredCMH.toStringAsFixed(0)} m³/h',
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Tính Lưu lượng & Vận tốc',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildModeSelector(),
          const SizedBox(height: 16),
          _buildInputFields(),
          const SizedBox(height: 16),
          _buildUnitToggle(),
          const SizedBox(height: 24),
          _buildResultCard(),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final m in AirflowMode.values)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _mode = m;
                  _recalculate();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _mode == m ? AppColors.bgCard : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _modeLabel(m),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _mode == m ? Colors.white : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _modeLabel(AirflowMode m) {
    switch (m) {
      case AirflowMode.flowRate:
        return 'Q = V×A';
      case AirflowMode.airVelocity:
        return 'Đường kính';
      case AirflowMode.ach:
        return 'ACH';
    }
  }

  Widget _buildInputFields() {
    switch (_mode) {
      case AirflowMode.flowRate:
        return Column(
          children: [
            _buildField(
              'Lưu lượng',
              _value1Controller,
              _unit == UnitSystem.imperial ? 'CFM' : 'm³/h',
            ),
            const SizedBox(height: 12),
            _buildField(
              'Diện tích',
              _value2Controller,
              _unit == UnitSystem.imperial ? 'ft²' : 'm²',
            ),
          ],
        );
      case AirflowMode.airVelocity:
        return Column(
          children: [
            _buildField(
              'Lưu lượng',
              _value1Controller,
              _unit == UnitSystem.imperial ? 'CFM' : 'm³/h',
            ),
            const SizedBox(height: 12),
            _buildField('Vận tốc mục tiêu', _value2Controller, 'FPM'),
            const SizedBox(height: 12),
            _buildField(
              'Đường kính (nếu có)',
              _value3Controller,
              _unit == UnitSystem.imperial ? 'inch' : 'mm',
            ),
          ],
        );
      case AirflowMode.ach:
        return Column(
          children: [
            _buildField('Chiều dài phòng', _value1Controller, _dimUnit),
            const SizedBox(height: 12),
            _buildField('Chiều rộng', _value2Controller, _dimUnit),
            const SizedBox(height: 12),
            _buildField('Chiều cao', _value3Controller, _dimUnit),
            const SizedBox(height: 12),
            _buildField('ACH mục tiêu', _achTargetController, 'lần/h'),
          ],
        );
    }
  }

  Widget _buildField(String label, TextEditingController ctrl, String unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: ctrl,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                suffixText: unit,
                suffixStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggle() {
    return Row(
      children: [
        const Text(
          'Hệ đơn vị:',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(width: 12),
        SegmentedButton<UnitSystem>(
          segments: const [
            ButtonSegment(value: UnitSystem.metric, label: Text('Metric')),
            ButtonSegment(value: UnitSystem.imperial, label: Text('Imperial')),
          ],
          selected: {_unit},
          onSelectionChanged: (s) => setState(() {
            _unit = s.first;
            _recalculate();
          }),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
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
          const Text(
            'KẾT QUẢ',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _result.isEmpty ? '—' : _result,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
