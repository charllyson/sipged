// lib/_widgets/layout/split_layout/horizontal_drag_divider.dart
import 'package:flutter/material.dart';

class HorizontalDragDivider extends StatelessWidget {
  const HorizontalDragDivider({
    super.key,
    required this.thickness,
    required this.background,
    required this.gripColor,
    this.borderColor,
    required this.onDrag,
  });

  final double thickness;
  final Color background;
  final Color gripColor;
  final Color? borderColor;
  final void Function(double dy) onDrag;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // 👈 melhora a área de clique
        onVerticalDragUpdate: (d) => onDrag(d.delta.dy),
        child: Container(
          height: thickness,
          color: background,
          child: Stack(
            children: [
              if (borderColor != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(height: 1, color: borderColor),
                ),
              if (borderColor != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(height: 1, color: borderColor),
                ),
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: gripColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
