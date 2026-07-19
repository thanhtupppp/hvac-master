import 'package:flutter/material.dart';
import '../../core/hvac/formulas/psychrometric.dart';
import '../../core/theme/app_colors.dart';

class DewPointCalculatorScreen extends StatefulWidget {
  const DewPointCalculatorScreen({super.key});

  @override
  State<DewPointCalculatorScreen> createState() => _DewPointCalculatorScreenState();
}

class _DewPointCalculatorScreenState extends State<DewPointCalculatorScreen> {
  final _tempController = TextEditingController(text: '25');
  final _rhController = TextEditingController(text: '60');
  double _dewPoint = double.nan;

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
    if (t == null || rh == null) {
      setState(() { _dewPoint = double.nan; });
      return;
    }
    final dp = dewPoint(t, rh);
    setState(() { _dewPoint = dp; });
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
          'Điểm Sương',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildInputCard(),
          const SizedBox(height: 24),
          _buildResultCard(),
          const SizedBox(height: 24),
          _buildRhGuide(),
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
    final dp = _dewPoint;
    final isNan = dp.isNaN;
    final dpF = isNan ? double.nan : (dp * 9 / 5) + 32;
    final rating = _dpRating(dp);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Text('ĐIỂM SƯƠNG', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 16),
          Text(
            isNan ? '—' : '${dp.toStringAsFixed(1)} °C',
            style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            isNan ? '—' : '${dpF.toStringAsFixed(1)} °F',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _dpColor(dp).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info, color: _dpColor(dp), size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(rating, style: TextStyle(color: _dpColor(dp), fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRhGuide() {
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
          const Text('THAM KHẢO ĐIỂM SƯƠNG', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          _refRow('< 10 °C', 'Thoải mái — ít ngưng tụ'),
          _refRow('10–16 °C', 'Bình thường — có thể hơi ẩm'),
          _refRow('16–20 °C', 'Cao — có nguy cơ ngưng tụ'),
          _refRow('> 20 °C', 'Rất cao — cần giảm độ ẩm hoặc tăng nhiệt'),
          const SizedBox(height: 12),
          const Text('Điểm sương = nhiệt độ mà không khí cần làm lạnh để đạt RH 100%.', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _refRow(String range, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(range, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Flexible(child: Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  String _dpRating(double dp) {
    if (dp.isNaN) return 'Giá trị không hợp lệ';
    if (dp < 10) return 'Thoải mái — không khí khô ráo';
    if (dp < 16) return 'Bình thường — có thể cảm thấy hơi ẩm';
    if (dp < 20) return 'Cao — nguy cơ ngưng tụ trên bề mặt lạnh';
    return 'Rất cao — cần xử lý ẩm';
  }

  Color _dpColor(double dp) {
    if (dp.isNaN) return AppColors.textMuted;
    if (dp < 10) return Colors.green;
    if (dp < 16) return Colors.white;
    if (dp < 20) return Colors.orange;
    return Colors.red;
  }
}
