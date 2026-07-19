import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../pt_calculator_controller.dart';

class PressureRuler extends StatefulWidget {
  final PTCalculatorController controller;

  const PressureRuler({
    super.key,
    required this.controller,
  });

  @override
  State<PressureRuler> createState() => _PressureRulerState();
}

class _PressureRulerState extends State<PressureRuler> {
  late final ScrollController _scrollController;
  bool _isProgrammaticScroll = false;

  final double _minTemp = -70.0;
  final double _maxTemp = 70.0;
  final double _itemHeight = 15.0; // Height per 1°C

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onRulerScroll);

    // Listen to tempNotifier to sync the scroll position
    widget.controller.tempNotifier.addListener(_onTempNotifierChanged);

    // Initial sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncRulerToTemp();
    });
  }

  @override
  void didUpdateWidget(PressureRuler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.tempNotifier.removeListener(_onTempNotifierChanged);
      widget.controller.tempNotifier.addListener(_onTempNotifierChanged);
      _syncRulerToTemp();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    widget.controller.tempNotifier.removeListener(_onTempNotifierChanged);
    super.dispose();
  }

  void _onTempNotifierChanged() {
    if (!_isProgrammaticScroll) {
      _syncRulerToTemp();
    }
  }

  void _onRulerScroll() {
    if (!_scrollController.hasClients || _isProgrammaticScroll) return;

    final double offset = _scrollController.offset;
    final double tempDiff = offset / _itemHeight;
    final double tempCelsius = widget.controller.reverseSlider ? (_maxTemp - tempDiff) : (_minTemp + tempDiff);
    final double clamped = tempCelsius.clamp(_minTemp, _maxTemp);

    // Debounce/avoid redundant calculations if change is extremely small (< 0.05°C)
    if ((clamped - widget.controller.tempNotifier.value).abs() < 0.05) return;

    // Use a temporary flag to prevent triggering listener callback
    _isProgrammaticScroll = true;
    widget.controller.tempNotifier.value = clamped;
    widget.controller.calculateValues(fromTemp: true);
    _isProgrammaticScroll = false;
  }

  void _syncRulerToTemp() {
    if (!_scrollController.hasClients || widget.controller.tempNotifier.value.isNaN) return;

    final double tempDiff = widget.controller.reverseSlider
        ? (_maxTemp - widget.controller.tempNotifier.value)
        : (widget.controller.tempNotifier.value - _minTemp);
    final double targetOffset = tempDiff * _itemHeight;

    _isProgrammaticScroll = true;
    _scrollController.jumpTo(targetOffset.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    ));
    _isProgrammaticScroll = false;
  }

  @override
  Widget build(BuildContext context) {

    return LayoutBuilder(
      builder: (context, constraints) {
        final rulerHeight = constraints.maxHeight;
        final halfRulerHeight = rulerHeight / 2;

        // AnimatedBuilder listens to general config changes (units, reverse slider)
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final accentColor = widget.controller.refrigerant.color;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Scrollable ticks list
                  ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(vertical: halfRulerHeight - (_itemHeight / 2)),
                    itemCount: (_maxTemp - _minTemp).toInt() + 1,
                    itemExtent: _itemHeight,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    cacheExtent: 500,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final currentTemp = widget.controller.reverseSlider
                          ? (_maxTemp - index)
                          : (_minTemp + index);

                      // Technical Risk Correction: Round before modulo to prevent precision issues on double
                      final int tempInt = currentTemp.round();
                      final isMajorTemp = tempInt % 10 == 0;
                      final isMediumTemp = tempInt % 5 == 0;

                      // Saturation pressure at this temperature (read from lazy cache)
                      final double currentPress = widget.controller.getPressureForTemp(currentTemp);

                      return SizedBox(
                        height: _itemHeight,
                        child: Row(
                          children: [
                            // Left side: Pressure values
                            Expanded(
                              child: isMajorTemp
                                  ? Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        currentPress.isNaN ? '--' : currentPress.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 8),

                            // Center: Ticks
                            SizedBox(
                              width: 40,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 1,
                                    color: Colors.white10,
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          width: isMajorTemp ? 12 : (isMediumTemp ? 8 : 4),
                                          height: 1,
                                          color: Colors.white30,
                                        ),
                                        Container(
                                          width: isMajorTemp ? 12 : (isMediumTemp ? 8 : 4),
                                          height: 1,
                                          color: Colors.white30,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Right side: Temp values
                            Expanded(
                              child: isMajorTemp
                                  ? Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        widget.controller.tempUnit == '°C'
                                            ? currentTemp.toInt().toString()
                                            : ((currentTemp * 9 / 5) + 32).round().toString(),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Ruler top header indicators
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.controller.pressureUnit.toLowerCase()}${widget.controller.isGauge ? '(g)' : '(a)'}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.controller.tempUnit,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // Viewfinder overlay in the center
                  IgnorePointer(
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(width: 16, height: 1, color: accentColor),
                          Container(width: 16, height: 1, color: accentColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
