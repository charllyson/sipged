import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data_item.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_state.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_floating.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_group.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_layout.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_side_rail.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_snap_overlay.dart';

class DockPanelWorkspace extends StatefulWidget {
  final Widget child;
  final List<DockPanelData> groups;
  final ValueChanged<List<DockPanelData>> onChanged;
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
  late final DockPanelCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = DockPanelCubit(
      initialGroups: widget.groups,
      onCommit: widget.onChanged,
      snapThickness: widget.snapThickness,
    );
  }

  bool _sameExternalLayout(
      List<DockPanelData> a,
      List<DockPanelData> b,
      ) {
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (!_sameGroupLayout(a[i], b[i])) return false;
    }

    return true;
  }

  bool _sameGroupLayout(
      DockPanelData a,
      DockPanelData b,
      ) {
    return a.id == b.id &&
        a.title == b.title &&
        a.area == b.area &&
        a.crossSpan == b.crossSpan &&
        a.activeItemId == b.activeItemId &&
        a.visible == b.visible &&
        a.collapsed == b.collapsed &&
        a.floatingOffset == b.floatingOffset &&
        a.floatingSize == b.floatingSize &&
        a.dockExtent == b.dockExtent &&
        a.dockWeight == b.dockWeight &&
        a.icon == b.icon &&
        a.accentColor == b.accentColor &&
        a.shrinkWrapOnMainAxis == b.shrinkWrapOnMainAxis &&
        a.minimized == b.minimized &&
        a.lastDockArea == b.lastDockArea &&
        a.lastDockCrossSpan == b.lastDockCrossSpan &&
        a.floatingAsDialog == b.floatingAsDialog &&
        a.restoreToFloatingOnDialogClose == b.restoreToFloatingOnDialogClose &&
        a.storedFloatingOffset == b.storedFloatingOffset &&
        a.storedFloatingSize == b.storedFloatingSize &&
        _sameItemsMetadata(a.items, b.items);
  }

  bool _sameItemsMetadata(
      List<DockPanelDataItem> a,
      List<DockPanelDataItem> b,
      ) {
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];

      if (x.id != y.id ||
          x.title != y.title ||
          x.icon != y.icon ||
          x.contentPadding != y.contentPadding ||
          x.contentToken != y.contentToken) {
        return false;
      }
    }

    return true;
  }

  @override
  void didUpdateWidget(covariant DockPanelWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);

    final layoutChanged = !_sameExternalLayout(
      oldWidget.groups,
      widget.groups,
    );

    if (layoutChanged) {
      _cubit.syncFromExternal(widget.groups);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Offset _globalToLocal(Offset globalOffset) {
    final renderBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return globalOffset;
    return renderBox.globalToLocal(globalOffset);
  }

  Object? _activeItemContentToken(DockPanelData group) {
    return group.activeItem?.contentToken;
  }

  Widget _buildGroupCard(
      DockPanelState state,
      DockPanelData group,
      bool isFloating,
      ) {
    final isGroupDragging =
        state.isDragging && state.draggingGroupId == group.id;

    final activeToken = _activeItemContentToken(group);

    return KeyedSubtree(
      key: ValueKey(
        '${isFloating ? 'float' : 'dock'}_'
            '${group.id}_'
            '${group.floatingAsDialog}_'
            '${group.collapsed}_'
            '${group.visible}_'
            '${group.minimized}_'
            '${group.activeItemId}_'
            '${group.items.length}_'
            '${activeToken ?? 'no_token'}',
      ),
      child: DockPanelGroup(
        group: group,
        isFloating: isFloating,
        isDragging: isGroupDragging,
        onToggleFloating: () => _cubit.toggleFloating(group.id),
        onHide: () {
          final isSideArea =
              group.area == DockArea.left || group.area == DockArea.right;

          if (isSideArea) {
            _cubit.collapseToRail(group.id);
            return;
          }

          _cubit.setGroupVisible(group.id, false);
        },
        onMinimize: () => _cubit.setGroupVisible(group.id, false),
        onTabSelected: (itemId) => _cubit.setGroupActiveItem(group.id, itemId),
        onDragStarted: () => _cubit.startDrag(group.id),
        onDragUpdate: (details) {
          final local = _globalToLocal(details.globalPosition);
          _cubit.updateDrag(group.id, local);
        },
        onDragEnd: (details) {
          final fallbackLocal = _globalToLocal(details.offset);
          _cubit.endDrag(
            groupId: group.id,
            fallbackLocalPosition: fallbackLocal,
          );
        },
        onResizeStart: _cubit.startFloatingResize,
        onResizeUpdate: (details) =>
            _cubit.resizeFloatingGroup(group.id, details),
        onResizeEnd: (_) => _cubit.endFloatingResize(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DockPanelCubit>.value(
      value: _cubit,
      child: BlocBuilder<DockPanelCubit, DockPanelState>(
        builder: (context, state) {
          final hasDialogPanel =
          state.floatingGroups.any((g) => g.floatingAsDialog);

          final leftStandaloneRail =
              state.collapsedLeftGroups.isNotEmpty && state.leftGroups.isEmpty;

          final rightStandaloneRail =
              state.collapsedRightGroups.isNotEmpty && state.rightGroups.isEmpty;

          return LayoutBuilder(
            builder: (context, constraints) {
              final nextWorkspaceSize = Size(
                constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
                constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
              );

              if (_cubit.state.workspaceSize != nextWorkspaceSize) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _cubit.setWorkspaceSize(nextWorkspaceSize);
                });
              }

              return SizedBox(
                key: _stackKey,
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: Colors.white),
                    ),
                    Positioned.fill(
                      child: DockPanelLayout(
                        state: state,
                        contentPadding: widget.contentPadding,
                        buildGroupCard: (group, isFloating) =>
                            _buildGroupCard(state, group, isFloating),
                        onSideExtentResizeStart: _cubit.startDockExtentResize,
                        onSideExtentResizeEnd: _cubit.endDockExtentResize,
                        onSideExtentResize: _cubit.resizeAreaExtent,
                        onWeightResizeStart: _cubit.startDockWeightResize,
                        onWeightResizeEnd: _cubit.endDockWeightResize,
                        onWeightResize: (
                            groups,
                            leadingIndex,
                            deltaPixels,
                            totalPixels,
                            ) {
                          _cubit.resizeDockWeights(
                            groups: groups,
                            leadingIndex: leadingIndex,
                            deltaPixels: deltaPixels,
                            totalAvailablePixels: totalPixels,
                          );
                        },
                        child: widget.child,
                      ),
                    ),
                    if (hasDialogPanel)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.16),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: DockPanelFloating(
                        floatingGroups: state.floatingGroups,
                        workspaceSize: state.workspaceSize,
                        buildGroupCard: (group, isFloating) =>
                            _buildGroupCard(state, group, isFloating),
                      ),
                    ),
                    DockPanelSnapOverlay(
                      visible: state.isDragging,
                      snapArea: state.hoveredSnapArea,
                      previewRect: state.previewRect,
                      backgroundOverlayColor: widget.backgroundOverlayColor,
                    ),
                    if (state.collapsedLeftGroups.isNotEmpty)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: DockPanelSideRail(
                          side: DockArea.left,
                          groups: state.collapsedLeftGroups,
                          onGroupTap: _cubit.restoreFromRail,
                          standalone: leftStandaloneRail,
                        ),
                      ),
                    if (state.collapsedRightGroups.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: DockPanelSideRail(
                          side: DockArea.right,
                          groups: state.collapsedRightGroups,
                          onGroupTap: _cubit.restoreFromRail,
                          standalone: rightStandaloneRail,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}