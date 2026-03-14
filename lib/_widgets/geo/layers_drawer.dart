import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/catalogs/marker_icons_catalog.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/geometry/shape_painter.dart';

class LayersDrawer extends StatefulWidget {
  final List<GeoLayersData> layers;
  final Set<String> activeLayerIds;
  final void Function(String id, bool isActive) onToggleLayer;

  final void Function(String id)? onRenameSelected;
  final void Function(String id)? onConnectLayer;
  final void Function(String id)? onRemoveSelected;

  final VoidCallback? onCreateLayer;
  final VoidCallback? onCreateEmptyGroup;

  final Map<String, bool> hasDbByLayer;
  final bool Function(GeoLayersData layer)? supportsConnect;

  final void Function(String id)? onMoveUp;
  final void Function(String id)? onMoveDown;

  final void Function(String draggedId, String? targetParentId, int targetIndex)?
  onDropItem;

  const LayersDrawer({
    super.key,
    required this.layers,
    required this.activeLayerIds,
    required this.onToggleLayer,
    this.onRenameSelected,
    this.onConnectLayer,
    this.onRemoveSelected,
    this.onCreateLayer,
    this.onCreateEmptyGroup,
    this.hasDbByLayer = const {},
    this.supportsConnect,
    this.onMoveUp,
    this.onMoveDown,
    this.onDropItem,
  });

  @override
  State<LayersDrawer> createState() => _LayersDrawerState();
}

class _LayersDrawerState extends State<LayersDrawer> {
  static const double _rowHeight = 40;
  static const double _trailingActionSlot = 28;

  late Set<String> _expandedGroupIds;
  String? _selectedId;
  bool _suppressRowTapOnce = false;

  @override
  void initState() {
    super.initState();
    _expandedGroupIds = _collectAllGroupIds(widget.layers);
  }

  @override
  void didUpdateWidget(covariant LayersDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);

    var shouldRebuild = false;

    if (_selectedId != null) {
      final stillExists = _existsLayerWithId(widget.layers, _selectedId!);
      if (!stillExists) {
        _selectedId = null;
        shouldRebuild = true;
      }
    }

    final newAllGroups = _collectAllGroupIds(widget.layers);
    final before = _expandedGroupIds.length;
    _expandedGroupIds.addAll(newAllGroups);
    if (_expandedGroupIds.length != before) {
      shouldRebuild = true;
    }

