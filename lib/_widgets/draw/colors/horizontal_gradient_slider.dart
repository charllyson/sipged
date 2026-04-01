import 'package:flutter/material.dart';
import 'package:sipged/_widgets/draw/colors/checkerboard_painter.dart';

class HorizontalGradientSlider extends StatelessWidget {
  final double value;
  final Gradient gradient;
  final ValueChanged<double> onChanged;
  final bool checkerboard;

  const HorizontalGradientSlider({super.key,
    required this.value,
    required this.gradient,
    required this.onChanged,
    this.checkerboard = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final handleLeft = value * constraints.maxWidth;

        void update(Offset localPosition) {
          final t = (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
          onChanged(t);
        }

        return SizedBox(
          height: 24,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (details) => update(details.localPosition),
            onPanUpdate: (details) => update(details.localPosition),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (checkerboard) CustomPaint(
                          painter: CheckerboardPainter(),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: gradient,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.grey.shade500),
                    ),
                  ),
                ),
                Positioned(
                  left: handleLeft - 6,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.black54),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
