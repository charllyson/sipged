import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/panels/docking/dock_panel_data.dart';

@immutable
class DockPanelState {
  final List<DockPanelData> workingGroups;

  final bool isDragging;
  final DockArea? hoveredSnapArea;
  final String? draggingGroupId;
  final Offset? lastDragLocalPosition;

  final bool isDockExtentResizing;
  final bool isDockWeightResizing;
  final bool isFloatingResizing;

  final Size workspaceSize;

  const DockPanelState({
    required this.workingGroups,
    required this.isDragging,
    required this.hoveredSnapArea,
    required this.draggingGroupId,
    required this.lastDragLocalPosition,
    required this.isDockExtentResizing,
    required this.isDockWeightResizing,
    required this.isFloatingResizing,
    required this.workspaceSize,
  });

  static const double minDockSideExtent = 180.0;
  static const double maxDockSideExtent = 1100.0;

  static const double minDockTopBottomExtent = 120.0;
  static const double maxDockTopBottomExtent = 700.0;

  static const double minDockWeight = 0.35;
  static const double dragUpdateThreshold = 10.0;

  static const double minFloatingWidth = 260.0;
  static const double maxFloatingWidth = 1200.0;

  static const double minFloatingHeight = 180.0;
  static const double maxFloatingHeight = 900.0;

  static const double floatingWorkspacePadding = 12.0;

  static const double seamOverlap = 1.0;

  factory DockPanelState.initial({
    required List<DockPanelData> groups,
  }) {
    return DockPanelState(
      workingGroups: List<DockPanelData>.from(groups),
      isDragging: false,
      hoveredSnapArea: null,
      draggingGroupId: null,
      lastDragLocalPosition: null,
      isDockExtentResizing: false,
      isDockWeightResizing: false,
      isFloatingResizing: false,
      workspaceSize: Size.zero,
    );
  }

  DockPanelState copyWith({
    List<DockPanelData>? workingGroups,
    bool? isDragging,
    DockArea? hoveredSnapArea,
    bool clearHoveredSnapArea = false,
    String? draggingGroupId,
    bool clearDraggingGroupId = false,
    Offset? lastDragLocalPosition,
    bool clearLastDragLocalPosition = false,
    bool? isDockExtentResizing,
    bool? isDockWeightResizing,
    bool? isFloatingResizing,
    Size? workspaceSize,
  }) {
    return DockPanelState(
      workingGroups: workingGroups ?? this.workingGroups,
      isDragging: isDragging ?? this.isDragging,
      hoveredSnapArea:
      clearHoveredSnapArea ? null : (hoveredSnapArea ?? this.hoveredSnapArea),
      draggingGroupId:
      clearDraggingGroupId ? null : (draggingGroupId ?? this.draggingGroupId),
      lastDragLocalPosition: clearLastDragLocalPosition
          ? null
          : (lastDragLocalPosition ?? this.lastDragLocalPosition),
      isDockExtentResizing: isDockExtentResizing ?? this.isDockExtentResizing,
      isDockWeightResizing: isDockWeightResizing ?? this.isDockWeightResizing,
      isFloatingResizing: isFloatingResizing ?? this.isFloatingResizing,
      workspaceSize: workspaceSize ?? this.workspaceSize,
    );
  }

  static bool isHorizontalArea(DockArea area) {
    return area == DockArea.top || area == DockArea.bottom;
  }

  static bool occupiesLayout(DockPanelData group) {
    return group.visible && group.area != DockArea.floating;
  }

  static double clampDockExtent(DockArea area, double extent) {
    switch (area) {
      case DockArea.left:
      case DockArea.right:
        return extent.clamp(minDockSideExtent, maxDockSideExtent).toDouble();
      case DockArea.top:
      case DockArea.bottom:
        return extent.clamp(minDockTopBottomExtent, maxDockTopBottomExtent).toDouble();
      case DockArea.floating:
        return 0.0;
    }
  }

  static bool hasVisibleArea(
      DockArea area,
      List<DockPanelData> source,
      ) {
    return source.any((g) => occupiesLayout(g) && g.area == area);
  }

