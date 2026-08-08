import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_data.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_state.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_region.dart';

class DockPanelLayout extends StatelessWidget {
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

  static const double _compactBreakpoint = 700.0;

  bool _isValidRect(Rect? rect) {
    if (rect == null) return false;

    return rect.left.isFinite &&
        rect.top.isFinite &&
        rect.right.isFinite &&
        rect.bottom.isFinite &&
        rect.width > 0 &&
        rect.height > 0;
  }

  Rect _safeRect(Rect? rect) {
    if (!_isValidRect(rect)) return Rect.zero;
    return rect!;
  }

  Rect _resolveContentRect({
    required Size size,
    required Rect? leftRect,
    required Rect? rightRect,
    required Rect? topRect,
    required Rect? bottomRect,
  }) {
    if (size.width <= 0 || size.height <= 0) {
      return Rect.zero;
    }

    final full = Rect.fromLTWH(
      contentPadding.left,
      contentPadding.top,
      math.max(0, size.width - contentPadding.horizontal),
      math.max(0, size.height - contentPadding.vertical),
    );

    var left = full.left;
    var top = full.top;
    var right = full.right;
    var bottom = full.bottom;

    if (state.leftGroups.isNotEmpty && _isValidRect(leftRect)) {
      left = math.max(left, _safeRect(leftRect).right);
    }

    if (state.rightGroups.isNotEmpty && _isValidRect(rightRect)) {
      right = math.min(right, _safeRect(rightRect).left);
    }

    if (state.topGroups.isNotEmpty && _isValidRect(topRect)) {
      top = math.max(top, _safeRect(topRect).bottom);
    }

    if (state.bottomGroups.isNotEmpty && _isValidRect(bottomRect)) {
      bottom = math.min(bottom, _safeRect(bottomRect).top);
    }

    left = left.clamp(0.0, size.width);
    right = right.clamp(0.0, size.width);
    top = top.clamp(0.0, size.height);
    bottom = bottom.clamp(0.0, size.height);

    if (right <= left || bottom <= top) {
      return Rect.fromLTWH(
        contentPadding.left.clamp(0.0, size.width),
        contentPadding.top.clamp(0.0, size.height),
        math.max(0, size.width - contentPadding.horizontal),
        math.max(0, size.height - contentPadding.vertical),
      );
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  Widget? _buildDockedRegion({
    required DockArea area,
    required List<DockPanelData> groups,
    required Rect? rect,
    required double extent,
  }) {
    if (groups.isEmpty || !_isValidRect(rect)) {
      return null;
    }

    return Positioned.fromRect(
      rect: rect!,
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

  Widget _buildContent(Rect contentRect) {
    final viewportWidth = contentRect.width;
    final viewportHeight = contentRect.height;

    final isCompact = viewportWidth < _compactBreakpoint;

    final shouldUseVirtualCanvas =
        !isCompact &&
            contentMinSize.width > 0 &&
            contentMinSize.height > 0 &&
            (contentMinSize.width > viewportWidth ||
                contentMinSize.height > viewportHeight);

    if (!shouldUseVirtualCanvas) {
      return RepaintBoundary(
        child: ClipRect(
          child: SizedBox.expand(
            child: child,
          ),
        ),
      );
    }

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
        );

        if (size.width <= 0 || size.height <= 0) {
          return const SizedBox.shrink();
        }

        final leftRect = state.resolveDockRectForArea(DockArea.left);
        final rightRect = state.resolveDockRectForArea(DockArea.right);
        final topRect = state.resolveDockRectForArea(DockArea.top);
        final bottomRect = state.resolveDockRectForArea(DockArea.bottom);

        final contentRect = _resolveContentRect(
          size: size,
          leftRect: leftRect,
          rightRect: rightRect,
          topRect: topRect,
          bottomRect: bottomRect,
        );

        final dockedRegions = <Widget?>[
          _buildDockedRegion(
            area: DockArea.left,
            groups: state.leftGroups,
            rect: leftRect,
            extent: state.resolvedDockExtent(DockArea.left),
          ),
          _buildDockedRegion(
            area: DockArea.right,
            groups: state.rightGroups,
            rect: rightRect,
            extent: state.resolvedDockExtent(DockArea.right),
          ),
          _buildDockedRegion(
            area: DockArea.top,
            groups: state.topGroups,
            rect: topRect,
            extent: state.resolvedDockExtent(DockArea.top),
          ),
          _buildDockedRegion(
            area: DockArea.bottom,
            groups: state.bottomGroups,
            rect: bottomRect,
            extent: state.resolvedDockExtent(DockArea.bottom),
          ),
        ];

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fromRect(
              rect: contentRect,
              child: _buildContent(contentRect),
            ),
            ...dockedRegions.whereType<Widget>(),
          ],
        );
      },
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