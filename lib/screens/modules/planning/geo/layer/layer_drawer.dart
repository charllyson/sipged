import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_map.dart';
import 'package:sipged/_blocs/system/map/map_state.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layer_panel.dart';

class LayerDrawer extends StatelessWidget {
  const LayerDrawer({
    super.key,
    required this.mapData,
    required this.editorState,
    required this.onSelectedChanged,
    required this.onToggleLayer,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onCreateEmptyGroup,
    required this.onCreateLayer,
    required this.onDropItem,
    required this.onRenameSelected,
    required this.onRemoveSelected,
    required this.onConnectLayer,
    required this.onOpenTable,
    this.currentUserId,
    this.title = 'Camadas',
  });

  final LayerDataMap mapData;
  final MapState editorState;
  final String title;

  final String? currentUserId;

  final ValueChanged<String> onSelectedChanged;
  final void Function(String id, bool active) onToggleLayer;
  final ValueChanged<String> onMoveUp;
  final ValueChanged<String> onMoveDown;

  final Future<void> Function(String? parentId, int? targetIndex)
  onCreateEmptyGroup;

  final Future<void> Function(String? parentId, int? targetIndex) onCreateLayer;

  final void Function(String draggedId, String? targetParentId, int targetIndex)
  onDropItem;

  final ValueChanged<String> onRenameSelected;
  final ValueChanged<String> onRemoveSelected;
  final ValueChanged<String> onConnectLayer;
  final ValueChanged<String> onOpenTable;

  List<LayerData> _filterTreeForUser({
    required List<LayerData> tree,
    required String currentUserId,
  }) {
    final uid = currentUserId.trim();

    if (uid.isEmpty) {
      return const [];
    }

    List<LayerData> walk(List<LayerData> nodes) {
      final result = <LayerData>[];

      for (final node in nodes) {
        if (node.isGroup) {
          final visibleChildren = walk(node.children);

          if (visibleChildren.isNotEmpty) {
            result.add(
              node.copyWith(
                children: visibleChildren,
              ),
            );
          }

          continue;
        }

        if (_canUserSeeLayer(node, uid)) {
          result.add(node);
        }
      }

      return result;
    }

    return walk(tree);
  }

  bool _canUserSeeLayer(LayerData layer, String currentUserId) {
    final uid = currentUserId.trim();
    if (uid.isEmpty) return false;

    if (layer.isOwner(uid)) {
      return true;
    }

    final permission = layer.permissionFor(uid);

    return permission == LayerSharePermission.readOnly ||
        permission == LayerSharePermission.edit;
  }

  Set<String> _collectTreeIds(List<LayerData> tree) {
    final ids = <String>{};

    void walk(List<LayerData> nodes) {
      for (final node in nodes) {
        ids.add(node.id);

        if (node.children.isNotEmpty) {
          walk(node.children);
        }
      }
    }

    walk(tree);
    return ids;
  }

  Set<String> _filterActiveLayerIds({
    required Set<String> source,
    required Set<String> visibleIds,
  }) {
    return source.where(visibleIds.contains).toSet();
  }

  Map<String, bool> _filterHasDataByVisibleLayers({
    required Map<String, bool> source,
    required Set<String> visibleIds,
  }) {
    return {
      for (final entry in source.entries)
        if (visibleIds.contains(entry.key)) entry.key: entry.value,
    };
  }

  String? _normalizeSelectedId({
    required String? selectedId,
    required Set<String> visibleIds,
  }) {
    final id = (selectedId ?? '').trim();

    if (id.isEmpty) {
      return null;
    }

    if (!visibleIds.contains(id)) {
      return null;
    }

    return id;
  }

  @override
  Widget build(BuildContext context) {
    const headerHeight = 60.0;

    final resolvedCurrentUserId =
    (currentUserId ?? FirebaseAuth.instance.currentUser?.uid ?? '').trim();

    final visibleTree = _filterTreeForUser(
      tree: mapData.currentTree,
      currentUserId: resolvedCurrentUserId,
    );

    final visibleIds = _collectTreeIds(visibleTree);

    final visibleActiveLayerIds = _filterActiveLayerIds(
      source: mapData.activeLayerIds,
      visibleIds: visibleIds,
    );

    final visibleHasDataByLayer = _filterHasDataByVisibleLayers(
      source: mapData.hasDataByLayer,
      visibleIds: visibleIds,
    );

    final selectedId = _normalizeSelectedId(
      selectedId: editorState.selectedLayerPanelItemId,
      visibleIds: visibleIds,
    );

    final panelKey = ValueKey(
      'layers_panel_drawer_'
          '${visibleTree.length}_'
          '${visibleActiveLayerIds.length}_'
          '${selectedId ?? 'none'}_'
          '${editorState.activeEditingPointLayerId ?? 'none'}_'
          '${editorState.activeEditingLineLayerId ?? 'none'}_'
          '${editorState.activeEditingPolygonLayerId ?? 'none'}_'
          '${mapData.hasDataSignature}_'
          '$resolvedCurrentUserId',
    );

    return SafeArea(
      top: true,
      left: false,
      right: false,
      bottom: false,
      child: Drawer(
        width: 250,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: Material(
          color: Colors.white,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(
                  width: 1.0,
                  color: Color(0xFFD1D5DB),
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  height: headerHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F6F8),
                    border: Border(
                      bottom: BorderSide(
                        width: 0.8,
                        color: Color(0xFFD6DAE1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 60),
                      const Icon(
                        Icons.layers_outlined,
                        size: 16,
                        color: Color(0xFF4B5563),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          tooltip: 'Fechar',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          splashRadius: 16,
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: Colors.white,
                    child: RepaintBoundary(
                      child: LayerPanel(
                        key: panelKey,
                        layers: visibleTree,
                        activeLayerIds: visibleActiveLayerIds,
                        selectedId: selectedId,
                        currentUserId: resolvedCurrentUserId,
                        onSelectedChanged: onSelectedChanged,
                        onClearSelection: () {
                          onSelectedChanged('');
                        },
                        onToggleLayer: onToggleLayer,
                        hasDataByLayer: visibleHasDataByLayer,
                        supportsConnect: (layer) =>
                        layer.supportsConnect && !layer.isGroup,
                        onMoveUp: onMoveUp,
                        onMoveDown: onMoveDown,
                        onCreateEmptyGroup: onCreateEmptyGroup,
                        onCreateLayer: onCreateLayer,
                        onDropItem: onDropItem,
                        onRenameSelected: onRenameSelected,
                        onRemoveSelected: onRemoveSelected,
                        onConnectLayer: onConnectLayer,
                        onOpenTable: onOpenTable,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}