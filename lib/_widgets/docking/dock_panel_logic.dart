import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';
import 'package:sipged/_widgets/docking/dock_panel_config.dart';

class DockPanelLogic {
  DockPanelLogic._();

  static bool isHorizontalArea(DockArea area) {
    return area == DockArea.top || area == DockArea.bottom;
  }

  static bool isVerticalArea(DockArea area) {
    return area == DockArea.left || area == DockArea.right;
  }

  static List<DockPanelData> mergeIncomingGroups({
    required List<DockPanelData> incoming,
    required List<DockPanelData> current,
    required bool preserveLayout,
  }) {
    final currentById = <String, DockPanelData>{
      for (final g in current) g.id: g,
    };

    return incoming.map((external) {
      final local = currentById[external.id];
      if (local == null || !preserveLayout) {
        return external;
      }

      return external.copyWith(
        area: local.area,
        crossSpan: local.crossSpan,
        floatingOffset: local.floatingOffset,
        floatingSize: local.floatingSize,
        dockExtent: local.dockExtent,
        dockWeight: local.dockWeight,
        visible: local.visible,
        activeItemId: local.activeItemId,
        minimized: local.minimized,
        lastDockArea: local.lastDockArea,
        lastDockCrossSpan: local.lastDockCrossSpan,
      );
    }).toList(growable: false);
  }

  static List<DockPanelData> normalizeDockSpans(
      List<DockPanelData> source, {
        DockArea? preferredFullArea,
      }) {
    final hasLeft = source.any((g) => g.visible && g.area == DockArea.left);
    final hasRight = source.any((g) => g.visible && g.area == DockArea.right);
    final hasTop = source.any((g) => g.visible && g.area == DockArea.top);
    final hasBottom = source.any((g) => g.visible && g.area == DockArea.bottom);

    final hasVertical = hasLeft || hasRight;
    final hasHorizontal = hasTop || hasBottom;

    if (!hasVertical && !hasHorizontal) {
      return source;
    }

    final hasFullVertical = source.any(
          (g) =>
      g.visible &&
          isVerticalArea(g.area) &&
          g.crossSpan == DockCrossSpan.full,
    );

    final hasFullHorizontal = source.any(
          (g) =>
      g.visible &&
          isHorizontalArea(g.area) &&
          g.crossSpan == DockCrossSpan.full,
    );

    bool horizontalWins;
    if (preferredFullArea != null && preferredFullArea != DockArea.floating) {
      horizontalWins = isHorizontalArea(preferredFullArea);
    } else if (hasFullHorizontal && !hasFullVertical) {
      horizontalWins = true;
    } else if (hasFullVertical && !hasFullHorizontal) {
      horizontalWins = false;
    } else if (hasHorizontal && !hasVertical) {
      horizontalWins = true;
    } else if (hasVertical && !hasHorizontal) {
      horizontalWins = false;
    } else {
      horizontalWins = false;
    }

    return source.map((group) {
      if (!group.visible || group.area == DockArea.floating) {
        return group;
      }

      final isHorizontal = isHorizontalArea(group.area);
      final orthogonalExists = isHorizontal ? hasVertical : hasHorizontal;

      if (!orthogonalExists) {
        return group.copyWith(crossSpan: DockCrossSpan.full);
      }

      return group.copyWith(
        crossSpan: (isHorizontal == horizontalWins)
            ? DockCrossSpan.full
            : DockCrossSpan.inner,
      );
    }).toList(growable: false);
  }

  static double resolvedDockExtentForArea(
      DockArea area,
      List<DockPanelData> source,
      ) {
    final groups = source
        .where((g) => g.visible && g.area == area)
        .toList(growable: false);

    if (groups.isEmpty) return 0;

    switch (area) {
      case DockArea.left:
      case DockArea.right:
        return groups
            .map((e) => e.dockExtent)
            .reduce(math.max)
            .clamp(
          DockPanelConfig.minDockSideExtent,
          DockPanelConfig.maxDockSideExtent,
        )
            .toDouble();

      case DockArea.top:
      case DockArea.bottom:
        return groups
            .map((e) => e.dockExtent)
            .reduce(math.max)
            .clamp(
          DockPanelConfig.minDockTopBottomExtent,
          DockPanelConfig.maxDockTopBottomExtent,
        )
            .toDouble();

      case DockArea.floating:
        return 0;
    }
  }

  static DockCrossSpan resolvedCrossSpanForArea(
      DockArea area,
      List<DockPanelData> source,
      ) {
    final groups = source
        .where((g) => g.visible && g.area == area)
        .toList(growable: false);

    if (groups.isEmpty) return DockCrossSpan.full;
    return groups.first.crossSpan;
  }

