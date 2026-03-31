import 'package:flutter/material.dart';
import 'package:sipged/_widgets/buttons/float_action_button.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_widgets.dart';
import 'package:sipged/_widgets/resize/resize_data.dart';

class ResizeChange extends StatefulWidget {
  const ResizeChange({
    super.key,
    required this.item,
    required this.dataVersion,
    required this.selected,
    required this.onSelected,
    required this.onMoveLive,
    required this.onMoveEnd,
    required this.onResizeLive,
    required this.onResizeEnd,
    required this.onRemove,
  });

  final ResizeData item;
  final int dataVersion;
  final bool selected;
  final VoidCallback onSelected;
  final ValueChanged<Rect> onMoveLive;
  final ValueChanged<Rect> onMoveEnd;
  final void Function(ResizeHandle handle, Rect rect) onResizeLive;
  final void Function(ResizeHandle handle, Rect rect) onResizeEnd;
  final VoidCallback onRemove;

  @override
  State<ResizeChange> createState() => _ResizeChangeState();
}

class _ResizeChangeState extends State<ResizeChange> {
  bool _hovered = false;
  Rect? _dragRectStart;
  Rect? _resizeRectStart;

  bool get _showControls => _hovered || widget.selected;

  Rect get _currentRect => Rect.fromLTWH(
    widget.item.offset.dx,
    widget.item.offset.dy,
    widget.item.size.width,
    widget.item.size.height,
  );

  void _onMoveStart() {
    _dragRectStart = _currentRect;
    widget.onSelected();
  }

  void _onMoveUpdate(DragUpdateDetails details) {
    final start = _dragRectStart ?? _currentRect;
    final next = start.shift(details.delta);
    _dragRectStart = next;
    widget.onMoveLive(next);
  }

  void _onMoveEnd() {
    final rect = _dragRectStart ?? _currentRect;
    _dragRectStart = null;
    widget.onMoveEnd(rect);
  }

  void _onResizeStart() {
    _resizeRectStart = _currentRect;
    widget.onSelected();
  }

  void _onResizeUpdate(
      ResizeHandle handle,
      DragUpdateDetails details,
      ) {
    final rect = _resizeRectStart ?? _currentRect;

    Rect next;
    switch (handle) {
      case ResizeHandle.right:
        next = Rect.fromLTRB(
          rect.left,
          rect.top,
          rect.right + details.delta.dx,
          rect.bottom,
        );
        break;

      case ResizeHandle.left:
        next = Rect.fromLTRB(
          rect.left + details.delta.dx,
          rect.top,
          rect.right,
          rect.bottom,
        );
        break;

      case ResizeHandle.bottom:
        next = Rect.fromLTRB(
          rect.left,
          rect.top,
          rect.right,
          rect.bottom + details.delta.dy,
        );
        break;

      case ResizeHandle.top:
        next = Rect.fromLTRB(
          rect.left,
          rect.top + details.delta.dy,
          rect.right,
          rect.bottom,
        );
        break;

      case ResizeHandle.topLeft:
        next = Rect.fromLTRB(
          rect.left + details.delta.dx,
          rect.top + details.delta.dy,
          rect.right,
          rect.bottom,
        );
        break;

      case ResizeHandle.topRight:
        next = Rect.fromLTRB(
          rect.left,
          rect.top + details.delta.dy,
          rect.right + details.delta.dx,
          rect.bottom,
        );
        break;

      case ResizeHandle.bottomLeft:
        next = Rect.fromLTRB(
          rect.left + details.delta.dx,
          rect.top,
          rect.right,
          rect.bottom + details.delta.dy,
        );
        break;

      case ResizeHandle.bottomRight:
        next = Rect.fromLTRB(
          rect.left,
          rect.top,
          rect.right + details.delta.dx,
          rect.bottom + details.delta.dy,
        );
        break;
    }

    _resizeRectStart = next;
    widget.onResizeLive(handle, next);
  }

  void _onResizeEnd(ResizeHandle handle) {
    final rect = _resizeRectStart ?? _currentRect;
    _resizeRectStart = null;
    widget.onResizeEnd(handle, rect);
  }

  IconData _iconForResizeHandle(ResizeHandle handle) {
    switch (handle) {
      case ResizeHandle.left:
        return Icons.arrow_back;
      case ResizeHandle.right:
        return Icons.arrow_forward;
      case ResizeHandle.top:
        return Icons.arrow_upward;
      case ResizeHandle.bottom:
        return Icons.arrow_downward;
      case ResizeHandle.topLeft:
        return Icons.north_west;
      case ResizeHandle.topRight:
        return Icons.north_east;
      case ResizeHandle.bottomLeft:
        return Icons.south_west;
      case ResizeHandle.bottomRight:
        return Icons.south_east;
    }
  }

