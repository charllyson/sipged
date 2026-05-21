import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';

import 'package:sipged/screens/modules/planning/geo/layer/layer_draggable.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layer_group.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layer_root.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layer_row.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layer_target.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layer_toolbar.dart';

class LayerPanel extends StatefulWidget {
  final List<LayerData> layers;
  final Set<String> activeLayerIds;
  final void Function(String id, bool isActive) onToggleLayer;

  final String? currentUserId;

  final void Function(String id)? onRenameSelected;
  final void Function(String id)? onConnectLayer;
  final void Function(String id)? onOpenTable;
  final void Function(String id)? onRemoveSelected;

  final Future<void> Function(String? parentId, int? targetIndex)? onCreateLayer;
  final Future<void> Function(String? parentId, int? targetIndex)?
  onCreateEmptyGroup;

  final Map<String, bool> hasDataByLayer;
  final bool Function(LayerData layer)? supportsConnect;

  final void Function(String id)? onMoveUp;
  final void Function(String id)? onMoveDown;

  final void Function(String draggedId, String? targetParentId, int targetIndex)?
  onDropItem;

  final String? selectedId;
  final ValueChanged<String>? onSelectedChanged;

  final VoidCallback? onClearSelection;

  const LayerPanel({
    super.key,
    required this.layers,
    required this.activeLayerIds,
    required this.onToggleLayer,
    this.currentUserId,
    this.onRenameSelected,
    this.onConnectLayer,
    this.onOpenTable,
    this.onRemoveSelected,
    this.onCreateLayer,
    this.onCreateEmptyGroup,
    this.hasDataByLayer = const {},
    this.supportsConnect,
    this.onMoveUp,
    this.onMoveDown,
    this.onDropItem,
    this.selectedId,
    this.onSelectedChanged,
    this.onClearSelection,
  });

  @override
  State<LayerPanel> createState() => _LayerPanelState();
}

