import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';

class LayerPanelDraggableNode extends StatelessWidget {
  final GeoLayersData entry;
  final Widget row;
  final VoidCallback onDragStarted;

  const LayerPanelDraggableNode({
    super.key,
    required this.entry,
    required this.row,
    required this.onDragStarted,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<String>(
      data: entry.id,
      onDragStarted: onDragStarted,
      maxSimultaneousDrags: 1,
      feedback: _LayerDragFeedback(title: entry.title),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: row,
      ),
      child: row,
    );
  }
}

class _LayerDragFeedback extends StatelessWidget {
  final String title;

  const _LayerDragFeedback({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Opacity(
        opacity: 0.96,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade700,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}