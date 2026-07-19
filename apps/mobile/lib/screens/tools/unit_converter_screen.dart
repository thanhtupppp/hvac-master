import 'package:flutter/material.dart';
import '../../core/hvac/units/units.dart' hide TemperatureDeltaUnit;
import '../../core/theme/app_colors.dart';

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
        items: [
          for (final u in [PowerUnit.hp, PowerUnit.btuHr, PowerUnit.kw, PowerUnit.ton])
            DropdownMenuItem<String>(
              value: _powerUnitToString(u),
              child: Text(PowerConverter.label(u), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
        onChanged: (val) {
          if (val != null) setState(() => _selectedPowerUnit = val);
        },
      );
    } else if (_tabController.index == 1) {
      return DropdownButton<String>(
        value: _selectedPressureUnit,
        dropdownColor: AppColors.bgSecondary,
        items: [
          for (final u in PressureConverter.common)
            DropdownMenuItem<String>(
              value: _pressureUnitToString(u),
              child: Text(PressureConverter.label(u), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
        onChanged: (val) {
          if (val != null) setState(() => _selectedPressureUnit = val);
        },
      );
    } else {
      return DropdownButton<String>(
        value: _selectedTempUnit,
        dropdownColor: AppColors.bgSecondary,
        items: [
          for (final u in TemperatureUnit.values)
            DropdownMenuItem<String>(
              value: _tempUnitToString(u),
              child: Text(TemperatureConverter.label(u), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
        onChanged: (val) {
          if (val != null) setState(() => _selectedTempUnit = val);
        },
      );
    }
  }

  Widget _buildPowerOutputs(Color accent) {
    final from = _powerUnitFromStr(_selectedPowerUnit);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        for (final u in [PowerUnit.hp, PowerUnit.btuHr, PowerUnit.kw, PowerUnit.ton, PowerUnit.w])
          if (u != from)
            _buildResultRow(PowerConverter.label(u), PowerConverter.convert(_inputValue, from, u).toStringAsFixed(3), accent),
      ],
    );
  }

  Widget _buildPressureOutputs(Color accent) {
    final from = _pressureUnitFromStr(_selectedPressureUnit);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        for (final u in PressureConverter.all)
          if (u != from)
            _buildResultRow('${PressureConverter.label(u)} (${PressureConverter.description(u)})', PressureConverter.convert(_inputValue, from, u).toStringAsFixed(3), accent),
      ],
    );
  }

  Widget _buildTempOutputs(Color accent) {
    final from = _tempUnitFromStr(_selectedTempUnit);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        for (final u in TemperatureUnit.values)
          if (u != from)
            _buildResultRow('${TemperatureConverter.label(u)} (${_tempLabel(u)})', TemperatureConverter.convert(_inputValue, from, u).toStringAsFixed(2), accent),
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
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
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

  String _powerUnitToString(PowerUnit u) {
    switch (u) {
      case PowerUnit.hp:     return 'HP';
      case PowerUnit.btuHr: return 'BTU/h';
      case PowerUnit.kw:    return 'kW';
      case PowerUnit.ton:   return 'Tons';
      case PowerUnit.w:     return 'W';
      case PowerUnit.mw:    return 'MW';
      case PowerUnit.kcalHr: return 'kcal/h';
    }
  }

  PowerUnit _powerUnitFromStr(String s) {
    switch (s) {
      case 'HP':     return PowerUnit.hp;
      case 'BTU/h': return PowerUnit.btuHr;
      case 'kW':    return PowerUnit.kw;
      case 'Tons':  return PowerUnit.ton;
      case 'W':     return PowerUnit.w;
      case 'MW':    return PowerUnit.mw;
      case 'kcal/h': return PowerUnit.kcalHr;
      default:       return PowerUnit.kw;
    }
  }

  String _tempUnitToString(TemperatureUnit u) {
    switch (u) {
      case TemperatureUnit.celsius:    return '°C';
      case TemperatureUnit.fahrenheit: return '°F';
      case TemperatureUnit.kelvin:    return 'K';
    }
  }

  TemperatureUnit _tempUnitFromStr(String s) {
    switch (s) {
      case '°C': return TemperatureUnit.celsius;
      case '°F': return TemperatureUnit.fahrenheit;
      case 'K':  return TemperatureUnit.kelvin;
      default:   return TemperatureUnit.celsius;
    }
  }

  String _tempLabel(TemperatureUnit u) {
    switch (u) {
      case TemperatureUnit.celsius:    return 'Độ Celsius';
      case TemperatureUnit.fahrenheit: return 'Độ Fahrenheit';
      case TemperatureUnit.kelvin:    return 'Độ Kelvin';
    }
  }

  String _pressureUnitToString(PressureUnit u) => PressureConverter.label(u);

  PressureUnit _pressureUnitFromStr(String s) {
    switch (s) {
      case 'Bar':    return PressureUnit.bar;
      case 'PSI':    return PressureUnit.psi;
      case 'kPa':    return PressureUnit.kpa;
      case 'MPa':    return PressureUnit.mpa;
      case 'inHg':   return PressureUnit.inhg;
      case 'mmHg':   return PressureUnit.mmhg;
      case 'inH₂O':  return PressureUnit.inh2o;
      case 'Pa':     return PressureUnit.pa;
      default:       return PressureUnit.bar;
    }
  }
}
