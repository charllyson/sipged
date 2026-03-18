import 'package:flutter/material.dart';
import 'package:sipged/_widgets/docking/dock_panel_docked_layout.dart';
import 'package:sipged/_widgets/docking/dock_panel_floating_layer.dart';
import 'package:sipged/_widgets/docking/dock_panel_group_card.dart';
import 'package:sipged/_widgets/docking/dock_panel_snap_overlay.dart';
import 'package:sipged/_widgets/docking/dock_panel_types.dart';
import 'package:sipged/_widgets/docking/dock_panel_workspace_config.dart';
import 'package:sipged/_widgets/docking/dock_panel_workspace_logic.dart';

class DockPanelWorkspace extends StatefulWidget {
  final Widget child;
  final List<DockPanelGroupData> groups;
  final ValueChanged<List<DockPanelGroupData>> onChanged;
  final EdgeInsets contentPadding;
  final double snapThickness;
  final Color? backgroundOverlayColor;

  const DockPanelWorkspace({
    super.key,
    required this.child,
    required this.groups,
    required this.onChanged,
    this.contentPadding = EdgeInsets.zero,
    this.snapThickness = 16,
    this.backgroundOverlayColor,
  });

  @override
  State<DockPanelWorkspace> createState() => _DockPanelWorkspaceState();
}

class _DockPanelWorkspaceState extends State<DockPanelWorkspace> {
  final GlobalKey _stackKey = GlobalKey();

  late List<DockPanelGroupData> _workingGroups;

  bool _isDragging = false;
  DockArea? _hoveredSnapArea;
  String? _draggingGroupId;
  Offset? _lastDragLocalPosition;

  bool _isDockExtentResizing = false;
  bool _isDockWeightResizing = false;
  bool _isFloatingResizing = false;

