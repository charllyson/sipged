import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/panels/docking/dock_panel_data.dart';
import 'package:sipged/_blocs/system/panels/docking/dock_panel_state.dart';

class DockPanelFloating extends StatelessWidget {
  final List<DockPanelData> floatingGroups;
  final Size workspaceSize;
  final Widget Function(DockPanelData group, bool isFloating) buildGroupCard;

  const DockPanelFloating({
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
    final padding = DockPanelState.floatingWorkspacePadding;

    return Stack(
      children: floatingGroups.map((group) {
        final size = group.floatingSize;

        final offset = (width <= 0 || height <= 0)
            ? group.floatingOffset
            : Offset(
          group.floatingOffset.dx
              .clamp(
            padding,
            math.max(padding, width - size.width - padding),
          )
              .toDouble(),
          group.floatingOffset.dy
              .clamp(
            padding,
            math.max(padding, height - size.height - padding),
          )
              .toDouble(),
        );

        return Positioned(
          left: offset.dx,
          top: offset.dy,
          width: size.width,
          height: size.height,
          child: buildGroupCard(group, true),
        );
      }).toList(growable: false),
    );
  }
}