  Widget _buildResizeHandle({
    required ResizeHandle handle,
    required Alignment alignment,
    required MouseCursor cursor,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    return FloatActionButton(
      tooltip: 'Redimensionar',
      icon: _iconForResizeHandle(handle),
      cursor: cursor,
      iconColor: primary,
      borderColor: primary.withValues(alpha: 0.55),
      borderHoverColor: primary.withValues(alpha: 0.95),
      backgroundColor: Colors.white.withValues(alpha: 0.96),
      hoverBackgroundColor: primary,
      size: 20,
      iconSize: 12,
      borderRadius: 6,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      shadowBlurRadius: 6,
      shadowOffset: const Offset(0, 1),
      alignment: alignment,
      onPanStart: (_) => _onResizeStart(),
      onPanUpdate: (d) => _onResizeUpdate(handle, d),
      onPanEnd: (_) => _onResizeEnd(handle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizeKey = ValueKey(
      '${widget.item.id}_${widget.item.type.name}_${widget.item.size.width}_${widget.item.size.height}_${widget.item.properties.hashCode}_${widget.dataVersion}',
    );

    final primary = Theme.of(context).colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => widget.onSelected(),
        onTap: widget.onSelected,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: widget.selected
                      ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: RepaintBoundary(
                    child: KeyedSubtree(
                      key: sizeKey,
                      child: GeoWorkspaceWidgets(
                        item: widget.item,
                        size: widget.item.size,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_showControls)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.selected
                            ? primary.withValues(alpha: 0.85)
                            : primary.withValues(alpha: 0.45),
                        width: widget.selected ? 2 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            if (_showControls)
              Positioned(
                top: 8,
                left: 8,
                child: FloatActionButton(
                  tooltip: 'Mover widget',
                  icon: Icons.open_with,
                  cursor: SystemMouseCursors.move,
                  iconColor: primary,
                  borderColor: primary.withValues(alpha: 0.22),
                  borderHoverColor: primary.withValues(alpha: 0.45),
                  onTap: widget.onSelected,
                  onPanStart: (_) => _onMoveStart(),
                  onPanUpdate: _onMoveUpdate,
                  onPanEnd: (_) => _onMoveEnd(),
                ),
              ),
            if (_showControls)
              Positioned(
                top: 8,
                right: 8,
                child: FloatActionButton(
                  tooltip: 'Remover',
                  icon: Icons.close,
                  cursor: SystemMouseCursors.click,
                  iconColor: Colors.black87,
                  borderColor: Colors.black.withValues(alpha: 0.10),
                  borderHoverColor: Colors.black.withValues(alpha: 0.18),
                  onTap: widget.onRemove,
                ),
              ),
            if (_showControls) ...[
              _buildResizeHandle(
                handle: ResizeHandle.topLeft,
                alignment: Alignment.topLeft,
                cursor: SystemMouseCursors.resizeUpLeftDownRight,
              ),
              _buildResizeHandle(
                handle: ResizeHandle.top,
                alignment: Alignment.topCenter,
                cursor: SystemMouseCursors.resizeUpDown,
              ),
              _buildResizeHandle(
                handle: ResizeHandle.topRight,
                alignment: Alignment.topRight,
                cursor: SystemMouseCursors.resizeUpRightDownLeft,
              ),
              _buildResizeHandle(
                handle: ResizeHandle.left,
                alignment: Alignment.centerLeft,
                cursor: SystemMouseCursors.resizeLeftRight,
              ),
              _buildResizeHandle(
                handle: ResizeHandle.right,
                alignment: Alignment.centerRight,
                cursor: SystemMouseCursors.resizeLeftRight,
              ),
              _buildResizeHandle(
                handle: ResizeHandle.bottomLeft,
                alignment: Alignment.bottomLeft,
                cursor: SystemMouseCursors.resizeUpRightDownLeft,
              ),
              _buildResizeHandle(
                handle: ResizeHandle.bottom,
                alignment: Alignment.bottomCenter,
                cursor: SystemMouseCursors.resizeUpDown,
              ),
              _buildResizeHandle(
                handle: ResizeHandle.bottomRight,
                alignment: Alignment.bottomRight,
                cursor: SystemMouseCursors.resizeUpLeftDownRight,
              ),
            ],
          ],
        ),
      ),
    );
  }
}