  static bool hasVisibleArea(
      DockArea area,
      List<DockPanelData> source,
      ) {
    return source.any((g) => g.visible && g.area == area);
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
            bottomExists &&
                localPosition.dy > (workspaceSize.height - bottomHeight);

        return (insideTopRow || insideBottomRow)
            ? DockCrossSpan.full
            : DockCrossSpan.inner;

      case DockArea.floating:
        return DockCrossSpan.full;
    }
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
      if (group.id == groupId) {
        return group.copyWith(
          area: targetArea,
          crossSpan: targetSpan,
          visible: true,
          minimized: false,
          lastDockArea: targetArea == DockArea.floating ? group.lastDockArea : targetArea,
          lastDockCrossSpan: targetArea == DockArea.floating
              ? group.lastDockCrossSpan
              : targetSpan,
        );
      }
      return group;
    }).toList(growable: false);

    return normalizeDockSpans(
      projected,
      preferredFullArea: targetSpan == DockCrossSpan.full ? targetArea : null,
    );
  }

  static Offset clampFloatingOffset({
    required Offset desired,
    required Size floatingSize,
    required Size workspaceSize,
  }) {
    return Offset(
      desired.dx
          .clamp(0.0, math.max(0.0, workspaceSize.width - floatingSize.width))
          .toDouble(),
      desired.dy
          .clamp(0.0, math.max(0.0, workspaceSize.height - floatingSize.height))
          .toDouble(),
    );
  }

  static Rect? resolveDockRectForArea({
    required DockArea area,
    required List<DockPanelData> source,
    required Size workspaceSize,
  }) {
    if (area == DockArea.floating) return null;

    final groups = source
        .where((g) => g.visible && g.area == area)
        .toList(growable: false);

    if (groups.isEmpty) return null;

    final leftGroups = source
        .where((g) => g.visible && g.area == DockArea.left)
        .toList(growable: false);
    final rightGroups = source
        .where((g) => g.visible && g.area == DockArea.right)
        .toList(growable: false);
    final topGroups = source
        .where((g) => g.visible && g.area == DockArea.top)
        .toList(growable: false);
    final bottomGroups = source
        .where((g) => g.visible && g.area == DockArea.bottom)
        .toList(growable: false);

    final leftWidth = resolvedDockExtentForArea(DockArea.left, source);
    final rightWidth = resolvedDockExtentForArea(DockArea.right, source);
    final topHeight = resolvedDockExtentForArea(DockArea.top, source);
    final bottomHeight = resolvedDockExtentForArea(DockArea.bottom, source);

    final span = resolvedCrossSpanForArea(area, source);

    final occupiedLeft = leftGroups.isNotEmpty ? leftWidth : 0.0;
    final occupiedRight = rightGroups.isNotEmpty ? rightWidth : 0.0;
    final occupiedTop = topGroups.isNotEmpty ? topHeight : 0.0;
    final occupiedBottom = bottomGroups.isNotEmpty ? bottomHeight : 0.0;

    switch (area) {
      case DockArea.left:
        final top = span == DockCrossSpan.full ? 0.0 : occupiedTop;
        final bottom = span == DockCrossSpan.full
            ? workspaceSize.height
            : workspaceSize.height - occupiedBottom;

        return Rect.fromLTRB(
          0,
          top,
          leftWidth,
          bottom,
        );

      case DockArea.right:
        final top = span == DockCrossSpan.full ? 0.0 : occupiedTop;
        final bottom = span == DockCrossSpan.full
            ? workspaceSize.height
            : workspaceSize.height - occupiedBottom;

        return Rect.fromLTRB(
          workspaceSize.width - rightWidth,
          top,
          workspaceSize.width,
          bottom,
        );

      case DockArea.top:
        final left = span == DockCrossSpan.full ? 0.0 : occupiedLeft;
        final right = span == DockCrossSpan.full
            ? workspaceSize.width
            : workspaceSize.width - occupiedRight;

        return Rect.fromLTRB(
          left,
          0,
          right,
          topHeight,
        );

      case DockArea.bottom:
        final left = span == DockCrossSpan.full ? 0.0 : occupiedLeft;
        final right = span == DockCrossSpan.full
            ? workspaceSize.width
            : workspaceSize.width - occupiedRight;

        return Rect.fromLTRB(
          left,
          workspaceSize.height - bottomHeight,
          right,
          workspaceSize.height,
        );

      case DockArea.floating:
        return null;
    }
  }

  static Rect resolveContentRect({
    required List<DockPanelData> source,
    required Size workspaceSize,
    EdgeInsets contentPadding = EdgeInsets.zero,
  }) {
    final hasLeft = hasVisibleArea(DockArea.left, source);
    final hasRight = hasVisibleArea(DockArea.right, source);
    final hasTop = hasVisibleArea(DockArea.top, source);
    final hasBottom = hasVisibleArea(DockArea.bottom, source);

    final leftInset =
    hasLeft ? resolvedDockExtentForArea(DockArea.left, source) : 0.0;
    final rightInset =
    hasRight ? resolvedDockExtentForArea(DockArea.right, source) : 0.0;
    final topInset =
    hasTop ? resolvedDockExtentForArea(DockArea.top, source) : 0.0;
    final bottomInset =
    hasBottom ? resolvedDockExtentForArea(DockArea.bottom, source) : 0.0;

    final left = (leftInset + contentPadding.left)
        .clamp(0.0, workspaceSize.width)
        .toDouble();
    final top = (topInset + contentPadding.top)
        .clamp(0.0, workspaceSize.height)
        .toDouble();

    final right = (workspaceSize.width - rightInset - contentPadding.right)
        .clamp(0.0, workspaceSize.width)
        .toDouble();
    final bottom = (workspaceSize.height - bottomInset - contentPadding.bottom)
        .clamp(0.0, workspaceSize.height)
        .toDouble();

    if (right <= left || bottom <= top) {
      return Rect.fromLTWH(0, 0, workspaceSize.width, workspaceSize.height);
    }

    return Rect.fromLTRB(left, top, right, bottom);
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

    return resolveDockRectForArea(
      area: hoveredSnapArea,
      source: projected,
      workspaceSize: workspaceSize,
    );
  }
}