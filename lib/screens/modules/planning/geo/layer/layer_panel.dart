import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layer_draggable.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layer_group.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layer_target.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layer_row.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layer_toolbar.dart';

class LayerPanel extends StatefulWidget {
  final List<LayerData> layers;
  final Set<String> activeLayerIds;
  final void Function(String id, bool isActive) onToggleLayer;

  final void Function(String id)? onRenameSelected;
  final void Function(String id)? onConnectLayer;
  final void Function(String id)? onOpenTable;
  final void Function(String id)? onRemoveSelected;

  final VoidCallback? onCreateLayer;
  final VoidCallback? onCreateEmptyGroup;

  final Map<String, bool> hasDataByLayer;
  final bool Function(LayerData layer)? supportsConnect;

  final void Function(String id)? onMoveUp;
  final void Function(String id)? onMoveDown;

  final void Function(String draggedId, String? targetParentId, int targetIndex)?
  onDropItem;

  final String? selectedId;
  final ValueChanged<String>? onSelectedChanged;

  const LayerPanel({
    super.key,
    required this.layers,
    required this.activeLayerIds,
    required this.onToggleLayer,
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
  });

  @override
  State<LayerPanel> createState() => _LayerPanelState();
}

class _LayerPanelState extends State<LayerPanel> {
  static const double rowHeight = 30;

  late Set<String> _expandedGroupIds;
  String? _internalSelectedId;

  String? get _effectiveSelectedId => widget.selectedId ?? _internalSelectedId;

  @override
  void initState() {
    super.initState();
    _expandedGroupIds = _collectAllGroupIds(widget.layers);
    _internalSelectedId = widget.selectedId;
  }

  @override
  void didUpdateWidget(covariant LayerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    var shouldRebuild = false;

    final selectedId = _effectiveSelectedId;
    if (selectedId != null) {
      final stillExists = _existsLayerWithId(widget.layers, selectedId);
      if (!stillExists && widget.selectedId == null) {
        _internalSelectedId = null;
        shouldRebuild = true;
      }
    }

    final allGroupsNow = _collectAllGroupIds(widget.layers);
    final beforeLength = _expandedGroupIds.length;
    _expandedGroupIds.addAll(allGroupsNow);

    if (_expandedGroupIds.length != beforeLength) {
      shouldRebuild = true;
    }

    if (widget.selectedId != oldWidget.selectedId &&
        widget.selectedId != _internalSelectedId) {
      _internalSelectedId = widget.selectedId;
      shouldRebuild = true;
    }

    if (shouldRebuild && mounted) {
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

  bool _existsLayerWithId(List<LayerData> nodes, String id) {
    for (final n in nodes) {
      if (n.id == id) return true;
      if (n.isGroup && n.children.isNotEmpty) {
        if (_existsLayerWithId(n.children, id)) return true;
      }
    }
    return false;
  }

  void _toggleGroupExpand(String groupId) {
    setState(() {
      if (_expandedGroupIds.contains(groupId)) {
        _expandedGroupIds.remove(groupId);
      } else {
        _expandedGroupIds.add(groupId);
      }
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

  bool _areAllChildrenActive(LayerData node) {
    if (!node.isGroup) {
      return widget.activeLayerIds.contains(node.id);
    }
    if (node.children.isEmpty) return false;

    for (final child in node.children) {
      if (!_areAllChildrenActive(child)) return false;
    }
    return true;
  }

  bool _hasAnyChildActive(LayerData node) {
    if (!node.isGroup) {
      return widget.activeLayerIds.contains(node.id);
    }
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
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleEntries = _buildVisibleEntries(widget.layers);

    return ColoredBox(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayerToolbar(
            selectedId: _effectiveSelectedId,
            onCreateLayer: widget.onCreateLayer,
            onCreateEmptyGroup: widget.onCreateEmptyGroup,
            onRemoveSelected: widget.onRemoveSelected,
            onRenameSelected: widget.onRenameSelected,
            onMoveDown: widget.onMoveDown,
            onMoveUp: widget.onMoveUp,
          ),
          Divider(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.7),
          ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                key: const PageStorageKey('layers_panel_list'),
                padding: const EdgeInsets.symmetric(vertical: 4),
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
                      onDropItem: widget.onDropItem,
                    );
                  }

                  final entry = item.entry!;
                  return LayerDraggable(
                    key: ValueKey('drag_${entry.id}'),
                    entry: entry,
                    row: _buildNodeRow(context, entry, item.depth),
                    onDragStarted: () => _selectItem(entry.id),
                  );
                },
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
        onWillAcceptWithDetails: (details) => details.data != entry.id,
        onAcceptWithDetails: (details) {
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