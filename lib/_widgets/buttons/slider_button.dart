// lib/_widgets/buttons/slider_button.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SliderButton extends StatelessWidget {
  const SliderButton({
    super.key,
    required this.zoomListenable,
    required this.onZoomChanged,
    this.minZoom = 8,
    this.maxZoom = 48,
    this.step = 2,
    this.sliderHeight = 130,
    this.buttonWidth = 33,
    this.buttonHeight = 33,
    this.borderRadius = 8,
    this.backgroundColor = Colors.black38,
    this.iconColor = Colors.white,
    this.disabledIconColor = const Color(0x77FFFFFF),
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0x55FFFFFF),
    this.thumbColor = Colors.white,
  });

  final ValueListenable<double> zoomListenable;
  final ValueChanged<double> onZoomChanged;

  final double minZoom;
  final double maxZoom;
  final double step;

  final double sliderHeight;
  final double buttonWidth;
  final double buttonHeight;
  final double borderRadius;

  final Color backgroundColor;
  final Color iconColor;
  final Color disabledIconColor;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;

  double _clampZoom(double value) {
    return value.clamp(minZoom, maxZoom).toDouble();
  }

  double _normalizedFromZoom(double zoom) {
    if (maxZoom <= minZoom) return 0;

    return ((zoom - minZoom) / (maxZoom - minZoom)).clamp(0.0, 1.0);
  }

  double _zoomFromNormalized(double normalized) {
    final value = minZoom + ((maxZoom - minZoom) * normalized);
    return _clampZoom(value);
  }

  void _increase(double currentZoom) {
    onZoomChanged(_clampZoom(currentZoom + step));
  }

  void _decrease(double currentZoom) {
    onZoomChanged(_clampZoom(currentZoom - step));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: zoomListenable,
      builder: (context, zoom, _) {
        final currentZoom = _clampZoom(zoom);
        final normalizedValue = _normalizedFromZoom(currentZoom);

        final canIncrease = currentZoom < maxZoom;
        final canDecrease = currentZoom > minZoom;

        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ZoomContainerButton(
                icon: Icons.add_rounded,
                tooltip: 'Aproximar',
                width: buttonWidth,
                height: buttonHeight,
                backgroundColor: backgroundColor,
                iconColor: canIncrease ? iconColor : disabledIconColor,
                onPressed: canIncrease ? () => _increase(currentZoom) : null,
              ),
              Container(
                width: buttonWidth,
                height: sliderHeight,
                color: backgroundColor,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      activeTrackColor: activeColor,
                      inactiveTrackColor: inactiveColor,
                      thumbColor: thumbColor,
                      overlayColor: thumbColor.withValues(alpha: 0.16),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      tickMarkShape: SliderTickMarkShape.noTickMark,
                    ),
                    child: Slider(
                      min: 0,
                      max: 1,
                      value: normalizedValue,
                      onChanged: (value) {
                        onZoomChanged(_zoomFromNormalized(value));
                      },
                    ),
                  ),
                ),
              ),
              _ZoomContainerButton(
                icon: Icons.remove_rounded,
                tooltip: 'Afastar',
                width: buttonWidth,
                height: buttonHeight,
                backgroundColor: backgroundColor,
                iconColor: canDecrease ? iconColor : disabledIconColor,
                onPressed: canDecrease ? () => _decrease(currentZoom) : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ZoomContainerButton extends StatelessWidget {
  const _ZoomContainerButton({
    required this.icon,
    required this.tooltip,
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.iconColor,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: backgroundColor,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: width,
            height: height,
            child: Icon(
              icon,
              size: 22,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}