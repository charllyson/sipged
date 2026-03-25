import 'package:flutter/material.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_types.dart';

class WorkspaceResizeHandle extends StatefulWidget {
  const WorkspaceResizeHandle({
    super.key,
    required this.handle,
    required this.alignment,
    required this.cursor,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final GeoWorkspaceResizeHandle handle;
  final Alignment alignment;
  final MouseCursor cursor;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  @override
  State<WorkspaceResizeHandle> createState() => _WorkspaceResizeHandleState();
}

class _WorkspaceResizeHandleState extends State<WorkspaceResizeHandle> {
  bool _hovered = false;

  IconData _iconForHandle(GeoWorkspaceResizeHandle handle) {
    switch (handle) {
      case GeoWorkspaceResizeHandle.left:
        return Icons.arrow_back;
      case GeoWorkspaceResizeHandle.right:
        return Icons.arrow_forward;
      case GeoWorkspaceResizeHandle.top:
        return Icons.arrow_upward;
      case GeoWorkspaceResizeHandle.bottom:
        return Icons.arrow_downward;
      case GeoWorkspaceResizeHandle.topLeft:
        return Icons.north_west;
      case GeoWorkspaceResizeHandle.topRight:
        return Icons.north_east;
      case GeoWorkspaceResizeHandle.bottomLeft:
        return Icons.south_west;
      case GeoWorkspaceResizeHandle.bottomRight:
        return Icons.south_east;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hovered = _hovered;

    return Align(
      alignment: widget.alignment,
      child: MouseRegion(
        cursor: widget.cursor,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: widget.onPanStart,
          onPanUpdate: widget.onPanUpdate,
          onPanEnd: widget.onPanEnd,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: hovered
                  ? primary
                  : Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: primary.withValues(alpha: hovered ? 0.95 : 0.55),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              _iconForHandle(widget.handle),
              size: 12,
              color: hovered ? Colors.white : primary,
            ),
          ),
        ),
      ),
    );
  }
}