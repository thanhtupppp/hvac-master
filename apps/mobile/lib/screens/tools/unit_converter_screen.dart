import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/coolprop.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _inputController = TextEditingController(text: '1.0');
  double _inputValue = 1.0;

  // Selected source units
  String _selectedPowerUnit = 'HP';
  String _selectedPressureUnit = 'Bar';
  String _selectedTempUnit = '°C';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          // Reset defaults when tab changes
          _inputController.text = '1.0';
          _inputValue = 1.0;
          _selectedPowerUnit = 'HP';
          _selectedPressureUnit = 'Bar';
          _selectedTempUnit = '°C';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFE91E63);

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
          'Bộ đổi đơn vị HVAC',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'Công suất'),
                  Tab(text: 'Áp suất'),
                  Tab(text: 'Nhiệt độ'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Input Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
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
                          'GIÁ TRỊ NHẬP',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _inputController,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val);
                            if (parsed != null) {
                              setState(() => _inputValue = parsed);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Unit Selector Dropdown depending on active tab
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: _buildDropdownSelector(accentColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Output Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'KẾT QUẢ QUY ĐỔI',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Outputs List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPowerOutputs(accentColor),
                _buildPressureOutputs(accentColor),
                _buildTempOutputs(accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSelector(Color accentColor) {
    if (_tabController.index == 0) {
      return DropdownButton<String>(
        value: _selectedPowerUnit,
        dropdownColor: AppColors.bgSecondary,
        items: ['HP', 'BTU/h', 'kW', 'Tons'].map((String val) {
          return DropdownMenuItem<String>(
            value: val,
            child: Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) setState(() => _selectedPowerUnit = val);
        },
      );
    } else if (_tabController.index == 1) {
      return DropdownButton<String>(
        value: _selectedPressureUnit,
        dropdownColor: AppColors.bgSecondary,
        items: ['Bar', 'PSI', 'kPa', 'MPa'].map((String val) {
          return DropdownMenuItem<String>(
            value: val,
            child: Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) setState(() => _selectedPressureUnit = val);
        },
      );
    } else {
      return DropdownButton<String>(
        value: _selectedTempUnit,
        dropdownColor: AppColors.bgSecondary,
        items: ['°C', '°F', 'K'].map((String val) {
          return DropdownMenuItem<String>(
            value: val,
            child: Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) setState(() => _selectedTempUnit = val);
        },
      );
    }
  }

  Widget _buildPowerOutputs(Color accent) {
    // Outputs in: HP, BTU/h, kW, Tons
    final double btu = CoolProp.convertPower(_inputValue, _selectedPowerUnit, 'BTU/h');
    final double hp = CoolProp.convertPower(_inputValue, _selectedPowerUnit, 'HP');
    final double kw = CoolProp.convertPower(_inputValue, _selectedPowerUnit, 'kW');
    final double tons = CoolProp.convertPower(_inputValue, _selectedPowerUnit, 'Tons');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildResultRow('HP (Ngựa / Ngựa lạnh)', hp.toStringAsFixed(2), accent),
        _buildResultRow('BTU/h (British Thermal Unit)', btu.toStringAsFixed(1), accent),
        _buildResultRow('kW (Cooling capacity)', kw.toStringAsFixed(3), accent),
        _buildResultRow('Tons (Tấn lạnh)', tons.toStringAsFixed(2), accent),
      ],
    );
  }

  Widget _buildPressureOutputs(Color accent) {
    final double bar = CoolProp.convertPressure(_inputValue, _selectedPressureUnit, 'Bar');
    final double psi = CoolProp.convertPressure(_inputValue, _selectedPressureUnit, 'PSI');
    final double kpa = CoolProp.convertPressure(_inputValue, _selectedPressureUnit, 'kPa');
    final double mpa = CoolProp.convertPressure(_inputValue, _selectedPressureUnit, 'MPa');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildResultRow('Bar', bar.toStringAsFixed(3), accent),
        _buildResultRow('PSI (Pounds per square inch)', psi.toStringAsFixed(2), accent),
        _buildResultRow('kPa (Kilopascal)', kpa.toStringAsFixed(1), accent),
        _buildResultRow('MPa (Megapascal)', mpa.toStringAsFixed(4), accent),
      ],
    );
  }

  Widget _buildTempOutputs(Color accent) {
    // Outputs in: °C, °F, K
    final double celsius = CoolProp.convertTemperature(_inputValue, _selectedTempUnit, '°C');
    final double fahrenheit = CoolProp.convertTemperature(_inputValue, _selectedTempUnit, '°F');
    final double kelvin = CoolProp.convertTemperature(_inputValue, _selectedTempUnit, 'K');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildResultRow('°C (Độ Celsius)', celsius.toStringAsFixed(1), accent),
        _buildResultRow('°F (Độ Fahrenheit)', fahrenheit.toStringAsFixed(1), accent),
        _buildResultRow('K (Độ Kelvin)', kelvin.toStringAsFixed(1), accent),
      ],
    );
  }

  Widget _buildResultRow(String label, String value, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
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