  static double resolvedDockExtentForArea(
      DockArea area,
      List<DockPanelData> source,
      ) {
    final groups = source
        .where((g) => occupiesLayout(g) && g.area == area)
        .toList(growable: false);

    if (groups.isEmpty) return 0;

    final maxExtent = groups.map((e) => e.dockExtent).reduce(math.max);
    return clampDockExtent(area, maxExtent);
  }

  static DockCrossSpan resolvedCrossSpanForArea(
      DockArea area,
      List<DockPanelData> source,
      ) {
    final groups = source
        .where((g) => occupiesLayout(g) && g.area == area)
        .toList(growable: false);

    if (groups.isEmpty) return DockCrossSpan.full;
    return groups.first.crossSpan;
  }

  static DockCrossSpan resolveTargetCrossSpan({
    required DockArea targetArea,
    required Offset localPosition,
    required List<DockPanelData> baseGroups,
    required Size workspaceSize,
  }) {
    final leftExists = hasVisibleArea(DockArea.left, baseGroups);
    final rightExists = hasVisibleArea(DockArea.right, baseGroups);
    final topExists = hasVisibleArea(DockArea.top, baseGroups);
    final bottomExists = hasVisibleArea(DockArea.bottom, baseGroups);

    final leftWidth = resolvedDockExtentForArea(DockArea.left, baseGroups);
    final rightWidth = resolvedDockExtentForArea(DockArea.right, baseGroups);
    final topHeight = resolvedDockExtentForArea(DockArea.top, baseGroups);
    final bottomHeight = resolvedDockExtentForArea(DockArea.bottom, baseGroups);

    switch (targetArea) {
      case DockArea.top:
      case DockArea.bottom:
        final hasOrthogonal = leftExists || rightExists;
        if (!hasOrthogonal) return DockCrossSpan.full;

        final insideLeftColumn = leftExists && localPosition.dx < leftWidth;
        final insideRightColumn =
            rightExists && localPosition.dx > (workspaceSize.width - rightWidth);

        return (insideLeftColumn || insideRightColumn)
            ? DockCrossSpan.full
            : DockCrossSpan.inner;

      case DockArea.left:
      case DockArea.right:
        final hasOrthogonal = topExists || bottomExists;
        if (!hasOrthogonal) return DockCrossSpan.full;

        final insideTopRow = topExists && localPosition.dy < topHeight;
        final insideBottomRow =
            bottomExists && localPosition.dy > (workspaceSize.height - bottomHeight);

        return (insideTopRow || insideBottomRow)
            ? DockCrossSpan.full
            : DockCrossSpan.inner;

      case DockArea.floating:
        return DockCrossSpan.full;
    }
  }

  static List<DockPanelData> normalizeDockSpans(
      List<DockPanelData> source, {
        DockArea? preferredFullArea,
      }) {
    final effective = source.where(occupiesLayout).toList(growable: false);

    final hasLeft = effective.any((g) => g.area == DockArea.left);
    final hasRight = effective.any((g) => g.area == DockArea.right);
    final hasTop = effective.any((g) => g.area == DockArea.top);
    final hasBottom = effective.any((g) => g.area == DockArea.bottom);

    final hasVertical = hasLeft || hasRight;
    final hasHorizontal = hasTop || hasBottom;

    if (!hasVertical && !hasHorizontal) {
      return source;
    }

    bool horizontalWins;
    if (preferredFullArea != null && preferredFullArea != DockArea.floating) {
      horizontalWins = isHorizontalArea(preferredFullArea);
    } else if (hasHorizontal && !hasVertical) {
      horizontalWins = true;
    } else if (hasVertical && !hasHorizontal) {
      horizontalWins = false;
    } else {
      horizontalWins = false;
    }

    return source.map((group) {
      if (!occupiesLayout(group)) return group;

      final isHorizontal = isHorizontalArea(group.area);
      final orthogonalExists = isHorizontal ? hasVertical : hasHorizontal;

      if (!orthogonalExists) {
        return group.copyWith(crossSpan: DockCrossSpan.full);
      }

      return group.copyWith(
        crossSpan:
        (isHorizontal == horizontalWins) ? DockCrossSpan.full : DockCrossSpan.inner,
      );
    }).toList(growable: false);
  }

