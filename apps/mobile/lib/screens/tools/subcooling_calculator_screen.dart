import 'package:flutter/material.dart';
import '../../core/hvac/thermo/thermo.dart';
import '../../core/theme/app_colors.dart';
import '../../models/refrigerant_model.dart';

class SubcoolingCalculatorScreen extends StatefulWidget {
  const SubcoolingCalculatorScreen({super.key});

  @override
  State<SubcoolingCalculatorScreen> createState() => _SubcoolingCalculatorScreenState();
}

class _SubcoolingCalculatorScreenState extends State<SubcoolingCalculatorScreen> {
  final _thermo = Thermodynamics();
  final _liquidPressureController = TextEditingController(text: '335');
  final _liquidTempController = TextEditingController(text: '30');
  String _pressureUnit = 'PSI';
  String _refrigerant = 'R410A';
  bool _isGauge = true;
  double _satTempC = 0;
  double _subcooling = 0;

  @override
  void initState() {
    super.initState();
    _liquidPressureController.addListener(_recalculate);
    _liquidTempController.addListener(_recalculate);
    _recalculate();
  }

  @override
  void dispose() {
    _liquidPressureController.dispose();
    _liquidTempController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final p = double.tryParse(_liquidPressureController.text);
    final t = double.tryParse(_liquidTempController.text);
    if (p == null || t == null) return;

    final satC = _thermo.getTempFromPressure(
      refrigerant: _refrigerant,
      pressure: p,
      pressureUnit: _pressureUnit,
      isGauge: _isGauge,
      isDew: false,
    );

    setState(() {
      _satTempC = satC;
      _subcooling = satC - t;
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Độ Quá Lạnh (Subcooling)',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildRefrigerantSelector(),
          const SizedBox(height: 16),
          _buildInputSection(),
          const SizedBox(height: 16),
          _buildUnitToggle(),
          const SizedBox(height: 24),
          _buildResultCard(),
          const SizedBox(height: 24),
          _buildReferenceCard(),
        ],
      ),
    );
  }

  Widget _buildRefrigerantSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _refrigerant,
          isExpanded: true,
          dropdownColor: AppColors.bgSecondary,
          items: [
            for (final r in defaultRefrigerants)
              DropdownMenuItem<String>(
                value: r.name,
                child: Text(
                  '${r.name} — ${r.typeClass}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() { _refrigerant = val; _recalculate(); });
            }
          },
        ),
      ),
    );
  }

  Widget _buildInputSection() {
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
          const Text('ĐẦU VÀO', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 16),
          _buildField('Áp suất đường lỏng', _liquidPressureController, _pressureUnit),
          const SizedBox(height: 12),
          _buildField('Nhiệt độ đường lỏng', _liquidTempController, '°C'),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String unit) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        SizedBox(
          width: 140,
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              suffixText: unit,
              suffixStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitToggle() {
    return Row(
      children: [
        const Text('Đơn vị áp suất:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(width: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'PSI', label: Text('PSI')),
            ButtonSegment(value: 'Bar', label: Text('Bar')),
          ],
          selected: {_pressureUnit},
          onSelectionChanged: (s) {
            final p = double.tryParse(_liquidPressureController.text) ?? 1.0;
            setState(() {
              _pressureUnit = s.first;
              if (_pressureUnit == 'Bar') {
                _liquidPressureController.text = (p / 14.5038).toStringAsFixed(2);
              } else {
                _liquidPressureController.text = (p * 14.5038).toStringAsFixed(1);
              }
              _recalculate();
            });
          },
        ),
        const Spacer(),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Gauge')),
            ButtonSegment(value: false, label: Text('Abs')),
          ],
          selected: {_isGauge},
          onSelectionChanged: (s) => setState(() { _isGauge = s.first; _recalculate(); }),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    final sc = _subcooling;
    final satC = _satTempC;
    final isNan = satC.isNaN;
    final rating = _scRating(sc);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Text('KẾT QUẢ', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          _resultRow('Nhiệt độ bão hòa', isNan ? '—' : '${satC.toStringAsFixed(1)} °C'),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 8),
          Text(
            isNan ? '—' : '${sc.toStringAsFixed(1)} K',
            style: TextStyle(
              color: _scColor(sc),
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Độ Quá Lạnh',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _scColor(sc).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_scIcon(sc), color: _scColor(sc), size: 18),
                const SizedBox(width: 8),
                Text(rating, style: TextStyle(color: _scColor(sc), fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildReferenceCard() {
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
          const Text('THAM KHẢO SUB coOLING', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          _refRow('Hệ thống Residential A/C', '8–14 K'),
          _refRow('Hệ thống Commercial A/C', '5–15 K'),
          _refRow('Hệ thống Heat Pump', '6–12 K'),
          _refRow('Low temp Refrigeration', '3–8 K'),
          const SizedBox(height: 8),
          const Text('* Giá trị tham khảo, phụ thuộc thiết kế hệ thống', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _refRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _scRating(double sc) {
    if (sc.isNaN) return 'N/A';
    if (sc < 3) return 'Thấp — có thể thiếu gas';
    if (sc <= 15) return 'Bình thường';
    return 'Cao — có thể quá nhiều gas hoặc vấn đề dàn ngưng';
  }

  Color _scColor(double sc) {
    if (sc.isNaN) return AppColors.textMuted;
    if (sc < 3) return Colors.red;
    if (sc <= 15) return Colors.green;
    return Colors.orange;
  }

  IconData _scIcon(double sc) {
    if (sc.isNaN) return Icons.help;
    if (sc < 3) return Icons.warning;
    if (sc <= 15) return Icons.check_circle;
    return Icons.info;
  }
}
