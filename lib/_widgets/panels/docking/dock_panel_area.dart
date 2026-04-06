import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_splitter.dart';

class DockPanelArea extends StatelessWidget {
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

  const DockPanelArea({
    super.key,
    required this.groups,
    required this.area,
    required this.onResizeWeights,
    required this.onResizeWeightsStart,
    required this.onResizeWeightsEnd,
    required this.buildGroupCard,
  });

  bool get _isSideArea => area == DockArea.left || area == DockArea.right;

  Axis get _splitAxis => _isSideArea ? Axis.vertical : Axis.horizontal;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalPixels = _isSideArea ? constraints.maxHeight : constraints.maxWidth;

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
          final shouldShrinkWrap = group.shrinkWrapOnMainAxis || group.minimized;

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
                  final delta = _isSideArea ? details.delta.dy : details.delta.dx;
                  onResizeWeights(i, delta, totalPixels);
                },
                onPanEnd: (_) => onResizeWeightsEnd(),
              ),
            );
          }
        }

        return Flex(
          direction: _isSideArea ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }
}