    if (shouldRebuild) {
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
    if (_selectedId == id) return;
    setState(() {
      _selectedId = id;
    });
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

  bool _hasDb(String id) => widget.hasDbByLayer[id] == true;

  bool _supportsConnect(GeoLayersData layer) {
    if (widget.onConnectLayer == null) return false;
    if (widget.supportsConnect != null) return widget.supportsConnect!(layer);
    return layer.supportsConnect && !layer.isGroup;
  }

  void _handleRowTapSelect(String id) {
    if (_suppressRowTapOnce) {
      _suppressRowTapOnce = false;
      return;
    }
    _selectItem(id);
  }

  void _handleConnectTap(String layerId) {
    _suppressRowTapOnce = true;
    final cb = widget.onConnectLayer;
    if (cb == null) return;
    cb(layerId);
  }

  _LayerActionVisual _resolveLayerActionVisual(GeoLayersData layer) {
    final hasDb = _hasDb(layer.id);

    return _LayerActionVisual(
      hasDb: hasDb,
      icon: hasDb ? Icons.table_view : Icons.cloud_off,
      tooltip: hasDb ? 'Abrir tabela' : 'Importar dados',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF3F3F3),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Text(
                'Camadas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            _buildTopToolbar(),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                key: const PageStorageKey('layers_drawer_list'),
                padding: EdgeInsets.zero,
                children: _buildTreeArea(
                  context,
                  widget.layers,
                  depth: 0,
                  parentId: null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _toolbarIconButton(
            icon: Icons.add,
            tooltip: 'Criar camada',
            onTap: widget.onCreateLayer,
          ),
          _toolbarIconButton(
            icon: Icons.remove_circle,
            tooltip: 'Remover item',
            onTap: () {
              final id = _selectedId;
              if (id == null) return;
              widget.onRemoveSelected?.call(id);
            },
          ),
          _toolbarIconButton(
            icon: Icons.create_new_folder,
            tooltip: 'Criar grupo',
            onTap: widget.onCreateEmptyGroup,
          ),
          _toolbarIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'Editar',
            onTap: () {
              final id = _selectedId;
              if (id == null) return;
              widget.onRenameSelected?.call(id);
            },
          ),
          _toolbarIconButton(
            icon: Icons.arrow_downward_outlined,
            tooltip: 'Mover para baixo',
            onTap: () {
              final id = _selectedId;
              if (id == null) return;
              widget.onMoveDown?.call(id);
            },
          ),
          _toolbarIconButton(
            icon: Icons.arrow_upward_outlined,
            tooltip: 'Mover para cima',
            onTap: () {
              final id = _selectedId;
              if (id == null) return;
              widget.onMoveUp?.call(id);
            },
          ),
        ],
      ),
    );
  }

  Widget _toolbarIconButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Icon(
              icon,
              size: 18,
              color: Colors.grey.shade800,
            ),
          ),
        ),
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
        _buildInsertTarget(
          key: ValueKey('insert_${parentId ?? 'root'}_$i'),
          parentId: parentId,
          targetIndex: i,
          depth: depth,
        ),
      );

      if (i == entries.length) continue;

      final entry = entries[i];
      widgets.add(
        _buildDraggableNode(
          context,
          entry,
          depth,
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

  Widget _buildInsertTarget({
    required Key key,
    required String? parentId,
    required int targetIndex,
    required int depth,
  }) {
    return DragTarget<String>(
      key: key,
      onWillAcceptWithDetails: (details) => details.data.trim().isNotEmpty,
      onAcceptWithDetails: (details) {
        widget.onDropItem?.call(details.data, parentId, targetIndex);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: isHovering ? 8 : 4,
          margin: EdgeInsets.only(
            left: 22 + (depth * 16.0),
            right: 12,
          ),
          decoration: BoxDecoration(
            color: isHovering
                ? Colors.blue.withValues(alpha: 0.18)
                : Colors.transparent,
            border: Border(
              top: BorderSide(
                color: isHovering ? Colors.blue : Colors.transparent,
                width: isHovering ? 2 : 1,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableNode(
      BuildContext context,
      GeoLayersData entry,
      int depth,
      ) {
    final row = _buildNodeRow(context, entry, depth);

    return LongPressDraggable<String>(
      key: ValueKey('drag_${entry.id}'),
      data: entry.id,
      onDragStarted: () => _selectItem(entry.id),
      feedback: Material(
        color: Colors.transparent,
        elevation: 8,
        child: Opacity(
          opacity: 0.92,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: row,
      ),
      child: row,
    );
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
          return _buildGroupRow(
            context,
            entry,
            depth,
            _expandedGroupIds.contains(entry.id),
            hoveringInside: hoveringInside,
          );
        },
      );
    }

    return _buildLayerRow(context, entry, depth);
  }

  Widget _buildGroupRow(
      BuildContext context,
      GeoLayersData group,
      int depth,
      bool isExpanded, {
        bool hoveringInside = false,
      }) {
    final isSelected = _selectedId == group.id;

    final allChildrenActive = _areAllChildrenActive(group);
    final anyChildActive = _hasAnyChildActive(group);

    final bool? checkboxValue =
    allChildrenActive ? true : (anyChildActive ? null : false);

    final bgColor = hoveringInside
        ? const Color(0xFFB3E5FC)
        : isSelected
        ? const Color(0xFF1976D2)
        : Colors.transparent;

    final textColor = isSelected ? Colors.white : Colors.black87;
    final iconColor = isSelected ? Colors.white : Colors.grey.shade800;
    final primaryCheckboxColor = Theme.of(context).colorScheme.primary;

    return Container(
      key: ValueKey('group_row_${group.id}'),
      child: InkWell(
        onTap: () => _handleRowTapSelect(group.id),
        child: Container(
          color: bgColor,
          height: _rowHeight,
          padding: EdgeInsets.only(
            left: 8.0 + depth * 16.0,
            right: 8.0,
          ),
          child: Row(
            children: [
              const SizedBox(width: 4),
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: checkboxValue,
                  tristate: true,
                  onChanged: (_) {
                    final shouldEnable = !allChildrenActive;
                    final leaves = _flattenLeaves(group);
                    for (final leaf in leaves) {
                      widget.onToggleLayer(leaf.id, shouldEnable);
                    }
                  },
                  activeColor: primaryCheckboxColor,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                IconsCatalog.iconFor(group.displayIconKey),
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: _trailingActionSlot,
                child: IconButton(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _toggleGroupExpand(group.id),
                  icon: Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayerRow(
      BuildContext context,
      GeoLayersData layer,
      int depth,
      ) {
    final isActive = widget.activeLayerIds.contains(layer.id);
    final isSelected = _selectedId == layer.id;

    final bgColor = isSelected ? const Color(0xFF1976D2) : Colors.transparent;
    final textColor = isSelected ? Colors.white : Colors.black87;

    final canConnect = _supportsConnect(layer);
    final visual = _resolveLayerActionVisual(layer);

    final actionIconColor = isSelected
        ? Colors.white
        : (visual.hasDb ? Colors.blue : Colors.grey.shade400);

    final primaryCheckboxColor = Theme.of(context).colorScheme.primary;

    return Container(
      key: ValueKey(
        'layer_row_${layer.id}_${visual.hasDb ? 'db' : 'link'}_${isActive ? 'on' : 'off'}_${layer.symbolLayers.length}_${layer.colorValue}_${layer.iconKey}',
      ),
      child: InkWell(
        onTap: () => _handleRowTapSelect(layer.id),
        child: Container(
          color: bgColor,
          height: _rowHeight,
          padding: EdgeInsets.only(
            left: 8.0 + depth * 16.0,
            right: 8.0,
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isActive,
                  onChanged: (v) => widget.onToggleLayer(layer.id, v ?? false),
                  activeColor: primaryCheckboxColor,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 4),
              _LayerSymbolStackPreview(
                layer: layer,
                isSelected: isSelected,
                isActive: isActive,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  layer.title,
                  style: TextStyle(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: _trailingActionSlot,
                child: canConnect
                    ? Tooltip(
                  message: visual.tooltip,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) {
                      _suppressRowTapOnce = true;
                    },
                    onTap: () => _handleConnectTap(layer.id),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          visual.icon,
                          key: ValueKey(
                            'action_${layer.id}_${visual.hasDb ? 'db' : 'link'}',
                          ),
                          size: 18,
                          color: actionIconColor,
                        ),
                      ),
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayerSymbolStackPreview extends StatelessWidget {
  final GeoLayersData layer;
  final bool isSelected;
  final bool isActive;

  const _LayerSymbolStackPreview({
    required this.layer,
    required this.isSelected,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final visibleSymbols = layer.effectiveSymbolLayers
        .where((e) => e.enabled)
        .toList(growable: false);

    if (visibleSymbols.isEmpty) {
      final iconColor =
      isSelected ? Colors.white : (isActive ? layer.displayColor : Colors.grey);

      return SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: Icon(
            IconsCatalog.iconFor(layer.displayIconKey),
            size: 18,
            color: iconColor,
          ),
        ),
      );
    }

    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...visibleSymbols.reversed.map(
                (symbol) => _DrawerSingleSymbolPreview(
              symbol: symbol,
              isSelected: isSelected,
              isActive: isActive,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSingleSymbolPreview extends StatelessWidget {
  final LayerSimpleSymbolData symbol;
  final bool isSelected;
  final bool isActive;

  const _DrawerSingleSymbolPreview({
    required this.symbol,
    required this.isSelected,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = symbol.fillColor;
    final strokeColor = symbol.strokeColor;

    final previewWidth = symbol.width.clamp(8.0, 22.0);
    final previewHeight = symbol.height.clamp(8.0, 22.0);

    if (symbol.type == LayerSimpleSymbolType.svgMarker) {
      return Transform.rotate(
        angle: symbol.rotationDegrees * 3.141592653589793 / 180,
        child: Icon(
          IconsCatalog.iconFor(symbol.iconKey),
          size: previewWidth > previewHeight ? previewWidth : previewHeight,
          color: fillColor,
        ),
      );
    }

    return Transform.rotate(
      angle: symbol.rotationDegrees * 3.141592653589793 / 180,
      child: SizedBox(
        width: previewWidth,
        height: previewHeight,
        child: CustomPaint(
          painter: ShapePainter(
            shape: symbol.shapeType,
            fillColor: fillColor,
            strokeColor: strokeColor,
            strokeWidth: symbol.strokeWidth.clamp(0.6, 1.5),
            rotationDegrees: 0,
          ),
        ),
      ),
    );
  }
}

class _LayerActionVisual {
  final bool hasDb;
  final IconData icon;
  final String tooltip;

  const _LayerActionVisual({
    required this.hasDb,
    required this.icon,
    required this.tooltip,
  });
}