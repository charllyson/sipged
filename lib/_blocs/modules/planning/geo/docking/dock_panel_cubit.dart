import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_state.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_config.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_logic.dart';

class DockPanelCubit extends Cubit<DockPanelState> {
  DockPanelCubit({
    required List<DockPanelData> initialGroups,
    required this.onCommit,
    this.snapThickness = 16,
  }) : super(
    DockPanelState.initial(
      groups: DockPanelLogic.normalizeDockSpans(
        List<DockPanelData>.from(initialGroups),
      ),
    ),
  );

  final ValueChanged<List<DockPanelData>> onCommit;
  final double snapThickness;

  void syncFromExternal(List<DockPanelData> groups) {
    final merged = DockPanelLogic.normalizeDockSpans(
      DockPanelLogic.mergeIncomingGroups(
        incoming: groups,
        current: state.workingGroups,
        preserveLayout: state.preserveLayoutDuringExternalSync,
      ),
    );

    if (listEquals(merged, state.workingGroups)) return;
    emit(state.copyWith(workingGroups: merged));
  }

  void setWorkspaceSize(Size size) {
    if (size == state.workspaceSize) return;

    final adaptedGroups = DockPanelLogic.adaptGroupsToWorkspace(
      groups: state.workingGroups,
      workspaceSize: size,
    );

    emit(
      state.copyWith(
        workspaceSize: size,
        workingGroups: adaptedGroups,
      ),
    );
  }

  void _emitGroups(List<DockPanelData> next) {
    if (listEquals(next, state.workingGroups)) return;
    emit(state.copyWith(workingGroups: next));
  }

  void _commitGroups(List<DockPanelData> next) {
    if (listEquals(next, state.workingGroups)) return;
    emit(state.copyWith(workingGroups: next));
    onCommit(List<DockPanelData>.from(next));
  }

  void _updateGroups({
    required DockPanelData Function(DockPanelData group) transform,
    required bool commit,
    bool normalize = false,
    DockArea? preferredFullArea,
  }) {
    var changed = false;

    List<DockPanelData> next = state.workingGroups.map((group) {
      final updated = transform(group);
      if (updated != group) changed = true;
      return updated;
    }).toList(growable: false);

    if (!changed) return;

    if (normalize) {
      next = DockPanelLogic.normalizeDockSpans(
        next,
        preferredFullArea: preferredFullArea,
      );
    }

    if (commit) {
      _commitGroups(next);
    } else {
      _emitGroups(next);
    }
  }

  void _updateManyGroupsLocal(Map<String, DockPanelData> updatesById) {
    if (updatesById.isEmpty) return;

    var changed = false;

    final next = state.workingGroups.map((group) {
      final updated = updatesById[group.id];
      if (updated != null && updated != group) {
        changed = true;
        return updated;
      }
      return group;
    }).toList(growable: false);

    if (!changed) return;
    _emitGroups(next);
  }

  DockArea _collapseAnchorFor(DockPanelData group) {
    if (group.area == DockArea.left || group.area == DockArea.right) {
      return group.area;
    }

    if (group.lastDockArea == DockArea.left || group.lastDockArea == DockArea.right) {
      return group.lastDockArea!;
    }

    return DockArea.right;
  }

  void setGroupVisible(String id, bool visible) {
    _updateGroups(
      commit: true,
      normalize: true,
      transform: (group) {
        if (group.id != id || group.visible == visible) return group;
        return group.copyWith(visible: visible);
      },
    );
  }

  void setGroupActiveItem(String groupId, String itemId) {
    _updateGroups(
      commit: true,
      transform: (group) {
        if (group.id != groupId || group.activeItemId == itemId) return group;
        return group.copyWith(activeItemId: itemId);
      },
    );
  }

  void collapseToRail(String groupId) {
    final current = state.groupById(groupId);
    final targetArea = _collapseAnchorFor(current);

    _updateGroups(
      commit: true,
      normalize: true,
      transform: (group) {
        if (group.id != groupId) return group;

        return group.copyWith(
          area: targetArea,
          visible: true,
          collapsed: true,
          minimized: false,
          floatingAsDialog: false,
          restoreToFloatingOnDialogClose: false,
          lastDockArea: targetArea,
          lastDockCrossSpan: targetArea == DockArea.left || targetArea == DockArea.right
              ? group.crossSpan
              : group.lastDockCrossSpan,
        );
      },
    );
  }

