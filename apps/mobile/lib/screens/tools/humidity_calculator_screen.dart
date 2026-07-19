import 'package:flutter/material.dart';
import '../../core/hvac/formulas/psychrometric.dart';
import '../../core/theme/app_colors.dart';

class HumidityCalculatorScreen extends StatefulWidget {
  const HumidityCalculatorScreen({super.key});

  @override
  State<HumidityCalculatorScreen> createState() => _HumidityCalculatorScreenState();
}

class _HumidityCalculatorScreenState extends State<HumidityCalculatorScreen> {
  final _tempController = TextEditingController(text: '25');
  final _rhController = TextEditingController(text: '60');
  double _w = double.nan;
  double _pv = double.nan;
  double _wb = double.nan;
  double _dp = double.nan;

  @override
  void initState() {
    super.initState();
    _tempController.addListener(_recalculate);
    _rhController.addListener(_recalculate);
    _recalculate();
  }

  @override
  void dispose() {
    _tempController.dispose();
    _rhController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final t = double.tryParse(_tempController.text);
    final rh = double.tryParse(_rhController.text);
    if (t == null || rh == null || rh <= 0 || rh > 100) {
      setState(() { _w = double.nan; _pv = double.nan; _wb = double.nan; _dp = double.nan; });
      return;
    }

    final svp = saturationVaporPressure(t);
    final pvapor = svp * rh / 100;
    final w = humidityRatio(t, rh);
    final wb = wetBulbTemperature(t, rh);
    final dp = dewPoint(t, rh);

    setState(() {
      _pv = pvapor;
      _w = w;
      _wb = wb;
      _dp = dp;
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
          'Độ Ẩm',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildInputCard(),
          const SizedBox(height: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ĐẦU VÀO', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 16),
          _buildField('Nhiệt độ không khí', _tempController, '°C'),
          const SizedBox(height: 12),
          _buildField('Độ ẩm tương đối (RH)', _rhController, '%', max: 100),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String unit, {double? max}) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        SizedBox(
          width: 120,
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
          const Text('KẾT QUẢ', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 16),
          _resultRow('Áp suất hơi nước', _pv.isNaN ? '—' : '${_pv.toStringAsFixed(2)} hPa', Icons.water_drop),
          const Divider(color: AppColors.divider),
          _resultRow('Tỷ lệ ẩm (W)', _w.isNaN ? '—' : '${_w.toStringAsFixed(4)} kg/kg', Icons.opacity),
          const Divider(color: AppColors.divider),
          _resultRow('Nhiệt độ bầu ướt', _wb.isNaN ? '—' : '${_wb.toStringAsFixed(1)} °C', Icons.thermostat),
          const Divider(color: AppColors.divider),
          _resultRow('Điểm sương', _dp.isNaN ? '—' : '${_dp.toStringAsFixed(1)} °C', Icons.ac_unit),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
