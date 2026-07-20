import 'package:flutter/material.dart';
import '../../core/hvac/thermo/thermo.dart';
import '../../core/theme/app_colors.dart';
import '../../models/refrigerant_model.dart';

const double kPsiPerBar = 14.5037738;

class SaturationTemperatureScreen extends StatefulWidget {
  const SaturationTemperatureScreen({super.key});

  @override
  State<SaturationTemperatureScreen> createState() =>
      _SaturationTemperatureScreenState();
}

class _SaturationTemperatureScreenState
    extends State<SaturationTemperatureScreen> {
  final _thermo = Thermodynamics();
  final _pressureController = TextEditingController(text: '200');
  String _pressureUnit = 'PSI';
  String _refrigerant = 'R410A';
  bool _isGauge = true;
  double _satTempC = double.nan;

  @override
  void initState() {
    super.initState();
    _pressureController.addListener(_recalculate);
    _recalculate();
  }

  @override
  void dispose() {
    _pressureController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final p = double.tryParse(_pressureController.text);
    if (p == null) {
      setState(() => _satTempC = double.nan);
      return;
    }
    final tempC = _thermo.getTempFromPressure(
      refrigerant: _refrigerant,
      pressure: p,
      pressureUnit: _pressureUnit,
      isGauge: _isGauge,
      isDew: false,
    );
    setState(() => _satTempC = tempC);
  }

  void _toggleUnit() {
    final p = double.tryParse(_pressureController.text) ?? 1.0;
    setState(() {
      if (_pressureUnit == 'PSI') {
        _pressureUnit = 'Bar';
        _pressureController.text = (p / kPsiPerBar).toStringAsFixed(2);
      } else {
        _pressureUnit = 'PSI';
        _pressureController.text = (p * kPsiPerBar).toStringAsFixed(1);
      }
      _recalculate();
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
          'Nhiệt độ Bão hòa',
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
          _buildRefrigerantSelector(),
          const SizedBox(height: 16),
          _buildPressureInput(),
          const SizedBox(height: 16),
          _buildGaugeToggle(),
          const SizedBox(height: 24),
          _buildResultCard(),
          const SizedBox(height: 24),
          _buildPTGuide(),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _refrigerant = val;
                _recalculate();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildPressureInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ÁP SUẤT',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _pressureController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              GestureDetector(
                onTap: _toggleUnit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    _pressureUnit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isGauge ? 'Gauge' : 'Absolute',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeToggle() {
    return Row(
      children: [
        const Text(
          'Kiểu đo:',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(width: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Gauge')),
            ButtonSegment(value: false, label: Text('Absolute')),
          ],
          selected: {_isGauge},
          onSelectionChanged: (s) => setState(() {
            _isGauge = s.first;
            _recalculate();
          }),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    final tempC = _satTempC;
    final isNan = tempC.isNaN;
    final tempF = isNan ? double.nan : (tempC * 9 / 5) + 32;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Text(
            'NHIỆT ĐỘ BÃO HÒA',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isNan ? '—' : '${tempC.toStringAsFixed(1)} °C',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isNan ? '—' : '${tempF.toStringAsFixed(1)} °F',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
            ),
          ),
          if (isNan) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Giá trị nằm ngoài phạm vi Antoine / CoolProp',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPTGuide() {
    final ref = defaultRefrigerants.firstWhere(
      (r) => r.name == _refrigerant,
      orElse: () => defaultRefrigerants.first,
    );
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
            'THÔNG TIN MÔI CHẤT',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('Loại', ref.typeClass),
          _infoRow('GWP', ref.gwp.toString()),
          _infoRow('ODP', ref.odp.toString()),
          _infoRow(
            'Nhiệt độ sôi (1 atm)',
            '${ref.boilingPoint.toStringAsFixed(1)} °C',
          ),
          _infoRow(
            'Nhiệt độ tới hạn',
            '${ref.criticalTemp.toStringAsFixed(1)} °C',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
