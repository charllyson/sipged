import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_item_data.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_types.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_widget_renderer.dart';
import 'package:sipged/_widgets/geo/workspace/workspace_close_button.dart';
import 'package:sipged/_widgets/geo/workspace/workspace_overlay_button.dart';
import 'package:sipged/_widgets/geo/workspace/workspace_resize_handle.dart';

class GeoWorkspaceDashboardItem extends StatefulWidget {
  const GeoWorkspaceDashboardItem({
    super.key,
    required this.item,
    required this.featuresByLayer,
    required this.selected,
    required this.onSelected,
    required this.onMoveLive,
    required this.onMoveEnd,
    required this.onResizeLive,
    required this.onResizeEnd,
    required this.onRemove,
  });

  final GeoWorkspaceItemData item;
  final Map<String, List<GeoFeatureData>> featuresByLayer;
  final bool selected;
  final VoidCallback onSelected;
  final ValueChanged<Rect> onMoveLive;
  final ValueChanged<Rect> onMoveEnd;
  final void Function(GeoWorkspaceResizeHandle handle, Rect rect) onResizeLive;
  final void Function(GeoWorkspaceResizeHandle handle, Rect rect) onResizeEnd;
  final VoidCallback onRemove;

  @override
  State<GeoWorkspaceDashboardItem> createState() =>
      _GeoWorkspaceDashboardItemState();
}