  static List<DockPanelData> projectDocking({
    required List<DockPanelData> workingGroups,
    required String groupId,
    required DockArea targetArea,
    required Offset localPosition,
    required Size workspaceSize,
  }) {
    final baseGroups =
    workingGroups.where((g) => g.id != groupId).toList(growable: false);

    final targetSpan = resolveTargetCrossSpan(
      targetArea: targetArea,
      localPosition: localPosition,
      baseGroups: baseGroups,
      workspaceSize: workspaceSize,
    );

    final projected = workingGroups.map((group) {
      if (group.id != groupId) return group;

      return group.copyWith(
        area: targetArea,
        crossSpan: targetSpan,
        visible: true,
        lastDockArea: targetArea == DockArea.floating ? group.lastDockArea : targetArea,
        lastDockCrossSpan:
        targetArea == DockArea.floating ? group.lastDockCrossSpan : targetSpan,
      );
    }).toList(growable: false);

    return normalizeDockSpans(
      projected,
      preferredFullArea: targetSpan == DockCrossSpan.full ? targetArea : null,
    );
  }

  static DockArea? resolveSnapArea({
    required Offset localPosition,
    required Size workspaceSize,
    required double snapThickness,
  }) {
    final width = workspaceSize.width;
    final height = workspaceSize.height;

    if (width <= 0 || height <= 0) return null;

    if (localPosition.dx <= snapThickness) return DockArea.left;
    if (localPosition.dx >= width - snapThickness) return DockArea.right;
    if (localPosition.dy <= snapThickness) return DockArea.top;
    if (localPosition.dy >= height - snapThickness) return DockArea.bottom;

    return null;
  }

  static Offset clampFloatingOffset({
    required Offset desired,
    required Size floatingSize,
    required Size workspaceSize,
  }) {
    final padding = floatingWorkspacePadding;

    final maxDx = math.max(0.0, workspaceSize.width - floatingSize.width - padding);
    final maxDy = math.max(0.0, workspaceSize.height - floatingSize.height - padding);

    return Offset(
      desired.dx.clamp(padding, maxDx).toDouble(),
      desired.dy.clamp(padding, maxDy).toDouble(),
    );
  }

  static Size clampFloatingSize({
    required Size desired,
    required Size workspaceSize,
  }) {
    final padding = floatingWorkspacePadding * 2;

    final maxWidth = workspaceSize.width > 0
        ? math.max(minFloatingWidth, workspaceSize.width - padding)
        : maxFloatingWidth;

    final maxHeight = workspaceSize.height > 0
        ? math.max(minFloatingHeight, workspaceSize.height - padding)
        : maxFloatingHeight;

    return Size(
      desired.width
          .clamp(minFloatingWidth, math.min(maxFloatingWidth, maxWidth))
          .toDouble(),
      desired.height
          .clamp(minFloatingHeight, math.min(maxFloatingHeight, maxHeight))
          .toDouble(),
    );
  }

  static List<DockPanelData> adaptGroupsToWorkspace({
    required List<DockPanelData> groups,
    required Size workspaceSize,
  }) {
    if (workspaceSize.isEmpty) return groups;

    var changed = false;

    final next = groups.map((group) {
      if (group.area != DockArea.floating) return group;

      final nextSize = clampFloatingSize(
        desired: group.floatingSize,
        workspaceSize: workspaceSize,
      );

      final nextOffset = clampFloatingOffset(
        desired: group.floatingOffset,
        floatingSize: nextSize,
        workspaceSize: workspaceSize,
      );

      if (nextSize == group.floatingSize && nextOffset == group.floatingOffset) {
        return group;
      }

      changed = true;
      return group.copyWith(
        floatingSize: nextSize,
        floatingOffset: nextOffset,
      );
    }).toList(growable: false);

    return changed ? next : groups;
  }

  static Rect _pixelSnapRect(Rect rect) {
    return Rect.fromLTRB(
      rect.left.floorToDouble(),
      rect.top.floorToDouble(),
      rect.right.ceilToDouble(),
      rect.bottom.ceilToDouble(),
    );
  }

  List<DockPanelData> get visibleGroups =>
      workingGroups.where((g) => g.visible).toList(growable: false);

  List<DockPanelData> get layoutGroups => workingGroups
      .where((g) => g.visible && g.area != DockArea.floating)
      .toList(growable: false);

  List<DockPanelData> groupsInArea(DockArea area) {
    return workingGroups.where((g) {
      return g.visible && g.area == area;
    }).toList(growable: false);
  }

