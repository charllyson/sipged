import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';
import 'package:sipged/_widgets/docking/dock_panel_logic.dart';

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

  List<DockPanelData> get visibleGroups =>
      workingGroups.where((g) => g.visible).toList(growable: false);

  List<DockPanelData> get layoutGroups =>
      workingGroups.where((g) => g.visible && !g.collapsed).toList(growable: false);

  List<DockPanelData> groupsInArea(
      DockArea area, {
        bool includeCollapsed = false,
      }) {
    return workingGroups.where((g) {
      if (!g.visible) return false;
      if (g.area != area) return false;
      if (!includeCollapsed && g.collapsed) return false;
      return true;
    }).toList(growable: false);
  }

  List<DockPanelData> get leftGroups => groupsInArea(DockArea.left);
  List<DockPanelData> get rightGroups => groupsInArea(DockArea.right);
  List<DockPanelData> get topGroups => groupsInArea(DockArea.top);
  List<DockPanelData> get bottomGroups => groupsInArea(DockArea.bottom);
  List<DockPanelData> get floatingGroups => groupsInArea(DockArea.floating);

  List<DockPanelData> get collapsedLeftGroups => workingGroups
      .where((g) => g.visible && g.collapsed && g.area == DockArea.left)
      .toList(growable: false);

  List<DockPanelData> get collapsedRightGroups => workingGroups
      .where((g) => g.visible && g.collapsed && g.area == DockArea.right)
      .toList(growable: false);

  bool get preserveLayoutDuringExternalSync =>
      isDragging || isDockExtentResizing || isDockWeightResizing || isFloatingResizing;

  bool get hasDialogPanel => floatingGroups.any((g) => g.floatingAsDialog);

  DockPanelData groupById(String id) => workingGroups.firstWhere((g) => g.id == id);

  double resolvedDockExtent(DockArea area) {
    return DockPanelLogic.resolvedDockExtentForArea(
      area,
      workingGroups,
    );
  }

  DockCrossSpan resolvedCrossSpan(DockArea area) {
    return DockPanelLogic.resolvedCrossSpanForArea(
      area,
      workingGroups,
    );
  }

  Rect? resolveDockRectForArea(DockArea area) {
    return DockPanelLogic.resolveDockRectForArea(
      area: area,
      source: workingGroups,
      workspaceSize: workspaceSize,
    );
  }

  Rect resolveContentRect({
    EdgeInsets contentPadding = EdgeInsets.zero,
  }) {
    return DockPanelLogic.resolveContentRect(
      source: workingGroups,
      workspaceSize: workspaceSize,
      contentPadding: contentPadding,
    );
  }

  Rect? get previewRect {
    return DockPanelLogic.projectedPreviewRect(
      isDragging: isDragging,
      hoveredSnapArea: hoveredSnapArea,
      draggingGroupId: draggingGroupId,
      lastDragLocalPosition: lastDragLocalPosition,
      workingGroups: workingGroups,
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