import 'package:flutter/material.dart';

class ResizeHandle extends StatelessWidget {
  const ResizeHandle({
    super.key,
    required this.onDrag,
    required this.onDoubleTap,
  });

  static const double width = 8;

  final void Function(double dx) onDrag;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
        onDoubleTap: onDoubleTap,
      ),
    );
  }
}
