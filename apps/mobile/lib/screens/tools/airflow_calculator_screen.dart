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
  }

  @override
  void dispose() {
    _value1Controller.dispose();
    _value2Controller.dispose();
    _value3Controller.dispose();
    super.dispose();
  }

  void _recalculate() {
    final v1 = double.tryParse(_value1Controller.text);
    final v2 = double.tryParse(_value2Controller.text);
    final v3 = double.tryParse(_value3Controller.text);
    if (v1 == null || v2 == null || v3 == null) return;

    switch (_mode) {
      case AirflowMode.flowRate:
        final cfm = v1;
        final areaSqFt = v2;
        if (areaSqFt <= 0) return;
        final fpm = cfm / areaSqFt;
        final ms = _unit == UnitSystem.imperial ? fpm : fpm / 196.85;
        final flow = _unit == UnitSystem.imperial ? cfm : cfm * 1.699;
        setState(
          () => _result =
              '${fpm.toStringAsFixed(1)} FPM\n${ms.toStringAsFixed(2)} m/s\n${flow.toStringAsFixed(1)} m³/h',
        );
        break;
      case AirflowMode.airVelocity:
        final cfm = v1;
        final fpm = v2;
        if (fpm <= 0) return;
        final areaSqFt = cfm / fpm;
        final diameterIn = v3;
        if (diameterIn <= 0) return;
        final areaFromDia = 3.14159 * diameterIn * diameterIn / 4 / 144;
        final cfmFromDia = fpm * areaFromDia;
        final flow = _unit == UnitSystem.imperial
            ? cfmFromDia
            : cfmFromDia * 1.699;
        setState(
          () => _result =
              'Diện tích: ${areaSqFt.toStringAsFixed(2)} ft²\n${areaSqFt * 929.03 > 0 ? (areaSqFt * 929.03).toStringAsFixed(1) : '—'} cm²\nLưu lượng (Ø${diameterIn.toStringAsFixed(1)}"): ${flow.toStringAsFixed(1)} ${_unit == UnitSystem.imperial ? 'CFM' : 'm³/h'}',
        );
        break;
      case AirflowMode.ach:
        final length = v1;
        final width = v2;
        final height = v3;
        final vol = length * width * height;
        final cfm = v2;
        if (vol <= 0) return;
        final ach = (cfm * 60) / vol;
        setState(
          () => _result =
              'Thể tích: ${vol.toStringAsFixed(1)} m³\nACH: ${ach.toStringAsFixed(1)} lần/giờ\nCFM cần: ${(ach * vol / 60).toStringAsFixed(1)}',
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
            _buildField('Chiều dài phòng', _value1Controller, 'm'),
            const SizedBox(height: 12),
            _buildField('Chiều rộng', _value2Controller, 'm'),
            const SizedBox(height: 12),
            _buildField('Chiều cao', _value3Controller, 'm'),
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
