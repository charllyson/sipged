// lib/_widgets/layout/split_layout/vertical_drag_divider.dart
import 'package:flutter/material.dart';

class VerticalDragDivider extends StatelessWidget {
  const VerticalDragDivider({
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
  final void Function(double dx) onDrag;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // 👈 idem, mais fácil de pegar
        onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
        child: Container(
          width: thickness,
          color: background,
          child: Stack(
            children: [
              if (borderColor != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(width: 1, color: borderColor),
                ),
              if (borderColor != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(width: 1, color: borderColor),
                ),
              Center(
                child: Container(
                  width: 4,
                  height: 48,
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