class _LayerPanelState extends State<LayerPanel>
    with AutomaticKeepAliveClientMixin {
  static const double rowHeight = 30;

  late Set<String> _expandedGroupIds;
  String? _internalSelectedId;

  Object? _lastVisibleEntriesKey;
  List<TreeRenderEntry> _lastVisibleEntries = const [];

  String? get _effectiveSelectedId {
    final external = widget.selectedId?.trim();

    if (external != null) {
      if (external.isEmpty) return null;
      return external;
    }

    final internal = _internalSelectedId?.trim();
    if (internal == null || internal.isEmpty) return null;

    return internal;
  }

  String get _currentUserId => (widget.currentUserId ?? '').trim();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _expandedGroupIds = _collectAllGroupIds(widget.layers);
    _internalSelectedId =
    (widget.selectedId?.trim().isNotEmpty ?? false) ? widget.selectedId : null;
  }

  @override
  void didUpdateWidget(covariant LayerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool shouldSetState = false;

    final selectedId = _effectiveSelectedId;

    if (selectedId != null &&
        !_existsLayerWithId(widget.layers, selectedId) &&
        widget.selectedId == null) {
      _internalSelectedId = null;
      shouldSetState = true;
    }

    final currentGroups = _collectAllGroupIds(widget.layers);
    final addedGroups = currentGroups.difference(_expandedGroupIds);

    if (addedGroups.isNotEmpty) {
      _expandedGroupIds = {..._expandedGroupIds, ...addedGroups};
      shouldSetState = true;
    }

    final normalizedExpanded = _expandedGroupIds.intersection(currentGroups);
    if (normalizedExpanded.length != _expandedGroupIds.length) {
      _expandedGroupIds = normalizedExpanded;
      shouldSetState = true;
    }

    if (widget.selectedId != oldWidget.selectedId) {
      final nextSelected =
      (widget.selectedId?.trim().isNotEmpty ?? false) ? widget.selectedId : null;

      if (nextSelected != _internalSelectedId) {
        _internalSelectedId = nextSelected;
        shouldSetState = true;
      }
    }

    if (oldWidget.layers != widget.layers ||
        oldWidget.currentUserId != widget.currentUserId) {
      _lastVisibleEntriesKey = null;
      _lastVisibleEntries = const [];
    }

    if (shouldSetState && mounted) {
      setState(() {});
    }
  }

  Set<String> _collectAllGroupIds(List<LayerData> nodes) {
    final ids = <String>{};

    void walk(List<LayerData> list) {
      for (final n in list) {
        if (n.isGroup) {
          ids.add(n.id);

          if (n.children.isNotEmpty) {
            walk(n.children);
          }
        }
      }
    }

    walk(nodes);
    return ids;
  }

  int _countGroups(List<LayerData> nodes) {
    var count = 0;

    void walk(List<LayerData> list) {
      for (final node in list) {
        if (node.isGroup) {
          count++;
        }

        if (node.children.isNotEmpty) {
          walk(node.children);
        }
      }
    }

    walk(nodes);
    return count;
  }

  int _countLayers(List<LayerData> nodes) {
    var count = 0;

    void walk(List<LayerData> list) {
      for (final node in list) {
        if (!node.isGroup) {
          count++;
        }

        if (node.children.isNotEmpty) {
          walk(node.children);
        }
      }
    }

    walk(nodes);
    return count;
  }

  bool _existsLayerWithId(List<LayerData> nodes, String id) {
    for (final n in nodes) {
      if (n.id == id) return true;

      if (n.isGroup && n.children.isNotEmpty) {
        if (_existsLayerWithId(n.children, id)) return true;
      }
    }

    return false;
  }

  List<int>? _findPathById(
      List<LayerData> nodes,
      String id, [
        List<int> current = const [],
      ]) {
    for (int i = 0; i < nodes.length; i++) {
      final path = [...current, i];
      final node = nodes[i];

      if (node.id == id) return path;

      if (node.isGroup && node.children.isNotEmpty) {
        final found = _findPathById(node.children, id, path);
        if (found != null) return found;
      }
    }

    return null;
  }

  LayerData? _getNodeByPath(
      List<LayerData> tree,
      List<int> path,
      ) {
    if (path.isEmpty) return null;

    List<LayerData> current = tree;
    LayerData? node;

    for (int i = 0; i < path.length; i++) {
      final index = path[i];

      if (index < 0 || index >= current.length) return null;

      node = current[index];

      if (i < path.length - 1) {
        current = node.children;
      }
    }

    return node;
  }

  LayerData? _selectedNode() {
    final selectedId = _effectiveSelectedId;
    if (selectedId == null || selectedId.trim().isEmpty) return null;

    final path = _findPathById(widget.layers, selectedId);
    if (path == null) return null;

    return _getNodeByPath(widget.layers, path);
  }

  LayerData? _findNodeById(List<LayerData> nodes, String id) {
    for (final node in nodes) {
      if (node.id == id) return node;

      if (node.children.isNotEmpty) {
        final found = _findNodeById(node.children, id);
        if (found != null) return found;
      }
    }

    return null;
  }

  bool _canEditLayer(LayerData layer) {
    final uid = _currentUserId;
    if (uid.isEmpty) return false;

    if (layer.isOwner(uid)) return true;

    final permission = layer.permissionFor(uid);
    return permission == LayerSharePermission.edit;
  }

  bool _canEditNode(LayerData node) {
    final uid = _currentUserId;
    if (uid.isEmpty) return false;

    if (node.isOwner(uid)) return true;

    final nodePermission = node.permissionFor(uid);
    if (nodePermission == LayerSharePermission.edit) return true;

    if (!node.isGroup) {
      return _canEditLayer(node);
    }

    final leaves = _flattenLeaves(node);

    if (leaves.isEmpty) {
      return false;
    }

    for (final leaf in leaves) {
      if (!_canEditLayer(leaf)) return false;
    }

    return true;
  }

  bool _canDropOnTarget({
    required String draggedId,
    required String? targetParentId,
  }) {
    final draggedNode = _findNodeById(widget.layers, draggedId);
    if (draggedNode == null) return false;

    if (!_canEditNode(draggedNode)) return false;

    if (targetParentId == null) return true;

    final targetNode = _findNodeById(widget.layers, targetParentId);
    if (targetNode == null) return false;

    return _canEditNode(targetNode);
  }

  Future<void> _handleCreateLayer() async {
    final selectedId = _effectiveSelectedId;

    if (selectedId == null) {
      await widget.onCreateLayer?.call(null, null);
      return;
    }

    final path = _findPathById(widget.layers, selectedId);

    if (path == null || path.isEmpty) {
      await widget.onCreateLayer?.call(null, null);
      return;
    }

    final selectedNode = _getNodeByPath(widget.layers, path);

    if (selectedNode == null) {
      await widget.onCreateLayer?.call(null, null);
      return;
    }

    if (selectedNode.isGroup) {
      if (!_canEditNode(selectedNode)) return;

      await widget.onCreateLayer?.call(
        selectedNode.id,
        selectedNode.children.length,
      );
      return;
    }

    if (!_canEditLayer(selectedNode)) return;

    final parentPath = path.sublist(0, path.length - 1);
    final selectedIndex = path.last;
    final parentNode =
    parentPath.isEmpty ? null : _getNodeByPath(widget.layers, parentPath);

    await widget.onCreateLayer?.call(parentNode?.id, selectedIndex + 1);
  }

  Future<void> _handleCreateEmptyGroup() async {
    final selectedId = _effectiveSelectedId;

    if (selectedId == null) {
      await widget.onCreateEmptyGroup?.call(null, null);
      return;
    }

    final path = _findPathById(widget.layers, selectedId);

    if (path == null || path.isEmpty) {
      await widget.onCreateEmptyGroup?.call(null, null);
      return;
    }

    final selectedNode = _getNodeByPath(widget.layers, path);

    if (selectedNode == null) {
      await widget.onCreateEmptyGroup?.call(null, null);
      return;
    }

    if (selectedNode.isGroup) {
      if (!_canEditNode(selectedNode)) return;

      await widget.onCreateEmptyGroup?.call(
        selectedNode.id,
        selectedNode.children.length,
      );
      return;
    }

    if (!_canEditLayer(selectedNode)) return;

    final parentPath = path.sublist(0, path.length - 1);
    final selectedIndex = path.last;
    final parentNode =
    parentPath.isEmpty ? null : _getNodeByPath(widget.layers, parentPath);

    await widget.onCreateEmptyGroup?.call(parentNode?.id, selectedIndex + 1);
  }

  void _toggleGroupExpand(String groupId) {
    setState(() {
      if (_expandedGroupIds.contains(groupId)) {
        _expandedGroupIds.remove(groupId);
      } else {
        _expandedGroupIds.add(groupId);
      }

      _lastVisibleEntriesKey = null;
      _lastVisibleEntries = const [];
    });
  }

  void _selectItem(String id) {
    if (_effectiveSelectedId == id) return;

    if (widget.selectedId == null) {
      setState(() {
        _internalSelectedId = id;
      });
    }

    widget.onSelectedChanged?.call(id);
  }

  void _clearSelection() {
    if (_effectiveSelectedId == null) return;

    if (widget.selectedId == null) {
      setState(() {
        _internalSelectedId = null;
      });
    }

    widget.onClearSelection?.call();
  }

  bool _areAllChildrenActive(LayerData node) {
    if (!node.isGroup) return widget.activeLayerIds.contains(node.id);
    if (node.children.isEmpty) return false;

    for (final child in node.children) {
      if (!_areAllChildrenActive(child)) return false;
    }

    return true;
  }

  bool _hasAnyChildActive(LayerData node) {
    if (!node.isGroup) return widget.activeLayerIds.contains(node.id);
    if (node.children.isEmpty) return false;

    for (final child in node.children) {
      if (_hasAnyChildActive(child)) return true;
    }

    return false;
  }

  List<LayerData> _flattenLeaves(LayerData node) {
    if (!node.isGroup) return [node];

    final result = <LayerData>[];

    for (final child in node.children) {
      result.addAll(_flattenLeaves(child));
    }

    return result;
  }

  bool _hasData(String id) => widget.hasDataByLayer[id] == true;

  List<TreeRenderEntry> _buildVisibleEntries(List<LayerData> nodes) {
    final cacheKey = Object.hash(
      nodes,
      Object.hashAll(_expandedGroupIds),
      widget.currentUserId,
    );

    if (_lastVisibleEntriesKey == cacheKey) {
      return _lastVisibleEntries;
    }

    final result = <TreeRenderEntry>[];

    void walk(
        List<LayerData> entries, {
          required int depth,
          required String? parentId,
        }) {
      for (var i = 0; i <= entries.length; i++) {
        result.add(
          TreeRenderEntry.insert(
            parentId: parentId,
            targetIndex: i,
            depth: depth,
          ),
        );

        if (i == entries.length) continue;

        final entry = entries[i];

        result.add(
          TreeRenderEntry.node(
            entry: entry,
            depth: depth,
          ),
        );

        if (entry.isGroup && _expandedGroupIds.contains(entry.id)) {
          walk(
            entry.children,
            depth: depth + 1,
            parentId: entry.id,
          );
        }
      }
    }

    walk(nodes, depth: 0, parentId: null);

    _lastVisibleEntriesKey = cacheKey;
    _lastVisibleEntries = List<TreeRenderEntry>.unmodifiable(result);

    return _lastVisibleEntries;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final visibleEntries = _buildVisibleEntries(widget.layers);

    final selectedNode = _selectedNode();
    final selectedCanEdit =
    selectedNode == null ? false : _canEditNode(selectedNode);

    final selectedId = _effectiveSelectedId;

    return ColoredBox(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayerToolbar(
            selectedId: selectedId,
            onCreateLayer: widget.onCreateLayer == null
                ? null
                : selectedNode == null
                ? () => widget.onCreateLayer?.call(null, null)
                : selectedCanEdit
                ? _handleCreateLayer
                : null,
            onCreateEmptyGroup: widget.onCreateEmptyGroup == null
                ? null
                : selectedNode == null
                ? () => widget.onCreateEmptyGroup?.call(null, null)
                : selectedCanEdit
                ? _handleCreateEmptyGroup
                : null,
            onRemoveSelected: selectedCanEdit ? widget.onRemoveSelected : null,
            onRenameSelected: selectedCanEdit ? widget.onRenameSelected : null,
            onMoveDown: selectedCanEdit ? widget.onMoveDown : null,
            onMoveUp: selectedCanEdit ? widget.onMoveUp : null,
          ),
          Divider(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.7),
          ),
          LayerRootHeader(
            layersCount: _countLayers(widget.layers),
            groupsCount: _countGroups(widget.layers),
            onTap: _clearSelection,
            onDropItem: (draggedId, targetParentId, targetIndex) {
              if (!_canDropOnTarget(
                draggedId: draggedId,
                targetParentId: targetParentId,
              )) {
                return;
              }

              widget.onDropItem?.call(
                draggedId,
                targetParentId,
                targetIndex,
              );
            },
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _clearSelection,
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  key: const PageStorageKey('layers_panel_list'),
                  padding: const EdgeInsets.only(bottom: 4),
                  itemCount: visibleEntries.length,
                  itemBuilder: (context, index) {
                    final item = visibleEntries[index];

                    if (item.isInsertTarget) {
                      return LayerTarget(
                        key: ValueKey(
                          'insert_${item.parentId ?? 'root'}_${item.targetIndex}',
                        ),
                        parentId: item.parentId,
                        targetIndex: item.targetIndex!,
                        depth: item.depth,
                        onDropItem: (draggedId, targetParentId, targetIndex) {
                          if (!_canDropOnTarget(
                            draggedId: draggedId,
                            targetParentId: targetParentId,
                          )) {
                            return;
                          }

                          widget.onDropItem?.call(
                            draggedId,
                            targetParentId,
                            targetIndex,
                          );
                        },
                      );
                    }

                    final entry = item.entry!;
                    final entryCanEdit = _canEditNode(entry);

                    return LayerDraggable(
                      key: ValueKey('drag_${entry.id}'),
                      entry: entry,
                      enabled: entryCanEdit,
                      row: _buildNodeRow(context, entry, item.depth),
                      onDragStarted: () => _selectItem(entry.id),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeRow(
      BuildContext context,
      LayerData entry,
      int depth,
      ) {
    if (entry.isGroup) {
      return DragTarget<String>(
        key: ValueKey('group_target_${entry.id}'),
        onWillAcceptWithDetails: (details) {
          if (details.data == entry.id) return false;

          return _canDropOnTarget(
            draggedId: details.data,
            targetParentId: entry.id,
          );
        },
        onAcceptWithDetails: (details) {
          if (!_canDropOnTarget(
            draggedId: details.data,
            targetParentId: entry.id,
          )) {
            return;
          }

          widget.onDropItem?.call(
            details.data,
            entry.id,
            entry.children.length,
          );
        },
        builder: (context, candidateData, rejectedData) {
          final hoveringInside = candidateData.isNotEmpty;

          return LayerGroup(
            group: entry,
            depth: depth,
            rowHeight: rowHeight,
            isExpanded: _expandedGroupIds.contains(entry.id),
            isSelected: _effectiveSelectedId == entry.id,
            hoveringInside: hoveringInside,
            checkboxValue: _areAllChildrenActive(entry)
                ? true
                : (_hasAnyChildActive(entry) ? null : false),
            onTap: () => _selectItem(entry.id),
            onToggleExpand: () => _toggleGroupExpand(entry.id),
            onToggleGroupVisibility: () {
              final shouldEnable = !_areAllChildrenActive(entry);
              final leaves = _flattenLeaves(entry);

              for (final leaf in leaves) {
                widget.onToggleLayer(leaf.id, shouldEnable);
              }
            },
          );
        },
      );
    }

    return LayerRow(
      layer: entry,
      depth: depth,
      rowHeight: rowHeight,
      isActive: widget.activeLayerIds.contains(entry.id),
      isSelected: _effectiveSelectedId == entry.id,
      hasData: _hasData(entry.id),
      currentUserId: widget.currentUserId,
      onTap: () => _selectItem(entry.id),
      onToggleLayer: (value) => widget.onToggleLayer(entry.id, value),
    );
  }
}

class TreeRenderEntry {
  final LayerData? entry;
  final int depth;
  final String? parentId;
  final int? targetIndex;
  final bool isInsertTarget;

  const TreeRenderEntry._({
    required this.entry,
    required this.depth,
    required this.parentId,
    required this.targetIndex,
    required this.isInsertTarget,
  });

  const TreeRenderEntry.node({
    required LayerData entry,
    required int depth,
  }) : this._(
    entry: entry,
    depth: depth,
    parentId: null,
    targetIndex: null,
    isInsertTarget: false,
  );

  const TreeRenderEntry.insert({
    required String? parentId,
    required int targetIndex,
    required int depth,
  }) : this._(
    entry: null,
    depth: depth,
    parentId: parentId,
    targetIndex: targetIndex,
    isInsertTarget: true,
  );
}