  void restoreFromRail(String groupId) {
    final current = state.groupById(groupId);
    final restoreArea = current.area == DockArea.left || current.area == DockArea.right
        ? current.area
        : (current.lastDockArea == DockArea.left || current.lastDockArea == DockArea.right
        ? current.lastDockArea!
        : DockArea.right);

    final restoreSpan = current.lastDockCrossSpan ??
        (restoreArea == DockArea.left || restoreArea == DockArea.right
            ? DockCrossSpan.inner
            : DockCrossSpan.full);

    final isCompact = state.workspaceSize.width > 0 && state.workspaceSize.width < 900;

    _updateGroups(
      commit: true,
      normalize: true,
      preferredFullArea: restoreSpan == DockCrossSpan.full ? restoreArea : null,
      transform: (group) {
        if (group.id == groupId) {
          return group.copyWith(
            area: restoreArea,
            crossSpan: restoreSpan,
            visible: true,
            collapsed: false,
            minimized: false,
            floatingAsDialog: false,
            restoreToFloatingOnDialogClose: false,
          );
        }

        if (isCompact &&
            group.visible &&
            !group.collapsed &&
            (group.area == DockArea.left || group.area == DockArea.right)) {
          return group.copyWith(collapsed: true);
        }

        return group;
      },
    );
  }

  Size _dialogSizeForWorkspace() {
    final width = state.workspaceSize.width;
    final height = state.workspaceSize.height;

    final rawWidth = width * 0.90;
    final rawHeight = height * 0.90;

    final clampedWidth = rawWidth.clamp(
      DockPanelConfig.minFloatingWidth,
      width > 0 ? width - 24 : DockPanelConfig.maxFloatingWidth,
    );

    final clampedHeight = rawHeight.clamp(
      DockPanelConfig.minFloatingHeight,
      height > 0 ? height - 24 : DockPanelConfig.maxFloatingHeight,
    );

    return Size(
      clampedWidth.toDouble(),
      clampedHeight.toDouble(),
    );
  }

  Offset _dialogOffsetForSize(Size size) {
    final width = state.workspaceSize.width;
    final height = state.workspaceSize.height;

    final desired = Offset(
      (width - size.width) / 2,
      (height - size.height) / 2,
    );

    return DockPanelLogic.clampFloatingOffset(
      desired: desired,
      floatingSize: size,
      workspaceSize: state.workspaceSize,
    );
  }

  void toggleFloating(String groupId) {
    final current = state.groupById(groupId);

    if (current.area == DockArea.floating && current.floatingAsDialog) {
      if (current.restoreToFloatingOnDialogClose) {
        _updateGroups(
          commit: true,
          normalize: true,
          transform: (group) {
            if (group.id != groupId) return group;

            return group.copyWith(
              area: DockArea.floating,
              crossSpan: DockCrossSpan.full,
              floatingAsDialog: false,
              restoreToFloatingOnDialogClose: false,
              floatingOffset: current.storedFloatingOffset,
              floatingSize: current.storedFloatingSize,
              visible: true,
              collapsed: false,
              minimized: false,
            );
          },
        );
        return;
      }

      final restoreArea = current.lastDockArea ?? DockArea.left;
      final restoreSpan = current.lastDockCrossSpan ?? DockCrossSpan.full;

      _updateGroups(
        commit: true,
        normalize: true,
        preferredFullArea: restoreSpan == DockCrossSpan.full ? restoreArea : null,
        transform: (group) {
          if (group.id != groupId) return group;
          return group.copyWith(
            area: restoreArea,
            crossSpan: restoreSpan,
            visible: true,
            collapsed: false,
            minimized: false,
            floatingAsDialog: false,
            restoreToFloatingOnDialogClose: false,
          );
        },
      );
      return;
    }

    final dialogSize = _dialogSizeForWorkspace();
    final dialogOffset = _dialogOffsetForSize(dialogSize);

    if (current.area == DockArea.floating) {
      _updateGroups(
        commit: true,
        normalize: true,
        transform: (group) {
          if (group.id != groupId) return group;
          return group.copyWith(
            area: DockArea.floating,
            crossSpan: DockCrossSpan.full,
            visible: true,
            collapsed: false,
            minimized: false,
            floatingAsDialog: true,
            restoreToFloatingOnDialogClose: true,
            storedFloatingOffset: current.floatingOffset,
            storedFloatingSize: current.floatingSize,
            floatingOffset: dialogOffset,
            floatingSize: dialogSize,
          );
        },
      );
      return;
    }

    _updateGroups(
      commit: true,
      normalize: true,
      transform: (group) {
        if (group.id != groupId) return group;
        return group.copyWith(
          area: DockArea.floating,
          crossSpan: DockCrossSpan.full,
          visible: true,
          collapsed: false,
          minimized: false,
          floatingAsDialog: true,
          restoreToFloatingOnDialogClose: false,
          lastDockArea: group.area == DockArea.floating ? group.lastDockArea : group.area,
          lastDockCrossSpan:
          group.area == DockArea.floating ? group.lastDockCrossSpan : group.crossSpan,
          storedFloatingOffset: group.floatingOffset,
          storedFloatingSize: group.floatingSize,
          floatingOffset: dialogOffset,
          floatingSize: dialogSize,
        );
      },
    );
  }

