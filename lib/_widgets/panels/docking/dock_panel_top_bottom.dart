import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/docking/dock_panel_data.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_area.dart';

class DockPanelTopBottom extends StatelessWidget {
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

  const DockPanelTopBottom({
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
    final isTop = area == DockArea.top;

    return SizedBox(
      height: extent,
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
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}