  Size _workspaceSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _workingGroups = DockPanelWorkspaceLogic.normalizeDockSpans(
      List<DockPanelGroupData>.from(widget.groups),
    );
  }

  @override
  void didUpdateWidget(covariant DockPanelWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);

    final preserveLayout = _isDragging ||
        _isDockExtentResizing ||
        _isDockWeightResizing ||
        _isFloatingResizing;

    _workingGroups = DockPanelWorkspaceLogic.normalizeDockSpans(
      DockPanelWorkspaceLogic.mergeIncomingGroups(
        incoming: widget.groups,
        current: _workingGroups,
        preserveLayout: preserveLayout,
      ),
    );
  }

  List<DockPanelGroupData> get _visibleGroups =>
      _workingGroups.where((g) => g.visible).toList(growable: false);

  DockPanelGroupData _groupById(String id) =>
      _workingGroups.firstWhere((g) => g.id == id);

  List<DockPanelGroupData> _groupsInArea(DockArea area) {
    return _visibleGroups.where((g) => g.area == area).toList(growable: false);
  }

  void _setWorkingGroups(List<DockPanelGroupData> next) {
    setState(() {
      _workingGroups = next;
    });
  }

  void _commitWorkingGroups() {
    widget.onChanged(List<DockPanelGroupData>.from(_workingGroups));
  }

  void _updateGroupLocal(
      String id,
      DockPanelGroupData Function(DockPanelGroupData current) update,
      ) {
    final next = _workingGroups.map((group) {
      if (group.id != id) return group;
      return update(group);
    }).toList(growable: false);

    _setWorkingGroups(next);
  }

  void _updateManyGroupsLocal(Map<String, DockPanelGroupData> updatesById) {
    final next = _workingGroups.map((group) {
      return updatesById[group.id] ?? group;
    }).toList(growable: false);

    _setWorkingGroups(next);
  }

  void _updateGroupAndCommit(
      String id,
      DockPanelGroupData Function(DockPanelGroupData current) update,
      ) {
    _updateGroupLocal(id, update);
    _commitWorkingGroups();
  }

  void _setGroupVisible(String id, bool visible) {
    final next = DockPanelWorkspaceLogic.normalizeDockSpans(
      _workingGroups.map((group) {
        if (group.id != id) return group;
        return group.copyWith(visible: visible);
      }).toList(growable: false),
    );

    _setWorkingGroups(next);
    _commitWorkingGroups();
  }

  void _setGroupActiveItem(String groupId, String itemId) {
    _updateGroupAndCommit(
      groupId,
          (current) => current.copyWith(activeItemId: itemId),
    );
  }

  Rect _workspaceRect() {
    final renderBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Rect.zero;
    return Offset.zero & renderBox.size;
  }

  Offset _globalToLocal(Offset globalOffset) {
    final renderBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return globalOffset;
    return renderBox.globalToLocal(globalOffset);
  }

  bool _shouldUpdateDragState({
    required String groupId,
    required DockArea? snap,
    required Offset local,
  }) {
    if (!_isDragging) return true;
    if (_draggingGroupId != groupId) return true;
    if (_hoveredSnapArea != snap) return true;
    if (_lastDragLocalPosition == null) return true;

    final dx = (local.dx - _lastDragLocalPosition!.dx).abs();
    final dy = (local.dy - _lastDragLocalPosition!.dy).abs();

    return dx >= DockPanelWorkspaceConfig.dragUpdateThreshold ||
        dy >= DockPanelWorkspaceConfig.dragUpdateThreshold;
  }

  void _handleDragUpdate(String groupId, DragUpdateDetails details) {
    final local = _globalToLocal(details.globalPosition);
    final snap = DockPanelWorkspaceLogic.resolveSnapArea(
      localPosition: local,
      workspaceSize: _workspaceSize,
      snapThickness: widget.snapThickness,
    );

    if (_shouldUpdateDragState(groupId: groupId, snap: snap, local: local)) {
      setState(() {
        _isDragging = true;
        _hoveredSnapArea = snap;
        _draggingGroupId = groupId;
        _lastDragLocalPosition = local;
      });
    }
  }

  List<DockPanelGroupData> _projectDocking({
    required String groupId,
    required DockArea targetArea,
    required Offset localPosition,
  }) {
    return DockPanelWorkspaceLogic.projectDocking(
      workingGroups: _workingGroups,
      groupId: groupId,
      targetArea: targetArea,
      localPosition: localPosition,
      workspaceSize: _workspaceSize,
    );
  }

  void _handleDragEnd(String groupId, DraggableDetails details) {
    final local = _lastDragLocalPosition;
    final snap = _hoveredSnapArea;

    if (local != null && snap != null) {
      final projected = _projectDocking(
        groupId: groupId,
        targetArea: snap,
        localPosition: local,
      );
      _setWorkingGroups(projected);
      _commitWorkingGroups();
    } else {
      final rect = _workspaceRect();
      final group = _groupById(groupId);

      final fallbackLocal = _globalToLocal(details.offset);
      final desired = Offset(fallbackLocal.dx, fallbackLocal.dy);

      final bounded = DockPanelWorkspaceLogic.clampFloatingOffset(
        desired: desired,
        floatingSize: group.floatingSize,
        workspaceSize: rect.size,
      );

      final next = DockPanelWorkspaceLogic.normalizeDockSpans(
        _workingGroups.map((current) {
          if (current.id != groupId) return current;
          return current.copyWith(
            area: DockArea.floating,
            crossSpan: DockCrossSpan.full,
            floatingOffset: bounded,
          );
        }).toList(growable: false),
      );

      _setWorkingGroups(next);
      _commitWorkingGroups();
    }

    if (mounted) {
      setState(() {
        _isDragging = false;
        _hoveredSnapArea = null;
        _draggingGroupId = null;
        _lastDragLocalPosition = null;
      });
    }
  }

  void _resizeDockWeightsLocal({
    required List<DockPanelGroupData> groups,
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

    final deltaWeight = deltaPixels / totalAvailablePixels * totalWeight;

    var newFirst = first.dockWeight + deltaWeight;
    var newSecond = second.dockWeight - deltaWeight;

    if (newFirst < DockPanelWorkspaceConfig.minDockWeight) {
      final diff = DockPanelWorkspaceConfig.minDockWeight - newFirst;
      newFirst += diff;
      newSecond -= diff;
    }

    if (newSecond < DockPanelWorkspaceConfig.minDockWeight) {
      final diff = DockPanelWorkspaceConfig.minDockWeight - newSecond;
      newSecond += diff;
      newFirst -= diff;
    }

    if (newFirst < DockPanelWorkspaceConfig.minDockWeight ||
        newSecond < DockPanelWorkspaceConfig.minDockWeight) {
      return;
    }

    _updateManyGroupsLocal({
      first.id: first.copyWith(dockWeight: newFirst),
      second.id: second.copyWith(dockWeight: newSecond),
    });
  }

  void _handleAreaExtentResize(DockArea area, double rawDelta) {
    final groups = _groupsInArea(area);
    if (groups.isEmpty) return;

    double currentExtent = DockPanelWorkspaceLogic.resolvedDockExtentForArea(
      area,
      _workingGroups,
    );

    double next;
    switch (area) {
      case DockArea.left:
        next = (currentExtent + rawDelta)
            .clamp(
          DockPanelWorkspaceConfig.minDockSideExtent,
          DockPanelWorkspaceConfig.maxDockSideExtent,
        )
            .toDouble();
        break;
      case DockArea.right:
        next = (currentExtent - rawDelta)
            .clamp(
          DockPanelWorkspaceConfig.minDockSideExtent,
          DockPanelWorkspaceConfig.maxDockSideExtent,
        )
            .toDouble();
        break;
      case DockArea.top:
        next = (currentExtent + rawDelta)
            .clamp(
          DockPanelWorkspaceConfig.minDockTopBottomExtent,
          DockPanelWorkspaceConfig.maxDockTopBottomExtent,
        )
            .toDouble();
        break;
      case DockArea.bottom:
        next = (currentExtent - rawDelta)
            .clamp(
          DockPanelWorkspaceConfig.minDockTopBottomExtent,
          DockPanelWorkspaceConfig.maxDockTopBottomExtent,
        )
            .toDouble();
        break;
      case DockArea.floating:
        return;
    }

    final updates = <String, DockPanelGroupData>{};
    for (final g in groups) {
      updates[g.id] = g.copyWith(dockExtent: next);
    }
    _updateManyGroupsLocal(updates);
  }

  Widget _buildGroupCard(DockPanelGroupData group, bool isFloating) {
    final isGroupDragging = _isDragging && _draggingGroupId == group.id;

    return KeyedSubtree(
      key: ValueKey('${isFloating ? 'float' : 'dock'}_${group.id}'),
      child: DockPanelGroupCard(
        group: group,
        isFloating: isFloating,
        isDragging: isGroupDragging,
        onToggleFloating: () {
          if (isFloating) {
            final projected = _projectDocking(
              groupId: group.id,
              targetArea: DockArea.left,
              localPosition: const Offset(0, 0),
            );
            _setWorkingGroups(projected);
            _commitWorkingGroups();
          } else {
            final next = DockPanelWorkspaceLogic.normalizeDockSpans(
              _workingGroups.map((current) {
                if (current.id != group.id) return current;
                return current.copyWith(
                  area: DockArea.floating,
                  crossSpan: DockCrossSpan.full,
                );
              }).toList(growable: false),
            );
            _setWorkingGroups(next);
            _commitWorkingGroups();
          }
        },
        onHide: () => _setGroupVisible(group.id, false),
        onTabSelected: (itemId) => _setGroupActiveItem(group.id, itemId),
        onDragStarted: () {
          if (!_isDragging) {
            setState(() {
              _isDragging = true;
              _draggingGroupId = group.id;
            });
          }
        },
        onDragUpdate: (details) => _handleDragUpdate(group.id, details),
        onDragEnd: (details) => _handleDragEnd(group.id, details),
        onResizeStart: () {
          setState(() {
            _isFloatingResizing = true;
          });
        },
        onResizeUpdate: (details) {
          final current = _groupById(group.id).floatingSize;
          final next = Size(
            (current.width + details.delta.dx)
                .clamp(
              DockPanelWorkspaceConfig.minFloatingWidth,
              DockPanelWorkspaceConfig.maxFloatingWidth,
            )
                .toDouble(),
            (current.height + details.delta.dy)
                .clamp(
              DockPanelWorkspaceConfig.minFloatingHeight,
              DockPanelWorkspaceConfig.maxFloatingHeight,
            )
                .toDouble(),
          );

          _updateGroupLocal(
            group.id,
                (currentGroup) => currentGroup.copyWith(floatingSize: next),
          );
        },
        onResizeEnd: (_) {
          _commitWorkingGroups();
          if (mounted) {
            setState(() {
              _isFloatingResizing = false;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final nextSize = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
        );

        if (_workspaceSize != nextSize) {
          _workspaceSize = nextSize;
        }

        final leftGroups = _groupsInArea(DockArea.left);
        final rightGroups = _groupsInArea(DockArea.right);
        final topGroups = _groupsInArea(DockArea.top);
        final bottomGroups = _groupsInArea(DockArea.bottom);
        final floatingGroups = _groupsInArea(DockArea.floating);

        final leftWidth = DockPanelWorkspaceLogic.resolvedDockExtentForArea(
          DockArea.left,
          _workingGroups,
        );
        final rightWidth = DockPanelWorkspaceLogic.resolvedDockExtentForArea(
          DockArea.right,
          _workingGroups,
        );
        final topHeight = DockPanelWorkspaceLogic.resolvedDockExtentForArea(
          DockArea.top,
          _workingGroups,
        );
        final bottomHeight = DockPanelWorkspaceLogic.resolvedDockExtentForArea(
          DockArea.bottom,
          _workingGroups,
        );

        final leftSpan = DockPanelWorkspaceLogic.resolvedCrossSpanForArea(
          DockArea.left,
          _workingGroups,
        );
        final rightSpan = DockPanelWorkspaceLogic.resolvedCrossSpanForArea(
          DockArea.right,
          _workingGroups,
        );
        final topSpan = DockPanelWorkspaceLogic.resolvedCrossSpanForArea(
          DockArea.top,
          _workingGroups,
        );
        final bottomSpan = DockPanelWorkspaceLogic.resolvedCrossSpanForArea(
          DockArea.bottom,
          _workingGroups,
        );

        final previewRect = DockPanelWorkspaceLogic.projectedPreviewRect(
          isDragging: _isDragging,
          hoveredSnapArea: _hoveredSnapArea,
          draggingGroupId: _draggingGroupId,
          lastDragLocalPosition: _lastDragLocalPosition,
          workingGroups: _workingGroups,
          workspaceSize: _workspaceSize,
        );

        return SizedBox(
          key: _stackKey,
          child: Stack(
            children: [
              DockPanelDockedLayout(
                contentPadding: widget.contentPadding,
                leftGroups: leftGroups,
                rightGroups: rightGroups,
                topGroups: topGroups,
                bottomGroups: bottomGroups,
                leftWidth: leftWidth,
                rightWidth: rightWidth,
                topHeight: topHeight,
                bottomHeight: bottomHeight,
                leftSpan: leftSpan,
                rightSpan: rightSpan,
                topSpan: topSpan,
                bottomSpan: bottomSpan,
                buildGroupCard: _buildGroupCard,
                onSideExtentResizeStart: () {
                  setState(() {
                    _isDockExtentResizing = true;
                  });
                },
                onSideExtentResizeEnd: () {
                  _commitWorkingGroups();
                  if (mounted) {
                    setState(() {
                      _isDockExtentResizing = false;
                    });
                  }
                },
                onSideExtentResize: _handleAreaExtentResize,
                onWeightResizeStart: () {
                  setState(() {
                    _isDockWeightResizing = true;
                  });
                },
                onWeightResizeEnd: () {
                  _commitWorkingGroups();
                  if (mounted) {
                    setState(() {
                      _isDockWeightResizing = false;
                    });
                  }
                },
                onWeightResize: (
                    groups,
                    leadingIndex,
                    deltaPixels,
                    totalPixels,
                    ) {
                  _resizeDockWeightsLocal(
                    groups: groups,
                    leadingIndex: leadingIndex,
                    deltaPixels: deltaPixels,
                    totalAvailablePixels: totalPixels,
                  );
                },
                child: widget.child,
              ),
              DockPanelFloatingLayer(
                floatingGroups: floatingGroups,
                workspaceSize: _workspaceSize,
                buildGroupCard: _buildGroupCard,
              ),
              DockPanelSnapOverlay(
                visible: _isDragging,
                snapArea: _hoveredSnapArea,
                previewRect: previewRect,
                backgroundOverlayColor: widget.backgroundOverlayColor,
              ),
            ],
          ),
        );
      },
    );
  }
}