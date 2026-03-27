import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';

class DockPanelFloatingLayer extends StatelessWidget {
  final List<DockPanelData> floatingGroups;
  final Size workspaceSize;
  final Widget Function(DockPanelData group, bool isFloating)
  buildGroupCard;

  const DockPanelFloatingLayer({
    super.key,
    required this.floatingGroups,
    required this.workspaceSize,
    required this.buildGroupCard,
  });

  @override
  Widget build(BuildContext context) {
    if (floatingGroups.isEmpty) return const SizedBox.shrink();

    final width = workspaceSize.width;
    final height = workspaceSize.height;

    return Stack(
      children: floatingGroups.map((group) {
        final size = group.floatingSize;
        final offset = (width <= 0 || height <= 0)
            ? group.floatingOffset
            : Offset(
          group.floatingOffset.dx
              .clamp(0.0, math.max(0.0, width - size.width))
              .toDouble(),
          group.floatingOffset.dy
              .clamp(0.0, math.max(0.0, height - size.height))
              .toDouble(),
        );

        return Positioned(
          left: offset.dx,
          top: offset.dy,
          width: size.width,
          height: size.height,
          child: RepaintBoundary(
            child: buildGroupCard(group, true),
          ),
        );
      }).toList(growable: false),
    );
  }
}