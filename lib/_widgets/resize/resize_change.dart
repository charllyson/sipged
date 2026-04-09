import 'package:flutter/material.dart';
import 'package:sipged/_widgets/buttons/float_action_button.dart';
import 'package:sipged/_widgets/resize/resize_handle.dart';

class ResizeChange extends StatefulWidget {
  const ResizeChange({
    super.key,
    required this.offset,
    required this.size,
    required this.selected,
    required this.onSelected,
    required this.onMoveLive,
    required this.onMoveEnd,
    required this.onResizeLive,
    required this.onResizeEnd,
    required this.onRemove,
    required this.child,
    this.contentKey,
    this.borderRadius = 8,
    this.showMoveButton = true,
    this.showRemoveButton = true,
    this.showResizeHandles = true,
    this.allowDiagonalResize = true,
    this.moveTooltip = 'Mover',
    this.removeTooltip = 'Remover',
    this.resizeTooltip = 'Redimensionar',
    this.moveIcon = Icons.open_with,
    this.removeIcon = Icons.close,
    this.handleSize = 20,
    this.handleIconSize = 12,
    this.actionButtonOffset = const EdgeInsets.all(8),
  });

  final Offset offset;
  final Size size;

  final bool selected;
  final VoidCallback onSelected;

  final ValueChanged<Rect> onMoveLive;
  final ValueChanged<Rect> onMoveEnd;

  final void Function(ResizeHandle handle, Rect rect) onResizeLive;
  final void Function(ResizeHandle handle, Rect rect) onResizeEnd;

  final VoidCallback onRemove;

  final Widget child;
  final Object? contentKey;

  final double borderRadius;

  final bool showMoveButton;
  final bool showRemoveButton;
  final bool showResizeHandles;
  final bool allowDiagonalResize;

  final String moveTooltip;
  final String removeTooltip;
  final String resizeTooltip;

  final IconData moveIcon;
  final IconData removeIcon;

  final double handleSize;
  final double handleIconSize;
  final EdgeInsets actionButtonOffset;

  @override
  State<ResizeChange> createState() => _ResizeChangeState();
}

class _ResizeChangeState extends State<ResizeChange> {
  bool _hovered = false;
  Rect? _dragRectStart;
  Rect? _resizeRectStart;

  bool get _showControls => _hovered || widget.selected;

  Rect get _currentRect => Rect.fromLTWH(
    widget.offset.dx,
    widget.offset.dy,
    widget.size.width,
    widget.size.height,
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
      tooltip: widget.resizeTooltip,
      icon: _iconForResizeHandle(handle),
      cursor: cursor,
      iconColor: primary,
      borderColor: primary.withValues(alpha: 0.55),
      borderHoverColor: primary.withValues(alpha: 0.95),
      backgroundColor: Colors.white.withValues(alpha: 0.96),
      hoverBackgroundColor: primary,
      size: widget.handleSize,
      iconSize: widget.handleIconSize,
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
                  borderRadius: BorderRadius.circular(widget.borderRadius),
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
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: RepaintBoundary(
                    child: widget.contentKey != null
                        ? KeyedSubtree(
                      key: ValueKey(widget.contentKey),
                      child: widget.child,
                    )
                        : widget.child,
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
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                    ),
                  ),
                ),
              ),
            if (_showControls && widget.showMoveButton)
              Positioned(
                top: widget.actionButtonOffset.top,
                left: widget.actionButtonOffset.left,
                child: FloatActionButton(
                  tooltip: widget.moveTooltip,
                  icon: widget.moveIcon,
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
            if (_showControls && widget.showRemoveButton)
              Positioned(
                top: widget.actionButtonOffset.top,
                right: widget.actionButtonOffset.right,
                child: FloatActionButton(
                  tooltip: widget.removeTooltip,
                  icon: widget.removeIcon,
                  cursor: SystemMouseCursors.click,
                  iconColor: Colors.black87,
                  borderColor: Colors.black.withValues(alpha: 0.10),
                  borderHoverColor: Colors.black.withValues(alpha: 0.18),
                  onTap: widget.onRemove,
                ),
              ),
            if (_showControls && widget.showResizeHandles) ...[
              if (widget.allowDiagonalResize)
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
              if (widget.allowDiagonalResize)
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
              if (widget.allowDiagonalResize)
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
              if (widget.allowDiagonalResize)
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