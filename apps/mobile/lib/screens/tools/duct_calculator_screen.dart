import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/coolprop.dart';

class DuctCalculatorScreen extends StatefulWidget {
  const DuctCalculatorScreen({super.key});

  @override
  State<DuctCalculatorScreen> createState() => _DuctCalculatorScreenState();
}

class _DuctCalculatorScreenState extends State<DuctCalculatorScreen> {
  final _cfmController = TextEditingController(text: '1000');
  final _frictionController = TextEditingController(text: '0.1');
  final _sideAController = TextEditingController(text: '12');

  double _cfm = 1000.0;
  double _friction = 0.1;
  double _sideA = 12.0;

  double _roundDiameterInches = 0.0;
  double _sideBInches = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateDuct();
  }

  @override
  void dispose() {
    _cfmController.dispose();
    _frictionController.dispose();
    _sideAController.dispose();
    super.dispose();
  }

  void _calculateDuct() {
    setState(() {
      _roundDiameterInches = CoolProp.calculateDuctDiameter(_cfm, _friction);
      _sideBInches = CoolProp.calculateRectangularSideB(_roundDiameterInches, _sideA);
    });
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFA5);

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
          'Thiết kế ống gió (Duct Sizer)',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input Fields Card
            Container(
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
                    'THÔNG SỐ ĐẦU VÀO',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // CFM
                  _buildInputField(
                    label: 'Lưu lượng gió (Airflow)',
                    unit: 'CFM',
                    controller: _cfmController,
                    onChanged: (val) {
                      final double? d = double.tryParse(val);
                      if (d != null && d > 0) {
                        _cfm = d;
                        _calculateDuct();
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Friction rate
                  _buildInputField(
                    label: 'Độ tổn thất ma sát',
                    unit: 'in. wg/100ft',
                    controller: _frictionController,
                    onChanged: (val) {
                      final double? d = double.tryParse(val);
                      if (d != null && d > 0) {
                        _friction = d;
                        _calculateDuct();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Output Round Duct Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'ỐNG GIÓ TRÒN TƯƠNG ĐƯƠNG',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đường kính:',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_roundDiameterInches.toStringAsFixed(1)} inch',
                            style: const TextStyle(
                              color: accentColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(_roundDiameterInches * 25.4).toStringAsFixed(0)} mm',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Output Rectangular Duct Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'ỐNG GIÓ CHỮ NHẬT TƯƠNG ĐƯƠNG',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Adjustable side A
                  _buildInputField(
                    label: 'Cạnh A ống gió (Đã biết)',
                    unit: 'inch',
                    controller: _sideAController,
                    onChanged: (val) {
                      final double? d = double.tryParse(val);
                      if (d != null && d > 0) {
                        _sideA = d;
                        _calculateDuct();
                      }
                    },
                  ),
                  const Divider(color: AppColors.divider, height: 28),

                  // Calculated side B
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cạnh B ống gió tính ra:',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_sideBInches.toStringAsFixed(1)} inch',
                            style: const TextStyle(
                              color: accentColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(_sideBInches * 25.4).toStringAsFixed(0)} mm',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kích thước thực tế: ${_sideA.toStringAsFixed(0)} x ${_sideBInches.toStringAsFixed(0)} inch '
                    '(${(_sideA * 25.4).toStringAsFixed(0)} x ${(_sideBInches * 25.4).toStringAsFixed(0)} mm)',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
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
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              style: const TextStyle(color: Color(0xFF00BFA5), fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
