import 'package:flutter/material.dart';

import 'package:sipged/_widgets/panels/docking/dock_panel_controller.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_data.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_state.dart';

import 'package:sipged/_widgets/panels/docking/dock_panel_floating.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_group.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_layout.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_snap.dart';

class DockPanelWorkspace extends StatefulWidget {
  const DockPanelWorkspace({
    super.key,
    required this.child,
    required this.groups,
    required this.onChanged,
    this.controller,
    this.contentPadding = EdgeInsets.zero,
    this.snapThickness = 16,
    this.backgroundOverlayColor,
    this.contentMinSize = Size.zero,
  });

  final Widget child;

  final List<DockPanelData> groups;

  final ValueChanged<List<DockPanelData>> onChanged;

  /// Controller externo opcional.
  ///
  /// Se informado, o widget não cria controller interno.
  /// Útil quando a tela pai precisa controlar ou observar o estado do dock.
  final DockPanelController? controller;

  final EdgeInsets contentPadding;

  final double snapThickness;

  final Color? backgroundOverlayColor;

  /// Use Size.zero para mapas.
  ///
  /// Assim o mapa ocupa somente a área útil restante entre os docks,
  /// sem criar canvas virtual maior que a tela.
  final Size contentMinSize;

  @override
  State<DockPanelWorkspace> createState() => _DockPanelWorkspaceState();
}

class _DockPanelWorkspaceState extends State<DockPanelWorkspace> {
  final GlobalKey _stackKey = GlobalKey();

  late DockPanelController _controller;

  bool _ownsController = false;

  @override
  void initState() {
    super.initState();

    _setupController();
  }

  void _setupController() {
    final externalController = widget.controller;

    if (externalController != null) {
      _controller = externalController;
      _ownsController = false;
      _controller.updateOnCommit(widget.onChanged);
      return;
    }

    _controller = _createController();
    _ownsController = true;
  }

