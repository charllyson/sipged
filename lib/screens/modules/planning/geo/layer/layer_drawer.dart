import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_map.dart';
import 'package:sipged/_blocs/modules/planning/geo/map/map_state.dart';
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
    this.title = 'Camadas',
  });

  final LayerDataMap mapData;
  final MapState editorState;
  final String title;

  final ValueChanged<String> onSelectedChanged;
  final void Function(String id, bool active) onToggleLayer;
  final ValueChanged<String> onMoveUp;
  final ValueChanged<String> onMoveDown;
  final Future<void> Function(String? parentId, int? targetIndex)
  onCreateEmptyGroup;
  final Future<void> Function(String? parentId, int? targetIndex)
  onCreateLayer;
  final void Function(String draggedId, String? targetParentId, int targetIndex)
  onDropItem;
  final ValueChanged<String> onRenameSelected;
  final ValueChanged<String> onRemoveSelected;
  final ValueChanged<String> onConnectLayer;
  final ValueChanged<String> onOpenTable;

  @override
  Widget build(BuildContext context) {
    const headerHeight = 60.0;

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
                        key: ValueKey(
                          'layers_panel_drawer_'
                              '${mapData.currentTree.length}_'
                              '${mapData.activeLayerIds.length}_'
                              '${editorState.selectedLayerPanelItemId ?? 'none'}_'
                              '${editorState.activeEditingPointLayerId ?? 'none'}_'
                              '${editorState.activeEditingLineLayerId ?? 'none'}_'
                              '${editorState.activeEditingPolygonLayerId ?? 'none'}_'
                              '${Object.hashAll(mapData.hasDataByLayer.entries.map((e) => Object.hash(e.key, e.value)))}',
                        ),
                        layers: mapData.currentTree,
                        activeLayerIds: mapData.activeLayerIds,
                        selectedId: editorState.selectedLayerPanelItemId,
                        onSelectedChanged: onSelectedChanged,
                        onToggleLayer: onToggleLayer,
                        hasDataByLayer: mapData.hasDataByLayer,
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