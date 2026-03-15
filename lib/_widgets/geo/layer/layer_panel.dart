import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/layer/layer_action.dart';
import 'package:sipged/_widgets/geo/layer/layer_panel_draggable_node.dart';
import 'package:sipged/_widgets/geo/layer/layer_panel_group_row.dart';
import 'package:sipged/_widgets/geo/layer/layer_panel_insert_target.dart';
import 'package:sipged/_widgets/geo/layer/layer_panel_layer_row.dart';
import 'package:sipged/_widgets/geo/layer/layer_panel_top_toolbar.dart';

class LayerPanel extends StatefulWidget {
  final List<GeoLayersData> layers;
  final Set<String> activeLayerIds;
  final void Function(String id, bool isActive) onToggleLayer;

  final void Function(String id)? onRenameSelected;
  final void Function(String id)? onConnectLayer;
  final void Function(String id)? onOpenTable;
  final void Function(String id)? onRemoveSelected;

  final VoidCallback? onCreateLayer;
  final VoidCallback? onCreateEmptyGroup;

  final Map<String, bool> hasDataByLayer;
  final bool Function(GeoLayersData layer)? supportsConnect;

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
  static const double trailingActionSlot = 28;

  late Set<String> _expandedGroupIds;
  String? _internalSelectedId;
  bool _suppressRowTapOnce = false;

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

    final newAllGroups = _collectAllGroupIds(widget.layers);
    final before = _expandedGroupIds.length;
    _expandedGroupIds.addAll(newAllGroups);

    if (_expandedGroupIds.length != before) {
      shouldRebuild = true;
    }

    if (widget.selectedId != oldWidget.selectedId && widget.selectedId != null) {
      _internalSelectedId = widget.selectedId;
      shouldRebuild = true;
    }

    if (shouldRebuild && mounted) {
      setState(() {});
    }
  }

  Set<String> _collectAllGroupIds(List<GeoLayersData> nodes) {
    final ids = <String>{};

    void walk(List<GeoLayersData> list) {
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

  bool _existsLayerWithId(List<GeoLayersData> nodes, String id) {
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

  bool _areAllChildrenActive(GeoLayersData node) {
    if (!node.isGroup) {
      return widget.activeLayerIds.contains(node.id);
    }
    if (node.children.isEmpty) return false;

    for (final c in node.children) {
      if (!_areAllChildrenActive(c)) return false;
    }
    return true;
  }

  bool _hasAnyChildActive(GeoLayersData node) {
    if (!node.isGroup) {
      return widget.activeLayerIds.contains(node.id);
    }
    if (node.children.isEmpty) return false;

    for (final c in node.children) {
      if (_hasAnyChildActive(c)) return true;
    }
    return false;
  }

  List<GeoLayersData> _flattenLeaves(GeoLayersData node) {
    if (!node.isGroup) return [node];

    final list = <GeoLayersData>[];
    for (final c in node.children) {
      list.addAll(_flattenLeaves(c));
    }
    return list;
  }

  bool _hasData(String id) => widget.hasDataByLayer[id] == true;

  bool _supportsConnect(GeoLayersData layer) {
    if (layer.isGroup) return false;
    if (widget.onConnectLayer == null && widget.onOpenTable == null) return false;

    if (widget.supportsConnect != null) {
      return widget.supportsConnect!(layer);
    }

    return layer.supportsConnect && !layer.isGroup;
  }

  void _handleRowTapSelect(String id) {
    if (_suppressRowTapOnce) {
      _suppressRowTapOnce = false;
      return;
    }
    _selectItem(id);
  }

  void _handleLayerActionTap(GeoLayersData layer) {
    _suppressRowTapOnce = true;

    final hasData = _hasData(layer.id);

    if (hasData) {
      _selectItem(layer.id);
      widget.onOpenTable?.call(layer.id);
      return;
    }

    widget.onConnectLayer?.call(layer.id);
  }

  LayerActionVisual _resolveLayerActionVisual(GeoLayersData layer) {
    final hasData = _hasData(layer.id);

    return LayerActionVisual(
      hasData: hasData,
      icon: hasData ? Icons.table_view : Icons.cloud_upload_outlined,
      tooltip: hasData ? 'Abrir tabela de atributos' : 'Importar dados',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayerPanelTopToolbar(
            selectedId: _effectiveSelectedId,
            onCreateLayer: widget.onCreateLayer,
            onCreateEmptyGroup: widget.onCreateEmptyGroup,
            onRemoveSelected: widget.onRemoveSelected,
            onRenameSelected: widget.onRenameSelected,
            onMoveDown: widget.onMoveDown,
            onMoveUp: widget.onMoveUp,
          ),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.7)),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView(
                key: const PageStorageKey('layers_panel_list'),
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: _buildTreeArea(
                  context,
                  widget.layers,
                  depth: 0,
                  parentId: null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTreeArea(
      BuildContext context,
      List<GeoLayersData> entries, {
        required int depth,
        required String? parentId,
      }) {
    final widgets = <Widget>[];

    for (int i = 0; i <= entries.length; i++) {
      widgets.add(
        LayerPanelInsertTarget(
          key: ValueKey('insert_${parentId ?? 'root'}_$i'),
          parentId: parentId,
          targetIndex: i,
          depth: depth,
          onDropItem: widget.onDropItem,
        ),
      );

      if (i == entries.length) continue;

      final entry = entries[i];

      widgets.add(
        LayerPanelDraggableNode(
          entry: entry,
          row: _buildNodeRow(context, entry, depth),
          onDragStarted: () => _selectItem(entry.id),
        ),
      );

      if (entry.isGroup && _expandedGroupIds.contains(entry.id)) {
        widgets.addAll(
          _buildTreeArea(
            context,
            entry.children,
            depth: depth + 1,
            parentId: entry.id,
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildNodeRow(
      BuildContext context,
      GeoLayersData entry,
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
          return LayerPanelGroupRow(
            group: entry,
            depth: depth,
            rowHeight: rowHeight,
            trailingActionSlot: trailingActionSlot,
            isExpanded: _expandedGroupIds.contains(entry.id),
            isSelected: _effectiveSelectedId == entry.id,
            hoveringInside: hoveringInside,
            checkboxValue: _areAllChildrenActive(entry)
                ? true
                : (_hasAnyChildActive(entry) ? null : false),
            onTap: () => _handleRowTapSelect(entry.id),
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

    final visual = _resolveLayerActionVisual(entry);

    return LayerPanelLayerRow(
      layer: entry,
      depth: depth,
      rowHeight: rowHeight,
      trailingActionSlot: trailingActionSlot,
      isActive: widget.activeLayerIds.contains(entry.id),
      isSelected: _effectiveSelectedId == entry.id,
      canConnect: _supportsConnect(entry),
      visual: visual,
      onTap: () => _handleRowTapSelect(entry.id),
      onToggleLayer: (value) => widget.onToggleLayer(entry.id, value),
      onActionTap: () => _handleLayerActionTap(entry),
      onActionTapDown: () {
        _suppressRowTapOnce = true;
      },
    );
  }
}