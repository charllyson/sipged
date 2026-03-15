import 'package:flutter/material.dart';
import 'package:sipged/_widgets/docking/dock_panel_dock_area.dart';
import 'package:sipged/_widgets/docking/dock_panel_types.dart';
import 'package:sipged/_widgets/docking/dock_panel_workspace_logic.dart';

class DockPanelDockedLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsets contentPadding;

  final List<DockPanelGroupData> leftGroups;
  final List<DockPanelGroupData> rightGroups;
  final List<DockPanelGroupData> topGroups;
  final List<DockPanelGroupData> bottomGroups;

  final double leftWidth;
  final double rightWidth;
  final double topHeight;
  final double bottomHeight;

  final DockCrossSpan leftSpan;
  final DockCrossSpan rightSpan;
  final DockCrossSpan topSpan;
  final DockCrossSpan bottomSpan;

  final Widget Function(DockPanelGroupData group, bool isFloating)
  buildGroupCard;

  final VoidCallback onSideExtentResizeStart;
  final VoidCallback onSideExtentResizeEnd;
  final void Function(DockArea area, double delta) onSideExtentResize;

  final VoidCallback onWeightResizeStart;
  final VoidCallback onWeightResizeEnd;
  final void Function(
      List<DockPanelGroupData> groups,
      int leadingIndex,
      double deltaPixels,
      double totalPixels,
      ) onWeightResize;

  const DockPanelDockedLayout({
    super.key,
    required this.child,
    required this.contentPadding,
    required this.leftGroups,
    required this.rightGroups,
    required this.topGroups,
    required this.bottomGroups,
    required this.leftWidth,
    required this.rightWidth,
    required this.topHeight,
    required this.bottomHeight,
    required this.leftSpan,
    required this.rightSpan,
    required this.topSpan,
    required this.bottomSpan,
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
    final hasLeft = leftGroups.isNotEmpty;
    final hasRight = rightGroups.isNotEmpty;
    final hasTop = topGroups.isNotEmpty;
    final hasBottom = bottomGroups.isNotEmpty;

    final allGroups = <DockPanelGroupData>[
      ...leftGroups,
      ...rightGroups,
      ...topGroups,
      ...bottomGroups,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final workspaceSize = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
        );

        final leftRect = DockPanelWorkspaceLogic.resolveDockRectForArea(
          area: DockArea.left,
          source: allGroups,
          workspaceSize: workspaceSize,
        );

        final rightRect = DockPanelWorkspaceLogic.resolveDockRectForArea(
          area: DockArea.right,
          source: allGroups,
          workspaceSize: workspaceSize,
        );

        final topRect = DockPanelWorkspaceLogic.resolveDockRectForArea(
          area: DockArea.top,
          source: allGroups,
          workspaceSize: workspaceSize,
        );

        final bottomRect = DockPanelWorkspaceLogic.resolveDockRectForArea(
          area: DockArea.bottom,
          source: allGroups,
          workspaceSize: workspaceSize,
        );

        final contentRect = DockPanelWorkspaceLogic.resolveContentRect(
          source: allGroups,
          workspaceSize: workspaceSize,
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
                  onExtentResize: (delta) =>
                      onSideExtentResize(DockArea.left, delta),
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
                  onExtentResize: (delta) =>
                      onSideExtentResize(DockArea.top, delta),
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
      },
    );
  }
}

class _SideDock extends StatelessWidget {
  final List<DockPanelGroupData> groups;
  final DockArea area;
  final double extent;
  final Widget Function(DockPanelGroupData group, bool isFloating)
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
                onPanUpdate: (details) {
                  onExtentResize(details.delta.dx);
                },
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
  final List<DockPanelGroupData> groups;
  final DockArea area;
  final double extent;
  final Widget Function(DockPanelGroupData group, bool isFloating)
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
                onPanUpdate: (details) {
                  onExtentResize(details.delta.dy);
                },
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