  List<DockPanelData> get leftGroups => groupsInArea(DockArea.left);
  List<DockPanelData> get rightGroups => groupsInArea(DockArea.right);
  List<DockPanelData> get topGroups => groupsInArea(DockArea.top);
  List<DockPanelData> get bottomGroups => groupsInArea(DockArea.bottom);
  List<DockPanelData> get floatingGroups => groupsInArea(DockArea.floating);

  bool get preserveLayoutDuringExternalSync =>
      isDragging || isDockExtentResizing || isDockWeightResizing || isFloatingResizing;

  bool get hasDialogPanel => floatingGroups.any((g) => g.floatingAsDialog);

  DockPanelData groupById(String id) =>
      workingGroups.firstWhere((g) => g.id == id);

  double resolvedDockExtent(DockArea area) {
    return resolvedDockExtentForArea(area, workingGroups);
  }

  DockCrossSpan resolvedCrossSpan(DockArea area) {
    return resolvedCrossSpanForArea(area, workingGroups);
  }

  Rect? resolveDockRectForArea(DockArea area) {
    return resolveDockRectForAreaStatic(
      area: area,
      source: workingGroups,
      workspaceSize: workspaceSize,
    );
  }

  Rect resolveContentRect({
    EdgeInsets contentPadding = EdgeInsets.zero,
  }) {
    return resolveContentRectStatic(
      source: workingGroups,
      workspaceSize: workspaceSize,
      contentPadding: contentPadding,
    );
  }

  Rect? get previewRect {
    return projectedPreviewRect(
      isDragging: isDragging,
      hoveredSnapArea: hoveredSnapArea,
      draggingGroupId: draggingGroupId,
      lastDragLocalPosition: lastDragLocalPosition,
      workingGroups: workingGroups,
      workspaceSize: workspaceSize,
    );
  }

  static Rect? resolveDockRectForAreaStatic({
    required DockArea area,
    required List<DockPanelData> source,
    required Size workspaceSize,
  }) {
    if (area == DockArea.floating) return null;

    final hasArea = hasVisibleArea(area, source);
    if (!hasArea) return null;

    final hasLeft = hasVisibleArea(DockArea.left, source);
    final hasRight = hasVisibleArea(DockArea.right, source);
    final hasTop = hasVisibleArea(DockArea.top, source);
    final hasBottom = hasVisibleArea(DockArea.bottom, source);

    final leftWidth = resolvedDockExtentForArea(DockArea.left, source);
    final rightWidth = resolvedDockExtentForArea(DockArea.right, source);
    final topHeight = resolvedDockExtentForArea(DockArea.top, source);
    final bottomHeight = resolvedDockExtentForArea(DockArea.bottom, source);

    final span = resolvedCrossSpanForArea(area, source);

    final occupiedLeft = hasLeft ? leftWidth : 0.0;
    final occupiedRight = hasRight ? rightWidth : 0.0;
    final occupiedTop = hasTop ? topHeight : 0.0;
    final occupiedBottom = hasBottom ? bottomHeight : 0.0;

    Rect rect;

    switch (area) {
      case DockArea.left:
        final top = span == DockCrossSpan.full ? 0.0 : occupiedTop;
        final bottom =
        span == DockCrossSpan.full ? workspaceSize.height : workspaceSize.height - occupiedBottom;

        rect = Rect.fromLTRB(
          0,
          top - seamOverlap,
          leftWidth + seamOverlap,
          bottom + seamOverlap,
        );
        break;

      case DockArea.right:
        final top = span == DockCrossSpan.full ? 0.0 : occupiedTop;
        final bottom =
        span == DockCrossSpan.full ? workspaceSize.height : workspaceSize.height - occupiedBottom;

        rect = Rect.fromLTRB(
          workspaceSize.width - rightWidth - seamOverlap,
          top - seamOverlap,
          workspaceSize.width,
          bottom + seamOverlap,
        );
        break;

      case DockArea.top:
        final left = span == DockCrossSpan.full ? 0.0 : occupiedLeft;
        final right =
        span == DockCrossSpan.full ? workspaceSize.width : workspaceSize.width - occupiedRight;

        rect = Rect.fromLTRB(
          left - seamOverlap,
          0,
          right + seamOverlap,
          topHeight + seamOverlap,
        );
        break;

      case DockArea.bottom:
        final left = span == DockCrossSpan.full ? 0.0 : occupiedLeft;
        final right =
        span == DockCrossSpan.full ? workspaceSize.width : workspaceSize.width - occupiedRight;

        rect = Rect.fromLTRB(
          left - seamOverlap,
          workspaceSize.height - bottomHeight - seamOverlap,
          right + seamOverlap,
          workspaceSize.height,
        );
        break;

      case DockArea.floating:
        return null;
    }

    rect = Rect.fromLTRB(
      rect.left.clamp(0.0, workspaceSize.width).toDouble(),
      rect.top.clamp(0.0, workspaceSize.height).toDouble(),
      rect.right.clamp(0.0, workspaceSize.width).toDouble(),
      rect.bottom.clamp(0.0, workspaceSize.height).toDouble(),
    );

    return _pixelSnapRect(rect);
  }

