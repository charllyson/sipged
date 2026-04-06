import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_area.dart';

class DockPanelSide extends StatelessWidget {
  final List<DockPanelData> groups;
  final DockArea area;
  final double extent;
  final Widget Function(DockPanelData group, bool isFloating) buildGroupCard;

  final VoidCallback onExtentResizeStart;
  final VoidCallback onExtentResizeEnd;
  final ValueChanged<double> onExtentResize;

  final VoidCallback onWeightResizeStart;
  final VoidCallback onWeightResizeEnd;
  final void Function(int leadingIndex, double deltaPixels, double totalPixels) onWeightResize;

  const DockPanelSide({
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

  @override
  Widget build(BuildContext context) {
    final isLeft = area == DockArea.left;

    return SizedBox(
      width: extent,
      child: Stack(
        children: [
          Positioned.fill(
            child: DockPanelArea(
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
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}