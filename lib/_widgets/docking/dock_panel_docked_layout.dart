import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_state.dart';
import 'package:sipged/_widgets/docking/dock_panel_dock_area.dart';

class DockPanelDockedLayout extends StatelessWidget {
  final DockPanelState state;
  final Widget child;
  final EdgeInsets contentPadding;

  final Widget Function(DockPanelData group, bool isFloating)
  buildGroupCard;

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

  const DockPanelDockedLayout({
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
            child: _SideDock(
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
            child: _SideDock(
              groups: rightGroups,
              area: DockArea.right,
              extent: rightWidth,
              buildGroupCard: buildGroupCard,
              onExtentResizeStart: onSideExtentResizeStart,
              onExtentResizeEnd: onSideExtentResizeEnd,
              onExtentResize: (delta) =>
                  onSideExtentResize(DockArea.right, delta),
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
            child: _TopBottomDock(
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
            child: _TopBottomDock(
              groups: bottomGroups,
              area: DockArea.bottom,
              extent: bottomHeight,
              buildGroupCard: buildGroupCard,
              onExtentResizeStart: onSideExtentResizeStart,
              onExtentResizeEnd: onSideExtentResizeEnd,
              onExtentResize: (delta) =>
                  onSideExtentResize(DockArea.bottom, delta),
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

class _SideDock extends StatelessWidget {
  final List<DockPanelData> groups;
  final DockArea area;
  final double extent;
  final Widget Function(DockPanelData group, bool isFloating)
  buildGroupCard;

  final VoidCallback onExtentResizeStart;
  final VoidCallback onExtentResizeEnd;
  final ValueChanged<double> onExtentResize;

  final VoidCallback onWeightResizeStart;
  final VoidCallback onWeightResizeEnd;
  final void Function(int leadingIndex, double deltaPixels, double totalPixels)
  onWeightResize;

  const _SideDock({
    required this.groups,
    required this.area,
    required this.extent,
    required this.buildGroupCard,
    required this.onExtentResizeStart,
    required this.onExtentResizeEnd,
    required this.onExtentResize,
    required this.onWeightResizeStart,
    required this.onWeightResizeEnd,
    required this.onWeightResize,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = area == DockArea.left;

    return SizedBox(
      width: extent,
      child: Stack(
        children: [
          Positioned.fill(
            child: DockPanelDockArea(
              groups: groups,
              area: area,
              buildGroupCard: (group) => buildGroupCard(group, false),
              onResizeWeightsStart: onWeightResizeStart,
              onResizeWeightsEnd: onWeightResizeEnd,
              onResizeWeights: onWeightResize,
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: isLeft ? 0 : null,
            left: isLeft ? null : 0,
            width: 8,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (_) => onExtentResizeStart(),
                onPanUpdate: (details) => onExtentResize(details.delta.dx),
                onPanEnd: (_) => onExtentResizeEnd(),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBottomDock extends StatelessWidget {
  final List<DockPanelData> groups;
  final DockArea area;
  final double extent;
  final Widget Function(DockPanelData group, bool isFloating)
  buildGroupCard;

  final VoidCallback onExtentResizeStart;
  final VoidCallback onExtentResizeEnd;
  final ValueChanged<double> onExtentResize;

  final VoidCallback onWeightResizeStart;
  final VoidCallback onWeightResizeEnd;
  final void Function(int leadingIndex, double deltaPixels, double totalPixels)
  onWeightResize;

  const _TopBottomDock({
    required this.groups,
    required this.area,
    required this.extent,
    required this.buildGroupCard,
    required this.onExtentResizeStart,
    required this.onExtentResizeEnd,
    required this.onExtentResize,
    required this.onWeightResizeStart,
    required this.onWeightResizeEnd,
    required this.onWeightResize,
  });

  @override
  Widget build(BuildContext context) {
    final isTop = area == DockArea.top;

    return SizedBox(
      height: extent,
      child: Stack(
        children: [
          Positioned.fill(
            child: DockPanelDockArea(
              groups: groups,
              area: area,
              buildGroupCard: (group) => buildGroupCard(group, false),
              onResizeWeightsStart: onWeightResizeStart,
              onResizeWeightsEnd: onWeightResizeEnd,
              onResizeWeights: onWeightResize,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: isTop ? null : 0,
            bottom: isTop ? 0 : null,
            height: 8,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeUpDown,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (_) => onExtentResizeStart(),
                onPanUpdate: (details) => onExtentResize(details.delta.dy),
                onPanEnd: (_) => onExtentResizeEnd(),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}