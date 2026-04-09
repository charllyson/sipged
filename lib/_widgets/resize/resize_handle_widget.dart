import 'package:flutter/material.dart';

class ResizeHandleWidget extends StatelessWidget {
  final VoidCallback onPanStart;
  final void Function(DragUpdateDetails details) onPanUpdate;
  final void Function(DragEndDetails details) onPanEnd;

  const ResizeHandleWidget({
    super.key,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: GestureDetector(
        onPanStart: (_) => onPanStart(),
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Icon(
            Icons.drag_handle,
            size: 18,
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.70),
          ),
        ),
      ),
    );
  }
}