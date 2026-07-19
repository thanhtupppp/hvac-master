import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MeasurementCards extends StatelessWidget {
  final ValueNotifier<double> tempNotifier;
  final ValueNotifier<double> pressureNotifier;
  final String tempUnitLabel;
  final String pressureUnitLabel;
  final String? Function(String) validateTemp;
  final String? Function(String) validatePressure;
  final ValueChanged<String> onTempSubmitted;
  final ValueChanged<String> onPressureSubmitted;
  final String Function(double) getTempDisplayValue;
  final String Function(double) getPressureDisplayValue;

  const MeasurementCards({
    super.key,
    required this.tempNotifier,
    required this.pressureNotifier,
    required this.tempUnitLabel,
    required this.pressureUnitLabel,
    required this.validateTemp,
    required this.validatePressure,
    required this.onTempSubmitted,
    required this.onPressureSubmitted,
    required this.getTempDisplayValue,
    required this.getPressureDisplayValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Digital Display 1: Pressure
        ValueListenableBuilder<double>(
          valueListenable: pressureNotifier,
          builder: (context, pressureVal, _) {
            return _DisplayCard(
              value: getPressureDisplayValue(pressureVal),
              unit: pressureVal.isNaN ? '' : pressureUnitLabel,
              onTap: () => _showInputDialog(
                context,
                title: 'Nhập áp suất',
                defaultValue: pressureVal.isNaN ? '' : getPressureDisplayValue(pressureVal),
                validator: validatePressure,
                onSubmitted: onPressureSubmitted,
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Digital Display 2: Temperature
        ValueListenableBuilder<double>(
          valueListenable: tempNotifier,
          builder: (context, tempVal, _) {
            return _DisplayCard(
              value: tempVal.isNaN ? 'N/A' : getTempDisplayValue(tempVal),
              unit: tempVal.isNaN ? '' : tempUnitLabel,
              onTap: () => _showInputDialog(
                context,
                title: 'Nhập nhiệt độ',
                defaultValue: tempVal.isNaN ? '' : getTempDisplayValue(tempVal),
                validator: validateTemp,
                onSubmitted: onTempSubmitted,
              ),
            );
          },
        ),
      ],
    );
  }

  void _showInputDialog(
    BuildContext context, {
    required String title,
    required String defaultValue,
    required String? Function(String) validator,
    required ValueChanged<String> onSubmitted,
  }) {
    showDialog(
      context: context,
      builder: (context) => _InputDialog(
        title: title,
        defaultValue: defaultValue,
        validator: validator,
        onSubmitted: onSubmitted,
      ),
    );
  }
}

class _DisplayCard extends StatelessWidget {
  final String value;
  final String unit;
  final VoidCallback onTap;

  const _DisplayCard({
    required this.value,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unit,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputDialog extends StatefulWidget {
  final String title;
  final String defaultValue;
  final String? Function(String) validator;
  final ValueChanged<String> onSubmitted;

  const _InputDialog({
    required this.title,
    required this.defaultValue,
    required this.validator,
    required this.onSubmitted,
  });

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.defaultValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    final val = _controller.text.trim().replaceAll(',', '.');
    final err = widget.validator(val);
    if (err != null) {
      setState(() {
        _errorText = err;
      });
    } else {
      widget.onSubmitted(val);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _handleConfirm(),
        onChanged: (value) {
          if (_errorText != null) {
            setState(() {
              _errorText = widget.validator(value.trim().replaceAll(',', '.'));
            });
          }
        },
        decoration: InputDecoration(
          errorText: _errorText,
          errorMaxLines: 2,
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentPrimary)),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary),
          onPressed: _handleConfirm,
          child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
