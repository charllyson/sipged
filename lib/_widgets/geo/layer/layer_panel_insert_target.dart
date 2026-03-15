import 'package:flutter/material.dart';

class LayerPanelInsertTarget extends StatelessWidget {
  final String? parentId;
  final int targetIndex;
  final int depth;
  final void Function(String draggedId, String? targetParentId, int targetIndex)?
  onDropItem;

  const LayerPanelInsertTarget({
    super.key,
    required this.parentId,
    required this.targetIndex,
    required this.depth,
    this.onDropItem,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data.trim().isNotEmpty,
      onAcceptWithDetails: (details) {
        onDropItem?.call(details.data, parentId, targetIndex);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: isHovering ? 8 : 4,
          margin: EdgeInsets.only(
            left: 22 + (depth * 16.0),
            right: 12,
          ),
          decoration: BoxDecoration(
            color: isHovering
                ? Colors.blue.withValues(alpha: 0.18)
                : Colors.transparent,
            border: Border(
              top: BorderSide(
                color: isHovering ? Colors.blue : Colors.transparent,
                width: isHovering ? 2 : 1,
              ),
            ),
          ),
        );
      },
    );
  }
}