  bool _shouldUpdateDragState({
    required String groupId,
    required DockArea? snap,
    required Offset local,
  }) {
    if (!state.isDragging) return true;
    if (state.draggingGroupId != groupId) return true;
    if (state.hoveredSnapArea != snap) return true;
    if (state.lastDragLocalPosition == null) return true;

    final dx = (local.dx - state.lastDragLocalPosition!.dx).abs();
    final dy = (local.dy - state.lastDragLocalPosition!.dy).abs();

    return dx >= DockPanelConfig.dragUpdateThreshold ||
        dy >= DockPanelConfig.dragUpdateThreshold;
  }

  void startDrag(String groupId) {
    if (state.isDragging) return;

    final group = state.groupById(groupId);
    if (group.collapsed) return;

    emit(
      state.copyWith(
        isDragging: true,
        draggingGroupId: groupId,
      ),
    );
  }

  void updateDrag(String groupId, Offset localPosition) {
    if (state.workspaceSize.isEmpty) return;

    final snap = DockPanelLogic.resolveSnapArea(
      localPosition: localPosition,
      workspaceSize: state.workspaceSize,
      snapThickness: snapThickness,
    );

    if (_shouldUpdateDragState(
      groupId: groupId,
      snap: snap,
      local: localPosition,
    )) {
      emit(
        state.copyWith(
          isDragging: true,
          draggingGroupId: groupId,
          hoveredSnapArea: snap,
          lastDragLocalPosition: localPosition,
        ),
      );
    }
  }

  List<DockPanelData> projectDocking({
    required String groupId,
    required DockArea targetArea,
    required Offset localPosition,
  }) {
    return DockPanelLogic.projectDocking(
      workingGroups: state.workingGroups,
      groupId: groupId,
      targetArea: targetArea,
      localPosition: localPosition,
      workspaceSize: state.workspaceSize,
    );
  }

  void endDrag({
    required String groupId,
    required Offset fallbackLocalPosition,
  }) {
    final sourceGroup = state.groupById(groupId);
    final releaseLocalPosition = state.lastDragLocalPosition ?? fallbackLocalPosition;

    final releaseSnap = state.workspaceSize.isEmpty
        ? null
        : DockPanelLogic.resolveSnapArea(
      localPosition: releaseLocalPosition,
      workspaceSize: state.workspaceSize,
      snapThickness: snapThickness,
    );

    if (releaseSnap != null) {
      final projected = projectDocking(
        groupId: groupId,
        targetArea: releaseSnap,
        localPosition: releaseLocalPosition,
      ).map((group) {
        if (group.id != groupId) return group;
        return group.copyWith(
          collapsed: false,
          floatingAsDialog: false,
          restoreToFloatingOnDialogClose: false,
        );
      }).toList(growable: false);

      _commitGroups(projected);
    } else {
      final desiredFloatingOffset = Offset(
        releaseLocalPosition.dx - (sourceGroup.floatingSize.width * 0.35),
        releaseLocalPosition.dy - 18,
      );

      final bounded = DockPanelLogic.clampFloatingOffset(
        desired: desiredFloatingOffset,
        floatingSize: sourceGroup.floatingSize,
        workspaceSize: state.workspaceSize,
      );

      _updateGroups(
        commit: true,
        normalize: true,
        transform: (current) {
          if (current.id != groupId) return current;

          return current.copyWith(
            area: DockArea.floating,
            crossSpan: DockCrossSpan.full,
            collapsed: false,
            floatingOffset: bounded,
            minimized: false,
            floatingAsDialog: false,
            restoreToFloatingOnDialogClose: false,
            lastDockArea:
            current.area == DockArea.floating ? current.lastDockArea : current.area,
            lastDockCrossSpan:
            current.area == DockArea.floating ? current.lastDockCrossSpan : current.crossSpan,
          );
        },
      );
    }

    emit(
      state.copyWith(
        isDragging: false,
        clearHoveredSnapArea: true,
        clearDraggingGroupId: true,
        clearLastDragLocalPosition: true,
      ),
    );
  }

  void startDockExtentResize() {
    if (state.isDockExtentResizing) return;
    emit(state.copyWith(isDockExtentResizing: true));
  }

