import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';
import 'package:sipged/_widgets/docking/dock_panel_splitter.dart';

class DockPanelDockArea extends StatelessWidget {
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

  const DockPanelDockArea({
    super.key,
    required this.groups,
    required this.area,
    required this.onResizeWeights,
    required this.onResizeWeightsStart,
    required this.onResizeWeightsEnd,
    required this.buildGroupCard,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();

    final isSideArea = area == DockArea.left || area == DockArea.right;
    final splitAxis = isSideArea ? Axis.vertical : Axis.horizontal;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalPixels =
        isSideArea ? constraints.maxHeight : constraints.maxWidth;

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

          final flex = math.max(
            1,
            ((group.dockWeight / safeTotalWeight) * 1000).round(),
          );

          final card = RepaintBoundary(
            child: buildGroupCard(group),
          );

          final shouldShrinkWrap =
              group.shrinkWrapOnMainAxis || group.minimized;

          final groupChild = shouldShrinkWrap
              ? card
              : Expanded(
            flex: flex,
            child: card,
          );

          children.add(groupChild);

          if (i < groups.length - 1) {
            children.add(
              DockPanelSplitter(
                axis: splitAxis,
                onPanStart: (_) => onResizeWeightsStart(),
                onPanUpdate: (details) {
                  final delta =
                  isSideArea ? details.delta.dy : details.delta.dx;
                  onResizeWeights(i, delta, totalPixels);
                },
                onPanEnd: (_) => onResizeWeightsEnd(),
              ),
            );
          }
        }

        return Flex(
          direction: isSideArea ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }
}