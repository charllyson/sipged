import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/panels/docking/dock_panel_data.dart';
import 'package:sipged/_blocs/system/panels/docking/dock_panel_state.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_region.dart';

class DockPanelLayout extends StatelessWidget {
  final DockPanelState state;
  final Widget child;
  final EdgeInsets contentPadding;
  final Size contentMinSize;

  final Widget Function(DockPanelData group, bool isFloating) buildGroupCard;

  final VoidCallback onSideExtentResizeStart;
  final VoidCallback onSideExtentResizeEnd;
  final void Function(DockArea area, double delta) onSideExtentResize;

  final VoidCallback onWeightResizeStart;
  final VoidCallback onWeightResizeEnd;
  final void Function(
      List<DockPanelData> groups,
      int leadingIndex,
      double deltaPixels,
      double totalPixels,
      ) onWeightResize;

  const DockPanelLayout({
    super.key,
    required this.state,
    required this.child,
    required this.contentPadding,
    required this.contentMinSize,
    required this.buildGroupCard,
    required this.onSideExtentResizeStart,
    required this.onSideExtentResizeEnd,
    required this.onSideExtentResize,
    required this.onWeightResizeStart,
    required this.onWeightResizeEnd,
    required this.onWeightResize,
  });

  Widget? _buildDockedRegion({
    required DockArea area,
    required List<DockPanelData> groups,
    required Rect? rect,
    required double extent,
  }) {
    if (groups.isEmpty || rect == null) return null;

    return Positioned.fromRect(
      rect: rect,
      child: DockPanelRegion(
        groups: groups,
        area: area,
        extent: extent,
        buildGroupCard: buildGroupCard,
        onExtentResizeStart: onSideExtentResizeStart,
        onExtentResizeEnd: onSideExtentResizeEnd,
        onExtentResize: (delta) => onSideExtentResize(area, delta),
        onWeightResizeStart: onWeightResizeStart,
        onWeightResizeEnd: onWeightResizeEnd,
        onWeightResize: (leadingIndex, deltaPixels, totalPixels) {
          onWeightResize(
            groups,
            leadingIndex,
            deltaPixels,
            totalPixels,
          );
        },
      ),
    );
  }

  Widget _buildScrollableContent(Rect contentRect) {
    final viewportWidth = contentRect.width;
    final viewportHeight = contentRect.height;

    final canvasWidth = math.max(viewportWidth, contentMinSize.width);
    final canvasHeight = math.max(viewportHeight, contentMinSize.height);

    return RepaintBoundary(
      child: ClipRect(
        child: ScrollConfiguration(
          behavior: const _DockScrollBehavior(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SizedBox(
                width: canvasWidth,
                height: canvasHeight,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentRect = state.resolveContentRect(
      contentPadding: contentPadding,
    );

    final dockedRegions = <Widget?>[
      _buildDockedRegion(
        area: DockArea.left,
        groups: state.leftGroups,
        rect: state.resolveDockRectForArea(DockArea.left),
        extent: state.resolvedDockExtent(DockArea.left),
      ),
      _buildDockedRegion(
        area: DockArea.right,
        groups: state.rightGroups,
        rect: state.resolveDockRectForArea(DockArea.right),
        extent: state.resolvedDockExtent(DockArea.right),
      ),
      _buildDockedRegion(
        area: DockArea.top,
        groups: state.topGroups,
        rect: state.resolveDockRectForArea(DockArea.top),
        extent: state.resolvedDockExtent(DockArea.top),
      ),
      _buildDockedRegion(
        area: DockArea.bottom,
        groups: state.bottomGroups,
        rect: state.resolveDockRectForArea(DockArea.bottom),
        extent: state.resolvedDockExtent(DockArea.bottom),
      ),
    ];

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fromRect(
          rect: contentRect,
          child: _buildScrollableContent(contentRect),
        ),
        ...dockedRegions.whereType<Widget>(),
      ],
    );
  }
}

class _DockScrollBehavior extends MaterialScrollBehavior {
  const _DockScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };

  @override
  Widget buildOverscrollIndicator(
      BuildContext context,
      Widget child,
      ScrollableDetails details,
      ) {
    return child;
  }
}