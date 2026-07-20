import 'package:flutter/material.dart';
import '../../core/hvac/models/enums.dart';
import '../../core/theme/app_colors.dart';

class AirVelocityCalculatorScreen extends StatefulWidget {
  const AirVelocityCalculatorScreen({super.key});

  @override
  State<AirVelocityCalculatorScreen> createState() =>
      _AirVelocityCalculatorScreenState();
}

class _AirVelocityCalculatorScreenState
    extends State<AirVelocityCalculatorScreen> {
  final _flowController = TextEditingController(text: '1700');
  final _areaController = TextEditingController(text: '0.5');
  double _resultFpm = 0;
  double _resultMs = 0;
  bool _byDuct = false;
  final _diameterController = TextEditingController(text: '300');
  UnitSystem _unit = UnitSystem.metric;

  @override
  void initState() {
    super.initState();
    _flowController.addListener(_recalculate);
    _areaController.addListener(_recalculate);
    _diameterController.addListener(_recalculate);
    _recalculate();
  }

  @override
  void dispose() {
    _flowController.dispose();
    _areaController.dispose();
    _diameterController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final flow = double.tryParse(_flowController.text);
    if (flow == null || flow <= 0) {
      setState(() {
        _resultFpm = 0;
        _resultMs = 0;
      });
      return;
    }

    final cfm = _unit == UnitSystem.metric ? flow / 1.699 : flow;
    double areaSqFt;

    if (_byDuct) {
      final diameter = double.tryParse(_diameterController.text);
      if (diameter == null || diameter <= 0) return;
      final dIn = _unit == UnitSystem.metric ? diameter / 25.4 : diameter;
      areaSqFt = 3.14159 * dIn * dIn / 4 / 144;
    } else {
      final area = double.tryParse(_areaController.text);
      if (area == null || area <= 0) return;
      areaSqFt = _unit == UnitSystem.metric ? area * 10.764 : area;
    }

    if (areaSqFt <= 0) return;
    final fpm = cfm / areaSqFt;
    final ms = fpm / 196.85;
    setState(() {
      _resultFpm = fpm;
      _resultMs = ms;
    });
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
          'Vận tốc Gió',
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
          _buildInputCard(),
          const SizedBox(height: 16),
          _buildUnitToggle(),
          const SizedBox(height: 16),
          _buildModeToggle(),
          const SizedBox(height: 24),
          _buildResultCard(),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _buildField(
            'Lưu lượng gió',
            _flowController,
            _unit == UnitSystem.imperial ? 'CFM' : 'm³/h',
          ),
          const SizedBox(height: 12),
          if (!_byDuct) ...[
            _buildField(
              'Diện tích mặt cắt',
              _areaController,
              _unit == UnitSystem.imperial ? 'ft²' : 'm²',
            ),
            const SizedBox(height: 8),
            const Text(
              'Hoặc tính theo đường kính ống bên dưới',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ] else
            _buildField(
              'Đường kính ống',
              _diameterController,
              _unit == UnitSystem.imperial ? 'inch' : 'mm',
            ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String unit) {
    return Row(
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
          width: 120,
          child: TextField(
            controller: ctrl,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

  Widget _buildModeToggle() {
    return Row(
      children: [
        const Text(
          'Tính theo:',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(width: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Diện tích')),
            ButtonSegment(value: true, label: Text('Đường kính')),
          ],
          selected: {_byDuct},
          onSelectionChanged: (s) => setState(() {
            _byDuct = s.first;
            _recalculate();
          }),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    final velocityLabel = _velocityRating(_resultMs);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _buildResultRow(
            'Vận tốc',
            '${_resultFpm.toStringAsFixed(1)} FPM',
            _resultFpm > 1200 ? Colors.red : Colors.white,
          ),
          const SizedBox(height: 8),
          _buildResultRow(
            'Vận tốc',
            '${_resultMs.toStringAsFixed(2)} m/s',
            Colors.white,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _resultFpm > 1200 ? Icons.warning : Icons.check_circle,
                  color: _resultFpm > 1200 ? Colors.orange : Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  velocityLabel,
                  style: TextStyle(
                    color: _resultFpm > 1200 ? Colors.orange : Colors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _velocityRating(double ms) {
    if (ms < 2.5) return 'Thấp — có thể cảm thấy gió yếu';
    if (ms < 5.0) return 'Bình thường — phù hợp cho không gian thương mại';
    if (ms < 8.0) return 'Cao — có thể gây tiếng ồn';
    return 'Rất cao — cần giảm tốc độ gió';
  }
}
