import 'package:flutter/material.dart';

class SaturationValueBox extends StatelessWidget {
  final double hue;
  final double saturation;
  final double value;
  final void Function(double saturation, double value) onChanged;

  const SaturationValueBox({super.key,
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  void _handleOffset(BoxConstraints constraints, Offset localPosition) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    final s = (localPosition.dx / width).clamp(0.0, 1.0);
    final v = (1.0 - (localPosition.dy / height)).clamp(0.0, 1.0);

    onChanged(s, v);
  }

  @override
  Widget build(BuildContext context) {
    final pureHue = HSVColor.fromAHSV(1, hue, 1, 1).toColor();

    return LayoutBuilder(
      builder: (context, constraints) {
        final handleLeft = saturation * constraints.maxWidth;
        final handleTop = (1 - value) * constraints.maxHeight;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (details) => _handleOffset(constraints, details.localPosition),
          onPanUpdate: (details) =>
              _handleOffset(constraints, details.localPosition),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, pureHue],
                      ),
                    ),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade500),
                  ),
                ),
              ),
              Positioned(
                left: handleLeft - 9,
                top: handleTop - 9,
                child: IgnorePointer(
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
