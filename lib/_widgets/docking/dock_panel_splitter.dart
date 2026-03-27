import 'package:flutter/material.dart';
import 'package:sipged/_widgets/docking/dock_panel_config.dart';

class DockPanelSplitter extends StatelessWidget {
  final Axis axis;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  const DockPanelSplitter({
    super.key,
    required this.axis,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: axis == Axis.vertical
          ? SystemMouseCursors.resizeRow
          : SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(
          width: axis == Axis.horizontal
              ? DockPanelConfig.splitterThickness
              : null,
          height: axis == Axis.vertical
              ? DockPanelConfig.splitterThickness
              : null,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Container(
            width: axis == Axis.horizontal ? 2 : 28,
            height: axis == Axis.vertical ? 2 : 28,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      ),
    );
  }
}