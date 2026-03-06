import 'package:flutter/material.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layers_geo.dart';

class LayersDrawer extends StatefulWidget {
  final List<LayersGeo> layers;
  final Set<String> activeLayerIds;
  final void Function(String id, bool isActive) onToggleLayer;

  final void Function(String id)? onRenameSelected;
  final void Function(String id)? onConnectLayer;
  final Map<String, bool> hasDbByLayer;
  final bool Function(String layerId)? supportsConnect;

  final void Function(String id)? onMoveUp;
  final void Function(String id)? onMoveDown;
  final void Function(String id)? onCreateGroup;

  /// draggedId, targetParentId, targetIndex
  final void Function(String draggedId, String? targetParentId, int targetIndex)?
  onDropItem;

  const LayersDrawer({
    super.key,
    required this.layers,
    required this.activeLayerIds,
    required this.onToggleLayer,
    this.onRenameSelected,
    this.onConnectLayer,
    this.hasDbByLayer = const {},
    this.supportsConnect,
    this.onMoveUp,
    this.onMoveDown,
    this.onCreateGroup,
    this.onDropItem,
  });

  @override
  State<LayersDrawer> createState() => _LayersDrawerState();
}

class _LayersDrawerState extends State<LayersDrawer> {
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

    if (_selectedId != null) {
      final stillExists = _existsLayerWithId(widget.layers, _selectedId!);
      if (!stillExists) _selectedId = null;
    }

    final newAllGroups = _collectAllGroupIds(widget.layers);
    _expandedGroupIds.addAll(newAllGroups);
  }

  Set<String> _collectAllGroupIds(List<LayersGeo> nodes) {
    final ids = <String>{};

    void walk(List<LayersGeo> list) {
      for (final n in list) {
        if (n.isGroup) {
          ids.add(n.id);
          if (n.children.isNotEmpty) walk(n.children);
        }
      }
    }

    walk(nodes);
    return ids;
  }

  bool _existsLayerWithId(List<LayersGeo> nodes, String id) {
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
    setState(() {
      _selectedId = id;
    });
  }

  bool _areAllChildrenActive(LayersGeo node) {
    if (!node.isGroup) {
      return widget.activeLayerIds.contains(node.id);
    }
    if (node.children.isEmpty) return false;
    for (final c in node.children) {
      if (!_areAllChildrenActive(c)) return false;
    }
    return true;
  }

  bool _hasAnyChildActive(LayersGeo node) {
    if (!node.isGroup) {
      return widget.activeLayerIds.contains(node.id);
    }
    if (node.children.isEmpty) return false;
    for (final c in node.children) {
      if (_hasAnyChildActive(c)) return true;
    }
    return false;
  }

  List<LayersGeo> _flattenLeaves(LayersGeo node) {
    if (!node.isGroup) return [node];
    final list = <LayersGeo>[];
    for (final c in node.children) {
      list.addAll(_flattenLeaves(c));
    }
    return list;
  }

  bool _hasDb(String id) => widget.hasDbByLayer[id] == true;

  bool _supportsConnect(String layerId) {
    if (widget.onConnectLayer == null) return false;
    if (widget.supportsConnect != null) return widget.supportsConnect!(layerId);
    return true;
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
            onTap: () {},
          ),
          _toolbarIconButton(
            icon: Icons.remove_circle,
            tooltip: 'Remover camada',
            onTap: () {},
          ),
          _toolbarIconButton(
            icon: Icons.create_new_folder,
            tooltip: 'Criar grupo',
            onTap: () {
              final id = _selectedId;
              if (id == null) return;
              widget.onCreateGroup?.call(id);
            },
          ),
          _toolbarIconButton(
            icon: Icons.drive_file_rename_outline,
            tooltip: 'Renomear',
            onTap: () {
              final id = _selectedId;
              if (id == null) return;
              widget.onRenameSelected?.call(id);
            },
          ),
          _toolbarIconButton(
            icon: Icons.visibility_outlined,
            tooltip: 'Visibilidade',
            onTap: () {},
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
      List<LayersGeo> entries, {
        required int depth,
        required String? parentId,
      }) {
    final widgets = <Widget>[];

    for (int i = 0; i <= entries.length; i++) {
      widgets.add(
        _buildInsertTarget(
          parentId: parentId,
          targetIndex: i,
          depth: depth,
        ),
      );

      if (i == entries.length) continue;

      final entry = entries[i];
      widgets.add(_buildDraggableNode(context, entry, depth));

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
    required String? parentId,
    required int targetIndex,
    required int depth,
  }) {
    return DragTarget<String>(
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
            color: isHovering ? Colors.blue.withValues(alpha: 0.18) : Colors.transparent,
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
      LayersGeo entry,
      int depth,
      ) {
    final row = _buildNodeRow(context, entry, depth);

    return LongPressDraggable<String>(
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
      LayersGeo entry,
      int depth,
      ) {
    if (entry.isGroup) {
      return DragTarget<String>(
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
      LayersGeo group,
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

    return InkWell(
      onTap: () => _handleRowTapSelect(group.id),
      child: Container(
        color: bgColor,
        height: 36,
        padding: EdgeInsets.only(
          left: 8.0 + depth * 16.0,
          right: 8.0,
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(
              isExpanded ? Icons.expand_more : Icons.chevron_right,
              size: 18,
              color: iconColor,
            ),
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
            Icon(group.icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                group.title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              iconSize: 18,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: () => _toggleGroupExpand(group.id),
              icon: Icon(
                isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerRow(
      BuildContext context,
      LayersGeo layer,
      int depth,
      ) {
    final isActive = widget.activeLayerIds.contains(layer.id);
    final isSelected = _selectedId == layer.id;

    final bgColor = isSelected ? const Color(0xFF1976D2) : Colors.transparent;
    final textColor = isSelected ? Colors.white : Colors.black87;

    final iconColor =
    isSelected ? Colors.white : (isActive ? layer.color : Colors.grey);

    final canConnect = _supportsConnect(layer.id);
    final hasDb = _hasDb(layer.id);

    final actionIconColor =
    isSelected ? Colors.white : (hasDb ? Colors.blue : Colors.grey.shade300);

    final primaryCheckboxColor = Theme.of(context).colorScheme.primary;
    final actionIcon = hasDb ? Icons.table_view : Icons.link;
    final tooltip =
    hasDb ? 'Abrir tabela de atributos' : 'Conectar / Importar dados';

    return InkWell(
      onTap: () => _handleRowTapSelect(layer.id),
      child: Container(
        color: bgColor,
        height: 36,
        padding: EdgeInsets.only(
          left: 8.0 + depth * 16.0,
          right: 8.0,
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const SizedBox(width: 18),
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
            Icon(layer.icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                layer.title,
                style: TextStyle(color: textColor),
              ),
            ),
            if (canConnect)
              Tooltip(
                message: tooltip,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) {
                    _suppressRowTapOnce = true;
                  },
                  onTap: () => _handleConnectTap(layer.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Icon(actionIcon, size: 18, color: actionIconColor),
                  ),
                ),
              )
            else
              const SizedBox(width: 30),
          ],
        ),
      ),
    );
  }
}