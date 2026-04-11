import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/panels/docking/dock_panel_data.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_splitter.dart';

class DockPanelRegion extends StatelessWidget {
  final List<DockPanelData> groups;
  final DockArea area;
  final double extent;
  final Widget Function(DockPanelData group, bool isFloating) buildGroupCard;

  final VoidCallback onExtentResizeStart;
  final VoidCallback onExtentResizeEnd;
  final ValueChanged<double> onExtentResize;

  final VoidCallback onWeightResizeStart;
  final VoidCallback onWeightResizeEnd;
  final void Function(
      int leadingIndex,
      double deltaPixels,
      double totalPixels,
      ) onWeightResize;

  const DockPanelRegion({
    super.key,
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

  bool get _isSideArea => area == DockArea.left || area == DockArea.right;

  bool get _isLeft => area == DockArea.left;

  bool get _isTop => area == DockArea.top;

  MouseCursor get _resizeCursor => _isSideArea
      ? SystemMouseCursors.resizeLeftRight
      : SystemMouseCursors.resizeUpDown;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: _isSideArea ? extent : null,
      height: _isSideArea ? null : extent,
      child: Stack(
        children: [
          Positioned.fill(
            child: _DockPanelWeightedGroups(
              groups: groups,
              area: area,
              buildGroupCard: (group) => buildGroupCard(group, false),
              onResizeWeightsStart: onWeightResizeStart,
              onResizeWeightsEnd: onWeightResizeEnd,
              onResizeWeights: onWeightResize,
            ),
          ),
          _DockRegionResizeHandle(
            area: area,
            cursor: _resizeCursor,
            onResizeStart: onExtentResizeStart,
            onResizeEnd: onExtentResizeEnd,
            onResize: onExtentResize,
            isLeft: _isLeft,
            isTop: _isTop,
            isSideArea: _isSideArea,
          ),
        ],
      ),
    );
  }
}

class _DockPanelWeightedGroups extends StatelessWidget {
  final List<DockPanelData> groups;
  final DockArea area;

  final void Function(
      int leadingIndex,
      double deltaPixels,
      double totalPixels,
      ) onResizeWeights;

  final VoidCallback onResizeWeightsStart;
  final VoidCallback onResizeWeightsEnd;

  final Widget Function(DockPanelData group) buildGroupCard;

  const _DockPanelWeightedGroups({
    required this.groups,
    required this.area,
    required this.onResizeWeights,
    required this.onResizeWeightsStart,
    required this.onResizeWeightsEnd,
    required this.buildGroupCard,
  });

  bool get _isSideArea => area == DockArea.left || area == DockArea.right;

  Axis get _splitAxis => _isSideArea ? Axis.vertical : Axis.horizontal;

  Axis get _direction => _isSideArea ? Axis.vertical : Axis.horizontal;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalPixels =
        _isSideArea ? constraints.maxHeight : constraints.maxWidth;

        if (!totalPixels.isFinite || totalPixels <= 0) {
          return const SizedBox.shrink();
        }

        final totalWeight = groups.fold<double>(
          0.0,
              (sum, item) => sum + item.dockWeight,
        );

        final safeTotalWeight = totalWeight <= 0 ? 1.0 : totalWeight;
        final children = <Widget>[];

        for (var i = 0; i < groups.length; i++) {
          final group = groups[i];
          final shouldShrinkWrap = group.shrinkWrapOnMainAxis;

          final flex = math.max(
            1,
            ((group.dockWeight / safeTotalWeight) * 1000).round(),
          );

          final card = SizedBox(
            width: double.infinity,
            child: buildGroupCard(group),
          );

          children.add(
            shouldShrinkWrap
                ? card
                : Expanded(
              flex: flex,
              child: card,
            ),
          );

          if (i < groups.length - 1) {
            children.add(
              DockPanelSplitter(
                axis: _splitAxis,
                onPanStart: (_) => onResizeWeightsStart(),
                onPanUpdate: (details) {
                  final delta =
                  _isSideArea ? details.delta.dy : details.delta.dx;
                  onResizeWeights(i, delta, totalPixels);
                },
                onPanEnd: (_) => onResizeWeightsEnd(),
              ),
            );
          }
        }

        return Flex(
          direction: _direction,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }
}

class _DockRegionResizeHandle extends StatelessWidget {
  final DockArea area;
  final MouseCursor cursor;
  final VoidCallback onResizeStart;
  final VoidCallback onResizeEnd;
  final ValueChanged<double> onResize;
  final bool isLeft;
  final bool isTop;
  final bool isSideArea;

  const _DockRegionResizeHandle({
    required this.area,
    required this.cursor,
    required this.onResizeStart,
    required this.onResizeEnd,
    required this.onResize,
    required this.isLeft,
    required this.isTop,
    required this.isSideArea,
  });

  @override
  Widget build(BuildContext context) {
    if (isSideArea) {
      return Positioned(
        top: 0,
        bottom: 0,
        right: isLeft ? 0 : null,
        left: isLeft ? null : 0,
        width: 8,
        child: MouseRegion(
          cursor: cursor,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (_) => onResizeStart(),
            onPanUpdate: (details) => onResize(details.delta.dx),
            onPanEnd: (_) => onResizeEnd(),
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
      );
    }

    return Positioned(
      left: 0,
      right: 0,
      top: isTop ? null : 0,
      bottom: isTop ? 0 : null,
      height: 8,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) => onResizeStart(),
          onPanUpdate: (details) => onResize(details.delta.dy),
          onPanEnd: (_) => onResizeEnd(),
          child: const ColoredBox(color: Colors.transparent),
        ),
      ),
    );
  }
}