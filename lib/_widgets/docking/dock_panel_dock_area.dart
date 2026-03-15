
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/docking/dock_panel_group_card.dart';
import 'package:sipged/_widgets/docking/dock_panel_splitter.dart';
import 'package:sipged/_widgets/docking/dock_panel_types.dart';

class DockPanelDockArea extends StatelessWidget {
  final List<DockPanelGroupData> groups;
  final DockArea area;
  final void Function(int leadingIndex, double deltaPixels, double totalPixels)
  onResizeWeights;
  final VoidCallback onResizeWeightsStart;
  final VoidCallback onResizeWeightsEnd;

  final Widget Function(DockPanelGroupData group) buildGroupCard;

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

        final totalWeight = groups.fold<double>(
          0.0,
              (sum, item) => sum + item.dockWeight,
        );

        final children = <Widget>[];

        for (var i = 0; i < groups.length; i++) {
          final group = groups[i];
          final flex = math.max(
            1,
            ((group.dockWeight / (totalWeight == 0 ? 1 : totalWeight)) * 1000)
                .round(),
          );

          children.add(
            Expanded(
              flex: flex,
              child: RepaintBoundary(
                child: buildGroupCard(group),
              ),
            ),
          );

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

        return isSideArea
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        )
            : Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }
}