class _GeoWorkspaceDashboardItemState extends State<GeoWorkspaceDashboardItem> {
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
      GeoWorkspaceResizeHandle handle,
      DragUpdateDetails details,
      ) {
    final rect = _resizeRectStart ?? _currentRect;

    Rect next;
    switch (handle) {
      case GeoWorkspaceResizeHandle.right:
        next = Rect.fromLTRB(
          rect.left,
          rect.top,
          rect.right + details.delta.dx,
          rect.bottom,
        );
        break;
      case GeoWorkspaceResizeHandle.left:
        next = Rect.fromLTRB(
          rect.left + details.delta.dx,
          rect.top,
          rect.right,
          rect.bottom,
        );
        break;
      case GeoWorkspaceResizeHandle.bottom:
        next = Rect.fromLTRB(
          rect.left,
          rect.top,
          rect.right,
          rect.bottom + details.delta.dy,
        );
        break;
      case GeoWorkspaceResizeHandle.top:
        next = Rect.fromLTRB(
          rect.left,
          rect.top + details.delta.dy,
          rect.right,
          rect.bottom,
        );
        break;
      case GeoWorkspaceResizeHandle.topLeft:
        next = Rect.fromLTRB(
          rect.left + details.delta.dx,
          rect.top + details.delta.dy,
          rect.right,
          rect.bottom,
        );
        break;
      case GeoWorkspaceResizeHandle.topRight:
        next = Rect.fromLTRB(
          rect.left,
          rect.top + details.delta.dy,
          rect.right + details.delta.dx,
          rect.bottom,
        );
        break;
      case GeoWorkspaceResizeHandle.bottomLeft:
        next = Rect.fromLTRB(
          rect.left + details.delta.dx,
          rect.top,
          rect.right,
          rect.bottom + details.delta.dy,
        );
        break;
      case GeoWorkspaceResizeHandle.bottomRight:
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

  void _onResizeEnd(GeoWorkspaceResizeHandle handle) {
    final rect = _resizeRectStart ?? _currentRect;
    _resizeRectStart = null;
    widget.onResizeEnd(handle, rect);
  }

  @override
  Widget build(BuildContext context) {
    final sizeKey = ValueKey(
      '${widget.item.id}_${widget.item.type.name}_${widget.item.size.width}_${widget.item.size.height}_${widget.item.properties.hashCode}',
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
                      child: GeoWorkspaceWidgetRenderer(
                        item: widget.item,
                        size: widget.item.size,
                        featuresByLayer: widget.featuresByLayer,
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
                child: WorkspaceOverlayButton(
                  tooltip: 'Mover widget',
                  icon: Icons.open_with,
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
                child: WorkspaceCloseButton(
                  onPressed: widget.onRemove,
                ),
              ),
            if (_showControls) ...[
              WorkspaceResizeHandle(
                handle: GeoWorkspaceResizeHandle.topLeft,
                alignment: Alignment.topLeft,
                cursor: SystemMouseCursors.resizeUpLeftDownRight,
                onPanStart: (_) => _onResizeStart(),
                onPanUpdate: (d) =>
                    _onResizeUpdate(GeoWorkspaceResizeHandle.topLeft, d),
                onPanEnd: (_) => _onResizeEnd(GeoWorkspaceResizeHandle.topLeft),
              ),
              WorkspaceResizeHandle(
                handle: GeoWorkspaceResizeHandle.top,
                alignment: Alignment.topCenter,
                cursor: SystemMouseCursors.resizeUpDown,
                onPanStart: (_) => _onResizeStart(),
                onPanUpdate: (d) =>
                    _onResizeUpdate(GeoWorkspaceResizeHandle.top, d),
                onPanEnd: (_) => _onResizeEnd(GeoWorkspaceResizeHandle.top),
              ),
              WorkspaceResizeHandle(
                handle: GeoWorkspaceResizeHandle.topRight,
                alignment: Alignment.topRight,
                cursor: SystemMouseCursors.resizeUpRightDownLeft,
                onPanStart: (_) => _onResizeStart(),
                onPanUpdate: (d) =>
                    _onResizeUpdate(GeoWorkspaceResizeHandle.topRight, d),
                onPanEnd: (_) =>
                    _onResizeEnd(GeoWorkspaceResizeHandle.topRight),
              ),
              WorkspaceResizeHandle(
                handle: GeoWorkspaceResizeHandle.left,
                alignment: Alignment.centerLeft,
                cursor: SystemMouseCursors.resizeLeftRight,
                onPanStart: (_) => _onResizeStart(),
                onPanUpdate: (d) =>
                    _onResizeUpdate(GeoWorkspaceResizeHandle.left, d),
                onPanEnd: (_) => _onResizeEnd(GeoWorkspaceResizeHandle.left),
              ),
              WorkspaceResizeHandle(
                handle: GeoWorkspaceResizeHandle.right,
                alignment: Alignment.centerRight,
                cursor: SystemMouseCursors.resizeLeftRight,
                onPanStart: (_) => _onResizeStart(),
                onPanUpdate: (d) =>
                    _onResizeUpdate(GeoWorkspaceResizeHandle.right, d),
                onPanEnd: (_) => _onResizeEnd(GeoWorkspaceResizeHandle.right),
              ),
              WorkspaceResizeHandle(
                handle: GeoWorkspaceResizeHandle.bottomLeft,
                alignment: Alignment.bottomLeft,
                cursor: SystemMouseCursors.resizeUpRightDownLeft,
                onPanStart: (_) => _onResizeStart(),
                onPanUpdate: (d) =>
                    _onResizeUpdate(GeoWorkspaceResizeHandle.bottomLeft, d),
                onPanEnd: (_) =>
                    _onResizeEnd(GeoWorkspaceResizeHandle.bottomLeft),
              ),
              WorkspaceResizeHandle(
                handle: GeoWorkspaceResizeHandle.bottom,
                alignment: Alignment.bottomCenter,
                cursor: SystemMouseCursors.resizeUpDown,
                onPanStart: (_) => _onResizeStart(),
                onPanUpdate: (d) =>
                    _onResizeUpdate(GeoWorkspaceResizeHandle.bottom, d),
                onPanEnd: (_) => _onResizeEnd(GeoWorkspaceResizeHandle.bottom),
              ),
              WorkspaceResizeHandle(
                handle: GeoWorkspaceResizeHandle.bottomRight,
                alignment: Alignment.bottomRight,
                cursor: SystemMouseCursors.resizeUpLeftDownRight,
                onPanStart: (_) => _onResizeStart(),
                onPanUpdate: (d) =>
                    _onResizeUpdate(GeoWorkspaceResizeHandle.bottomRight, d),
                onPanEnd: (_) =>
                    _onResizeEnd(GeoWorkspaceResizeHandle.bottomRight),
              ),
            ],
          ],
        ),
      ),
    );
  }
}