  static Rect resolveContentRectStatic({
    required List<DockPanelData> source,
    required Size workspaceSize,
    EdgeInsets contentPadding = EdgeInsets.zero,
  }) {
    final hasLeftDock = hasVisibleArea(DockArea.left, source);
    final hasRightDock = hasVisibleArea(DockArea.right, source);
    final hasTopDock = hasVisibleArea(DockArea.top, source);
    final hasBottomDock = hasVisibleArea(DockArea.bottom, source);

    final leftDockExtent =
    hasLeftDock ? resolvedDockExtentForArea(DockArea.left, source) : 0.0;
    final rightDockExtent =
    hasRightDock ? resolvedDockExtentForArea(DockArea.right, source) : 0.0;
    final topDockExtent =
    hasTopDock ? resolvedDockExtentForArea(DockArea.top, source) : 0.0;
    final bottomDockExtent =
    hasBottomDock ? resolvedDockExtentForArea(DockArea.bottom, source) : 0.0;

    final left =
    (leftDockExtent + contentPadding.left).clamp(0.0, workspaceSize.width).toDouble();
    final top =
    (topDockExtent + contentPadding.top).clamp(0.0, workspaceSize.height).toDouble();
    final right = (workspaceSize.width - rightDockExtent - contentPadding.right)
        .clamp(0.0, workspaceSize.width)
        .toDouble();
    final bottom = (workspaceSize.height - bottomDockExtent - contentPadding.bottom)
        .clamp(0.0, workspaceSize.height)
        .toDouble();

    if (right <= left || bottom <= top) {
      return Rect.fromLTWH(0, 0, workspaceSize.width, workspaceSize.height);
    }

    return _pixelSnapRect(Rect.fromLTRB(left, top, right, bottom));
  }

  static Rect? projectedPreviewRect({
    required bool isDragging,
    required DockArea? hoveredSnapArea,
    required String? draggingGroupId,
    required Offset? lastDragLocalPosition,
    required List<DockPanelData> workingGroups,
    required Size workspaceSize,
  }) {
    if (!isDragging ||
        hoveredSnapArea == null ||
        draggingGroupId == null ||
        lastDragLocalPosition == null) {
      return null;
    }

    final projected = projectDocking(
      workingGroups: workingGroups,
      groupId: draggingGroupId,
      targetArea: hoveredSnapArea,
      localPosition: lastDragLocalPosition,
      workspaceSize: workspaceSize,
    );

    return resolveDockRectForAreaStatic(
      area: hoveredSnapArea,
      source: projected,
      workspaceSize: workspaceSize,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DockPanelState &&
            listEquals(other.workingGroups, workingGroups) &&
            other.isDragging == isDragging &&
            other.hoveredSnapArea == hoveredSnapArea &&
            other.draggingGroupId == draggingGroupId &&
            other.lastDragLocalPosition == lastDragLocalPosition &&
            other.isDockExtentResizing == isDockExtentResizing &&
            other.isDockWeightResizing == isDockWeightResizing &&
            other.isFloatingResizing == isFloatingResizing &&
            other.workspaceSize == workspaceSize);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(workingGroups),
    isDragging,
    hoveredSnapArea,
    draggingGroupId,
    lastDragLocalPosition,
    isDockExtentResizing,
    isDockWeightResizing,
    isFloatingResizing,
    workspaceSize,
  );
}