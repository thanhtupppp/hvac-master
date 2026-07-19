import 'package:flutter/material.dart';
import '../../core/hvac/models/enums.dart';
import '../../core/theme/app_colors.dart';

class AchCalculatorScreen extends StatefulWidget {
  const AchCalculatorScreen({super.key});

  @override
  State<AchCalculatorScreen> createState() => _AchCalculatorScreenState();
}

class _AchCalculatorScreenState extends State<AchCalculatorScreen> {
  final _lengthController = TextEditingController(text: '6');
  final _widthController = TextEditingController(text: '5');
  final _heightController = TextEditingController(text: '3');
  final _achController = TextEditingController(text: '6');
  final _cfmController = TextEditingController();

  bool _calcFromAch = true;
  UnitSystem _unit = UnitSystem.metric;

  @override
  void initState() {
    super.initState();
    _lengthController.addListener(_recalculate);
    _widthController.addListener(_recalculate);
    _heightController.addListener(_recalculate);
    _achController.addListener(_recalculate);
    _cfmController.addListener(_recalculate);
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _achController.dispose();
    _cfmController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final l = double.tryParse(_lengthController.text);
    final w = double.tryParse(_widthController.text);
    final h = double.tryParse(_heightController.text);
    if (l == null || w == null || h == null || l <= 0 || w <= 0 || h <= 0) return;

    final vol = l * w * h;

    if (_calcFromAch) {
      final ach = double.tryParse(_achController.text);
      if (ach == null || ach <= 0) return;
      final cfm = (ach * vol) / 60;
      _cfmController.text = cfm.toStringAsFixed(1);
    } else {
      final cfm = double.tryParse(_cfmController.text);
      if (cfm == null || cfm <= 0) return;
      final ach = (cfm * 60) / vol;
      _achController.text = ach.toStringAsFixed(1);
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tính ACH',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildModeToggle(),
          const SizedBox(height: 16),
          _buildInputCard(),
          const SizedBox(height: 16),
          _buildUnitToggle(),
          const SizedBox(height: 24),
          _buildResultCard(),
          const SizedBox(height: 24),
          _buildAchGuide(),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _calcFromAch = true; _recalculate(); }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _calcFromAch ? AppColors.bgCard : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Tính CFM từ ACH', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _calcFromAch = false; _recalculate(); }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_calcFromAch ? AppColors.bgCard : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Tính ACH từ CFM', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
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
          _buildField('Chiều dài phòng', _lengthController, 'm'),
          const SizedBox(height: 12),
          _buildField('Chiều rộng', _widthController, 'm'),
          const SizedBox(height: 12),
          _buildField('Chiều cao', _heightController, 'm'),
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),
          if (_calcFromAch)
            _buildField('ACH mục tiêu', _achController, 'lần/giờ')
          else
            _buildField('Lưu lượng CFM', _cfmController, 'CFM'),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String unit) {
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

  Widget _buildUnitToggle() {
    return Row(
      children: [
        const Text('Hệ đơn vị:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
    final l = double.tryParse(_lengthController.text) ?? 0;
    final w = double.tryParse(_widthController.text) ?? 0;
    final h = double.tryParse(_heightController.text) ?? 0;
    final vol = l * w * h;
    final ach = double.tryParse(_achController.text) ?? 0;
    final cfm = double.tryParse(_cfmController.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _buildResultRow('Thể tích phòng', '${vol.toStringAsFixed(1)} m³'),
          const SizedBox(height: 8),
          _buildResultRow('ACH', '${ach.toStringAsFixed(1)} lần/giờ'),
          const SizedBox(height: 8),
          _buildResultRow('Lưu lượng cần thiết', '${cfm.toStringAsFixed(1)} CFM'),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAchGuide() {
    final guides = [
      ('Phòng ngủ', '4–6 ACH'),
      ('Phòng khách', '4–8 ACH'),
      ('Nhà bếp', '15–25 ACH'),
      ('Phòng tắm', '8–12 ACH'),
      ('Phòng server', '15–30 ACH'),
    ];
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
          const Text('ACH THAM KHẢO THEO KHÔNG GIAN', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          for (final g in guides) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(g.$1, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text(g.$2, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
