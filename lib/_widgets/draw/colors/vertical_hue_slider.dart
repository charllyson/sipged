import 'package:flutter/material.dart';

class VerticalHueSlider extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;

  const VerticalHueSlider({super.key,
    required this.hue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final handleTop = (hue / 360.0) * constraints.maxHeight;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (details) {
            final t = (details.localPosition.dy / constraints.maxHeight)
                .clamp(0.0, 1.0);
            onChanged(t * 360.0);
          },
          onPanUpdate: (details) {
            final t = (details.localPosition.dy / constraints.maxHeight)
                .clamp(0.0, 1.0);
            onChanged(t * 360.0);
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFF0000),
                          Color(0xFFFFFF00),
                          Color(0xFF00FF00),
                          Color(0xFF00FFFF),
                          Color(0xFF0000FF),
                          Color(0xFFFF00FF),
                          Color(0xFFFF0000),
                        ],
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
                top: handleTop - 2,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black54),
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