  DockPanelController _createController() {
    return DockPanelController(
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
      List<DockPanelData> a,
      List<DockPanelData> b,
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

    final controllerChanged = oldWidget.controller != widget.controller;

    if (controllerChanged) {
      if (_ownsController) {
        _controller.dispose();
      }

      _setupController();

      return;
    }

    _controller.updateOnCommit(widget.onChanged);

    final mustRecreateInternalController =
        widget.controller == null &&
            oldWidget.snapThickness != widget.snapThickness;

    if (mustRecreateInternalController) {
      final oldController = _controller;

      _controller = _createController();
      _ownsController = true;

      oldController.dispose();

      return;
    }

    final layoutChanged = !_sameExternalLayout(
      oldWidget.groups,
      widget.groups,
    );

    if (layoutChanged) {
      _controller.syncFromExternal(widget.groups);
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }

    super.dispose();
  }

  Offset _globalToLocal(Offset globalOffset) {
    final renderBox = _stackKey.currentContext?.findRenderObject();

    if (renderBox is! RenderBox) {
      return globalOffset;
    }

    return renderBox.globalToLocal(globalOffset);
  }

  Object? _activeItemContentToken(DockPanelData group) {
    return group.activeItem?.contentToken;
  }

  Key _groupKey(
      DockPanelData group,
      bool isFloating,
      ) {
    final activeToken = _activeItemContentToken(group);

    return ValueKey(
      '${isFloating ? 'float' : 'dock'}_'
          '${group.id}_'
          '${group.floatingAsDialog}_'
          '${group.collapsed}_'
          '${group.visible}_'
          '${group.minimized}_'
          '${group.activeItemId}_'
          '${group.items.length}_'
          '${activeToken ?? 'no_token'}',
    );
  }

  Widget _buildGroupCard(
      DockPanelState state,
      DockPanelData group,
      bool isFloating,
      ) {
    final isGroupDragging =
        state.isDragging && state.draggingGroupId == group.id;

    return KeyedSubtree(
      key: _groupKey(group, isFloating),
      child: DockPanelGroup(
        group: group,
        isFloating: isFloating,
        isDragging: isGroupDragging,
        onToggleFloating: () => _controller.toggleFloating(group.id),
        onHide: () => _controller.setGroupVisible(group.id, false),
        onMinimize: () => _controller.setGroupVisible(group.id, false),
        onTabSelected: (itemId) {
          _controller.setGroupActiveItem(
            group.id,
            itemId,
          );
        },
        onDragStarted: () {
          _controller.startDrag(group.id);
        },
        onDragUpdate: (details) {
          final local = _globalToLocal(details.globalPosition);

          _controller.updateDrag(
            group.id,
            local,
          );
        },
        onDragEnd: (details) {
          final fallbackLocal = _globalToLocal(details.offset);

          _controller.endDrag(
            groupId: group.id,
            fallbackLocalPosition: fallbackLocal,
          );
        },
        onResizeStart: _controller.startFloatingResize,
        onResizeUpdate: (details) {
          _controller.resizeFloatingGroup(
            group.id,
            details,
          );
        },
        onResizeEnd: (_) {
          _controller.endFloatingResize();
        },
      ),
    );
  }

  void _syncWorkspaceSizeIfNeeded(
      Size nextWorkspaceSize,
      DockPanelState state,
      ) {
    if (nextWorkspaceSize.width <= 0 || nextWorkspaceSize.height <= 0) {
      return;
    }

    if (state.workspaceSize == nextWorkspaceSize) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _controller.setWorkspaceSize(nextWorkspaceSize);
    });
  }

  Size _effectiveWorkspaceSize(
      Size nextWorkspaceSize,
      DockPanelState state,
      ) {
    if (nextWorkspaceSize.width > 0 && nextWorkspaceSize.height > 0) {
      return nextWorkspaceSize;
    }

    if (state.workspaceSize.width > 0 && state.workspaceSize.height > 0) {
      return state.workspaceSize;
    }

    return Size.zero;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return LayoutBuilder(
          builder: (context, constraints) {
            final nextWorkspaceSize = Size(
              constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
              constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
            );

            _syncWorkspaceSizeIfNeeded(
              nextWorkspaceSize,
              state,
            );

            final effectiveWorkspaceSize = _effectiveWorkspaceSize(
              nextWorkspaceSize,
              state,
            );

            return SizedBox.expand(
              key: _stackKey,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.white,
                    ),
                  ),

                  Positioned.fill(
                    child: DockPanelLayout(
                      state: state,
                      contentPadding: widget.contentPadding,
                      contentMinSize: widget.contentMinSize,
                      buildGroupCard: (group, isFloating) {
                        return _buildGroupCard(
                          state,
                          group,
                          isFloating,
                        );
                      },
                      onSideExtentResizeStart:
                      _controller.startDockExtentResize,
                      onSideExtentResizeEnd:
                      _controller.endDockExtentResize,
                      onSideExtentResize:
                      _controller.resizeAreaExtent,
                      onWeightResizeStart:
                      _controller.startDockWeightResize,
                      onWeightResizeEnd:
                      _controller.endDockWeightResize,
                      onWeightResize: (
                          groups,
                          leadingIndex,
                          deltaPixels,
                          totalPixels,
                          ) {
                        _controller.resizeDockWeights(
                          groups: groups,
                          leadingIndex: leadingIndex,
                          deltaPixels: deltaPixels,
                          totalAvailablePixels: totalPixels,
                        );
                      },
                      child: widget.child,
                    ),
                  ),

                  if (state.hasDialogPanel)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.16),
                        ),
                      ),
                    ),

                  if (effectiveWorkspaceSize.width > 0 &&
                      effectiveWorkspaceSize.height > 0)
                    Positioned.fill(
                      child: DockPanelFloating(
                        floatingGroups: state.floatingGroups,
                        workspaceSize: effectiveWorkspaceSize,
                        buildGroupCard: (group, isFloating) {
                          return _buildGroupCard(
                            state,
                            group,
                            isFloating,
                          );
                        },
                      ),
                    ),

                  DockPanelSnap(
                    visible: state.isDragging,
                    snapArea: state.hoveredSnapArea,
                    previewRect: state.previewRect,
                    backgroundOverlayColor: widget.backgroundOverlayColor,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}