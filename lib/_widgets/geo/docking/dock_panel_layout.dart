import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_state.dart';
import 'package:sipged/_widgets/geo/docking/dock_panel_side.dart';
import 'package:sipged/_widgets/geo/docking/dock_panel_top_bottom.dart';

class DockPanelLayout extends StatelessWidget {
  final DockPanelState state;
  final Widget child;
  final EdgeInsets contentPadding;

  final Widget Function(DockPanelData group, bool isFloating) buildGroupCard;

  final VoidCallback onSideExtentResizeStart;
  final VoidCallback onSideExtentResizeEnd;
  final void Function(DockArea area, double delta) onSideExtentResize;

  final VoidCallback onWeightResizeStart;
  final VoidCallback onWeightResizeEnd;
  final void Function(
      List<DockPanelData> groups,
      int leadingIndex,
      double deltaPixels,
      double totalPixels,
      ) onWeightResize;

  const DockPanelLayout({
    super.key,
    required this.state,
    required this.child,
    required this.contentPadding,
    required this.buildGroupCard,
    required this.onSideExtentResizeStart,
    required this.onSideExtentResizeEnd,
    required this.onSideExtentResize,
    required this.onWeightResizeStart,
    required this.onWeightResizeEnd,
    required this.onWeightResize,
  });

  @override
  Widget build(BuildContext context) {
    final leftGroups = state.leftGroups;
    final rightGroups = state.rightGroups;
    final topGroups = state.topGroups;
    final bottomGroups = state.bottomGroups;

    final hasLeft = leftGroups.isNotEmpty;
    final hasRight = rightGroups.isNotEmpty;
    final hasTop = topGroups.isNotEmpty;
    final hasBottom = bottomGroups.isNotEmpty;

    final leftWidth = state.resolvedDockExtent(DockArea.left);
    final rightWidth = state.resolvedDockExtent(DockArea.right);
    final topHeight = state.resolvedDockExtent(DockArea.top);
    final bottomHeight = state.resolvedDockExtent(DockArea.bottom);

    final leftRect = state.resolveDockRectForArea(DockArea.left);
    final rightRect = state.resolveDockRectForArea(DockArea.right);
    final topRect = state.resolveDockRectForArea(DockArea.top);
    final bottomRect = state.resolveDockRectForArea(DockArea.bottom);

    final contentRect = state.resolveContentRect(
      contentPadding: contentPadding,
    );

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fromRect(
          rect: contentRect,
          child: RepaintBoundary(
            child: ClipRect(child: child),
          ),
        ),
        if (hasLeft && leftRect != null)
          Positioned.fromRect(
            rect: leftRect,
            child: DockPanelSide(
              groups: leftGroups,
              area: DockArea.left,
              extent: leftWidth,
              buildGroupCard: buildGroupCard,
              onExtentResizeStart: onSideExtentResizeStart,
              onExtentResizeEnd: onSideExtentResizeEnd,
              onExtentResize: (delta) => onSideExtentResize(DockArea.left, delta),
              onWeightResizeStart: onWeightResizeStart,
              onWeightResizeEnd: onWeightResizeEnd,
              onWeightResize: (leadingIndex, deltaPixels, totalPixels) {
                onWeightResize(
                  leftGroups,
                  leadingIndex,
                  deltaPixels,
                  totalPixels,
                );
              },
            ),
          ),
        if (hasRight && rightRect != null)
          Positioned.fromRect(
            rect: rightRect,
            child: DockPanelSide(
              groups: rightGroups,
              area: DockArea.right,
              extent: rightWidth,
              buildGroupCard: buildGroupCard,
              onExtentResizeStart: onSideExtentResizeStart,
              onExtentResizeEnd: onSideExtentResizeEnd,
              onExtentResize: (delta) => onSideExtentResize(DockArea.right, delta),
              onWeightResizeStart: onWeightResizeStart,
              onWeightResizeEnd: onWeightResizeEnd,
              onWeightResize: (leadingIndex, deltaPixels, totalPixels) {
                onWeightResize(
                  rightGroups,
                  leadingIndex,
                  deltaPixels,
                  totalPixels,
                );
              },
            ),
          ),
        if (hasTop && topRect != null)
          Positioned.fromRect(
            rect: topRect,
            child: DockPanelTopBottom(
              groups: topGroups,
              area: DockArea.top,
              extent: topHeight,
              buildGroupCard: buildGroupCard,
              onExtentResizeStart: onSideExtentResizeStart,
              onExtentResizeEnd: onSideExtentResizeEnd,
              onExtentResize: (delta) => onSideExtentResize(DockArea.top, delta),
              onWeightResizeStart: onWeightResizeStart,
              onWeightResizeEnd: onWeightResizeEnd,
              onWeightResize: (leadingIndex, deltaPixels, totalPixels) {
                onWeightResize(
                  topGroups,
                  leadingIndex,
                  deltaPixels,
                  totalPixels,
                );
              },
            ),
          ),
        if (hasBottom && bottomRect != null)
          Positioned.fromRect(
            rect: bottomRect,
            child: DockPanelTopBottom(
              groups: bottomGroups,
              area: DockArea.bottom,
              extent: bottomHeight,
              buildGroupCard: buildGroupCard,
              onExtentResizeStart: onSideExtentResizeStart,
              onExtentResizeEnd: onSideExtentResizeEnd,
              onExtentResize: (delta) => onSideExtentResize(DockArea.bottom, delta),
              onWeightResizeStart: onWeightResizeStart,
              onWeightResizeEnd: onWeightResizeEnd,
              onWeightResize: (leadingIndex, deltaPixels, totalPixels) {
                onWeightResize(
                  bottomGroups,
                  leadingIndex,
                  deltaPixels,
                  totalPixels,
                );
              },
            ),
          ),
      ],
    );
  }
}