  void endDockExtentResize() {
    onCommit(List<DockPanelData>.from(state.workingGroups));
    emit(state.copyWith(isDockExtentResizing: false));
  }

  void resizeAreaExtent(DockArea area, double rawDelta) {
    final groups = state.groupsInArea(area);
    if (groups.isEmpty) return;

    final currentExtent = state.resolvedDockExtent(area);

    late final double next;

    switch (area) {
      case DockArea.left:
        next = (currentExtent + rawDelta)
            .clamp(
          DockPanelConfig.minDockSideExtent,
          DockPanelConfig.maxDockSideExtent,
        )
            .toDouble();
        break;
      case DockArea.right:
        next = (currentExtent - rawDelta)
            .clamp(
          DockPanelConfig.minDockSideExtent,
          DockPanelConfig.maxDockSideExtent,
        )
            .toDouble();
        break;
      case DockArea.top:
        next = (currentExtent + rawDelta)
            .clamp(
          DockPanelConfig.minDockTopBottomExtent,
          DockPanelConfig.maxDockTopBottomExtent,
        )
            .toDouble();
        break;
      case DockArea.bottom:
        next = (currentExtent - rawDelta)
            .clamp(
          DockPanelConfig.minDockTopBottomExtent,
          DockPanelConfig.maxDockTopBottomExtent,
        )
            .toDouble();
        break;
      case DockArea.floating:
        return;
    }

    final updates = <String, DockPanelData>{};
    for (final g in groups) {
      if (g.dockExtent != next) {
        updates[g.id] = g.copyWith(dockExtent: next);
      }
    }

    _updateManyGroupsLocal(updates);
  }

  void startDockWeightResize() {
    if (state.isDockWeightResizing) return;
    emit(state.copyWith(isDockWeightResizing: true));
  }

  void endDockWeightResize() {
    onCommit(List<DockPanelData>.from(state.workingGroups));
    emit(state.copyWith(isDockWeightResizing: false));
  }

  void resizeDockWeights({
    required List<DockPanelData> groups,
    required int leadingIndex,
    required double deltaPixels,
    required double totalAvailablePixels,
  }) {
    if (groups.length < 2) return;
    if (leadingIndex < 0 || leadingIndex >= groups.length - 1) return;
    if (totalAvailablePixels <= 0) return;

    final first = groups[leadingIndex];
    final second = groups[leadingIndex + 1];

    final totalWeight = first.dockWeight + second.dockWeight;
    if (totalWeight <= 0) return;

    final deltaWeight = (deltaPixels / totalAvailablePixels) * totalWeight;

    var newFirst = first.dockWeight + deltaWeight;
    var newSecond = second.dockWeight - deltaWeight;

    if (newFirst < DockPanelConfig.minDockWeight) {
      final diff = DockPanelConfig.minDockWeight - newFirst;
      newFirst += diff;
      newSecond -= diff;
    }

    if (newSecond < DockPanelConfig.minDockWeight) {
      final diff = DockPanelConfig.minDockWeight - newSecond;
      newSecond += diff;
      newFirst -= diff;
    }

    if (newFirst < DockPanelConfig.minDockWeight ||
        newSecond < DockPanelConfig.minDockWeight) {
      return;
    }

    _updateManyGroupsLocal({
      first.id: first.copyWith(dockWeight: newFirst),
      second.id: second.copyWith(dockWeight: newSecond),
    });
  }

  void startFloatingResize() {
    if (state.isFloatingResizing) return;
    emit(state.copyWith(isFloatingResizing: true));
  }

  void resizeFloatingGroup(String groupId, DragUpdateDetails details) {
    final group = state.groupById(groupId);
    if (group.floatingAsDialog) return;

    final current = group.floatingSize;

    final unclamped = Size(
      current.width + details.delta.dx,
      current.height + details.delta.dy,
    );

    final nextSize = DockPanelLogic.clampFloatingSize(
      desired: unclamped,
      workspaceSize: state.workspaceSize,
    );

    final nextOffset = DockPanelLogic.clampFloatingOffset(
      desired: group.floatingOffset,
      floatingSize: nextSize,
      workspaceSize: state.workspaceSize,
    );

    _updateGroups(
      commit: false,
      transform: (currentGroup) {
        if (currentGroup.id != groupId) return currentGroup;
        return currentGroup.copyWith(
          floatingSize: nextSize,
          floatingOffset: nextOffset,
        );
      },
    );
  }

  void endFloatingResize() {
    onCommit(List<DockPanelData>.from(state.workingGroups));
    emit(state.copyWith(isFloatingResizing: false));
  }
}