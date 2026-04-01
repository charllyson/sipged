import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:sipged/_blocs/modules/planning/geo/attribute/attribute_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/attribute/attribute_data_drag.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/component/component_data_catalog.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/property/component_data_property.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data_item.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_map.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/map/map_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/map/map_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/toolbox/toolbox_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/toolbox/toolbox_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/_utils/debug/sipged_perf.dart';

import 'package:sipged/_widgets/buttons/back_circle_button.dart';
import 'package:sipged/_widgets/docking/dock_panel_workspace.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';

import 'package:sipged/screens/modules/planning/geo/attributes/import/attribute_import_feature.dart';
import 'package:sipged/screens/modules/planning/geo/attributes/layer/attribute_panel.dart';
import 'package:sipged/screens/modules/planning/geo/catalog/component/component_panel.dart';
import 'package:sipged/screens/modules/planning/geo/catalog/property/property_panel.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layer_panel.dart';
import 'package:sipged/screens/modules/planning/geo/map/map_change.dart';
import 'package:sipged/screens/modules/planning/geo/properties/dialog/layer_properties_dialog.dart';
import 'package:sipged/screens/modules/planning/geo/status/status_bar.dart';
import 'package:sipged/screens/modules/planning/geo/toolbox/toolbox_content.dart';
import 'package:sipged/screens/modules/planning/geo/workspace/workspace_panel.dart';

class GeoNetworkPage extends StatelessWidget {
  const GeoNetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final geoLayersRepository = LayerRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ToolboxCubit()),
        BlocProvider(
          create: (_) => LayerCubit(
            repository: geoLayersRepository,
          )..load(),
        ),
        BlocProvider(
          create: (_) => GeoFeatureCubit(
            repository: GeoFeatureRepository(),
          ),
        ),
        BlocProvider(
          create: (context) => MapCubit(
            layersCubit: context.read<LayerCubit>(),
            featureCubit: context.read<GeoFeatureCubit>(),
            toolboxCubit: context.read<ToolboxCubit>(),
          ),
        ),
      ],
      child: const _PlanningNetworkView(),
    );
  }
}

class _PlanningNetworkView extends StatefulWidget {
  const _PlanningNetworkView();

  @override
  State<_PlanningNetworkView> createState() => _PlanningNetworkViewState();
}

class _PlanningNetworkViewState extends State<_PlanningNetworkView> {
  MapController? controller;

  List<WorkspaceData> _workspaceItems = const <WorkspaceData>[];
  int _workspaceCounter = 0;

  String? _selectedCatalogItemId;
  String? _selectedWorkspaceItemId;

  bool _statusDismissed = false;
  String _lastStatusIdentity = '';

  List<WorkspaceData>? _lastWorkspaceItemsRef;
  Object? _lastWorkspaceItemsToken;

  WorkspaceData? get _selectedWorkspaceItem {
    for (final item in _workspaceItems) {
      if (item.id == _selectedWorkspaceItemId) return item;
    }
    return null;
  }

  Object _workspaceItemToken(WorkspaceData item) {
    return Object.hash(
      item.id,
      item.title,
      item.type,
      item.offset,
      item.size,
      item.properties.length,
      Object.hashAll(
        item.properties.map(
              (p) => Object.hash(
            p.key,
            p.type,
            p.textValue,
            p.numberValue,
            p.selectedValue,
            p.bindingValue?.sourceId,
            p.bindingValue?.fieldName,
          ),
        ),
      ),
    );
  }

  Object _workspaceItemsToken() {
    if (identical(_lastWorkspaceItemsRef, _workspaceItems) &&
        _lastWorkspaceItemsToken != null) {
      return _lastWorkspaceItemsToken!;
    }

    final token = SipgedPerf.traceSync(
      'GeoNetworkPage._workspaceItemsToken',
          () => Object.hashAll(_workspaceItems.map(_workspaceItemToken)),
      warnMs: 6,
      data: {
        'workspaceItems': _workspaceItems.length,
      },
    );

    _lastWorkspaceItemsRef = _workspaceItems;
    _lastWorkspaceItemsToken = token;
    return token;
  }

  Object _selectedWorkspaceItemToken() {
    final item = _selectedWorkspaceItem;
    return item?.id ?? 'no_selected_workspace_item';
  }



  Map<String, dynamic> _mergedFeatureProperties(GeoFeatureData feature) {
    final out = <String, dynamic>{};
    out.addAll(feature.originalProperties);
    out.addAll(feature.editedProperties);
    return out;
  }

  Future<LayerData?> _askEditLayerData({
    required BuildContext context,
    required LayerData current,
  }) async {
    final geoFeatureCubit = context.read<GeoFeatureCubit>();
    final availableFields = await geoFeatureCubit.ensureLayerFieldNames(current);

    if (!context.mounted) return null;

    return LayerPropertiesDialog.show(
      context,
      current: current,
      availableRuleFields: availableFields,
    );
  }

  Future<void> _editSelectedItem(
      String id,
      List<LayerData> currentTree,
      ) async {
    final layersCubit = context.read<LayerCubit>();
    final node = layersCubit.findNodeById(id, tree: currentTree);
    if (node == null) return;

    final edited = await _askEditLayerData(
      context: context,
      current: node,
    );

    if (!mounted || edited == null) return;
    if (edited.title.trim().isEmpty) return;

    await layersCubit.updateNodeById(id, (_) => edited);
  }

  Future<void> _handleConnectLayer(
      String rawId,
      List<LayerData> currentTree,
      ) async {
    final layersCubit = context.read<LayerCubit>();
    final layer = layersCubit.findNodeById(rawId, tree: currentTree);

    if (layer == null || layer.isGroup) return;

    final isAlreadyActive = layersCubit.state.activeLayerIds.contains(layer.id);

    await AttributeImportFeature.handleConnectLayer(
      context,
      layer: layer,
      shouldLoadOnMap: isAlreadyActive,
    );

    if (!mounted) return;

    await layersCubit.refreshLayerData(layer, force: true);

    final hasDataNow = layersCubit.state.hasDataByLayer[layer.id] == true;
    if (!hasDataNow) return;

    if (!layersCubit.state.activeLayerIds.contains(layer.id)) {
      layersCubit.toggleLayer(layer.id, true);
    }

    await context.read<GeoFeatureCubit>().ensureLayerLoaded(layer, force: true);
    await context.read<GeoFeatureCubit>().ensureLayerFieldNames(
      layer,
      force: true,
    );
  }

  Future<void> _openLayerTable(
      BuildContext context,
      String id,
      List<LayerData> currentTree,
      ) async {
    final layersCubit = context.read<LayerCubit>();
    final editorCubit = context.read<MapCubit>();

    final layer = layersCubit.findNodeById(id, tree: currentTree);
    if (layer == null || layer.isGroup) return;

    editorCubit.selectLayerPanelItem(layer.id);

    if (!layersCubit.state.activeLayerIds.contains(layer.id)) {
      layersCubit.toggleLayer(layer.id, true);
    }

    await context.read<GeoFeatureCubit>().ensureLayerLoaded(
      layer,
      force: true,
    );

    await context.read<GeoFeatureCubit>().ensureLayerFieldNames(
      layer,
      force: false,
    );

    if (!mounted) return;

    await AttributeImportFeature.openFirestoreTable(
      context,
      layer: layer,
    );
  }

  void _showSnack(BuildContext context, String message) {
    if (message.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  WorkspaceData _buildWorkspaceItemFromCatalog({
    required ComponentDataCatalog catalogItem,
    required Offset localOffset,
  }) {
    final type = ComponentTypeMapper.fromCatalogItemId(catalogItem.id);
    if (type == null) {
      throw Exception('Tipo não implementado: ${catalogItem.id}');
    }

    return WorkspaceData(
      id: 'workspace_item_${_workspaceCounter++}',
      title: catalogItem.title,
      type: type,
      offset: localOffset,
      size: type.defaultSize,
      properties: type.defaultProperties,
    );
  }

  void _handleWorkspaceCatalogDrop(
      ComponentDataCatalog item,
      Offset localOffset,
      ) {
    SipgedPerf.traceSync(
      'GeoNetworkPage._handleWorkspaceCatalogDrop',
          () {
        final newItem = _buildWorkspaceItemFromCatalog(
          catalogItem: item,
          localOffset: localOffset,
        );

        setState(() {
          _workspaceItems = <WorkspaceData>[
            ..._workspaceItems,
            newItem,
          ];

          _selectedCatalogItemId = newItem.catalogItemId;
          _selectedWorkspaceItemId = newItem.id;
        });
      },
      warnMs: 6,
      data: {
        'catalogItemId': item.id,
        'workspaceItemsBefore': _workspaceItems.length,
        'x': localOffset.dx,
        'y': localOffset.dy,
      },
    );
  }

  void _handleWorkspaceItemChanged(
      String itemId,
      Offset newOffset,
      Size newSize,
      ) {
    SipgedPerf.traceSync(
      'GeoNetworkPage._handleWorkspaceItemChanged',
          () {
        final index = _workspaceItems.indexWhere((e) => e.id == itemId);
        if (index < 0) return;

        final current = _workspaceItems[index];
        final updated = current.copyWith(
          offset: newOffset,
          size: newSize,
        );

        if (updated == current) return;

        setState(() {
          final nextItems = List<WorkspaceData>.from(_workspaceItems);
          nextItems[index] = updated;
          _workspaceItems = nextItems;
        });
      },
      warnMs: 6,
      data: {
        'itemId': itemId,
        'workspaceItems': _workspaceItems.length,
        'w': newSize.width,
        'h': newSize.height,
      },
    );
  }

  void _handleWorkspaceItemRemoved(String itemId) {
    final removedIndex = _workspaceItems.indexWhere((e) => e.id == itemId);
    if (removedIndex < 0) return;

    setState(() {
      final nextItems = List<WorkspaceData>.from(_workspaceItems)
        ..removeAt(removedIndex);

      _workspaceItems = nextItems;

      if (_selectedWorkspaceItemId == itemId) {
        if (_workspaceItems.isEmpty) {
          _selectedWorkspaceItemId = null;
          _selectedCatalogItemId = null;
        } else {
          final fallback = _workspaceItems.last;
          _selectedWorkspaceItemId = fallback.id;
          _selectedCatalogItemId = fallback.catalogItemId;
        }
      } else if (_workspaceItems.isEmpty) {
        _selectedCatalogItemId = null;
      }
    });
  }

  void _handleWorkspaceItemSelected(WorkspaceData? item) {
    final nextWorkspaceId = item?.id;
    final nextCatalogId = item?.catalogItemId;

    if (_selectedWorkspaceItemId == nextWorkspaceId &&
        _selectedCatalogItemId == nextCatalogId) {
      return;
    }

    setState(() {
      _selectedWorkspaceItemId = nextWorkspaceId;
      _selectedCatalogItemId = nextCatalogId;
    });
  }

  void _handleWorkspacePropertyChanged(
      String itemId,
      ComponentDataProperty property,
      ) {
    final index = _workspaceItems.indexWhere((e) => e.id == itemId);
    if (index < 0) return;

    final current = _workspaceItems[index];
    final updated = current.copyWithUpdatedProperty(property.key, property);

    if (updated == current) return;

    setState(() {
      final nextItems = List<WorkspaceData>.from(_workspaceItems);
      nextItems[index] = updated;
      _workspaceItems = nextItems;

      if (_selectedWorkspaceItemId == itemId) {
        _selectedCatalogItemId = updated.catalogItemId;
      }
    });
  }

  Future<void> _handleWorkspaceBindingDropped(
      String itemId,
      String propertyKey,
      AttributeDataDrag data,
      List<LayerData> currentTree,
      ) async {
    final itemIndex = _workspaceItems.indexWhere((e) => e.id == itemId);
    if (itemIndex < 0) return;

    final currentItem = _workspaceItems[itemIndex];

    final updatedProperties = currentItem.properties.map((property) {
      if (property.key == propertyKey) {
        return property.copyWith(
          bindingValue: AttributeData(
            sourceId: data.sourceId,
            sourceLabel: data.sourceLabel,
            fieldName: data.fieldName,
            aggregation: data.aggregation,
            fieldValue: data.fieldValue,
          ),
        );
      }

      if (property.key == 'source') {
        final currentBinding = property.bindingValue;
        final currentSourceId = currentBinding?.sourceId?.trim() ?? '';

        if (currentSourceId.isEmpty || currentSourceId != data.sourceId) {
          return property.copyWith(
            bindingValue: AttributeData(
              sourceId: data.sourceId,
              sourceLabel: data.sourceLabel,
            ),
          );
        }
      }

      return property;
    }).toList(growable: false);

    final updatedItem = currentItem.copyWith(properties: updatedProperties);

    if (updatedItem != currentItem) {
      setState(() {
        final nextItems = List<WorkspaceData>.from(_workspaceItems);
        nextItems[itemIndex] = updatedItem;
        _workspaceItems = nextItems;

        if (_selectedWorkspaceItemId == itemId) {
          _selectedWorkspaceItemId = updatedItem.id;
          _selectedCatalogItemId = updatedItem.catalogItemId;
        }
      });
    }

    final layersCubit = context.read<LayerCubit>();
    final featureCubit = context.read<GeoFeatureCubit>();

    final layer = layersCubit.findNodeById(data.sourceId, tree: currentTree);
    if (layer == null || layer.isGroup) return;

    await featureCubit.ensureLayerFieldNames(layer, force: false);
    await featureCubit.ensureLayerLoaded(layer, force: false);
  }

  String _buildStatusIdentity({
    required MapState editorState,
    required ToolboxState measurementState,
    required LayerData? activePointLayer,
    required LayerData? activeLineLayer,
    required LayerData? activePolygonLayer,
  }) {
    if (editorState.isMeasureDistanceToolSelected || !measurementState.isEmpty) {
      return 'measure_${measurementState.points.length}'
          '_${measurementState.segmentDistancesMeters.length}'
          '_${measurementState.totalDistanceLabel}';
    }

    if (activePointLayer != null) {
      final count =
          editorState.draftPointLayers[activePointLayer.id]?.length ?? 0;
      return 'point_${activePointLayer.id}_$count';
    }

    if (activeLineLayer != null) {
      final count = editorState.draftLineLayers[activeLineLayer.id]?.length ?? 0;
      return 'line_${activeLineLayer.id}_$count';
    }

    if (activePolygonLayer != null) {
      final count =
          editorState.draftPolygonLayers[activePolygonLayer.id]?.length ?? 0;
      return 'polygon_${activePolygonLayer.id}_$count';
    }

    return 'idle';
  }

  int _findSecondFromRightInsertIndex(List<DockPanelData> groups) {
    final rightIndexes = <int>[];

    for (var i = 0; i < groups.length; i++) {
      if (groups[i].area == DockArea.right) {
        rightIndexes.add(i);
      }
    }

    if (rightIndexes.isEmpty) return groups.length;
    if (rightIndexes.length == 1) return rightIndexes.first;
    return rightIndexes[rightIndexes.length - 1];
  }

  int _findFirstRightInsertIndex(List<DockPanelData> groups) {
    for (var i = 0; i < groups.length; i++) {
      if (groups[i].area == DockArea.right) return i;
    }
    return groups.length;
  }

  List<DockPanelData> _ensureDefaultGroups(List<DockPanelData> source) {
    final next = <DockPanelData>[...source];

    final hasFerramentas = next.any((e) => e.id == 'group_ferramentas');
    final hasAtributos = next.any((e) => e.id == 'group_atributos');
    final hasVisualizacoes = next.any((e) => e.id == 'group_visualizacoes');
    final hasWorkspace = next.any((e) => e.id == 'group_area_trabalho');

    if (!hasFerramentas) {
      next.insert(
        _findFirstRightInsertIndex(next),
        const DockPanelData(
          id: 'group_ferramentas',
          title: 'Ferramentas',
          area: DockArea.right,
          crossSpan: DockCrossSpan.inner,
          visible: true,
          dockWeight: 0.70,
          icon: Icons.handyman_outlined,
          shrinkWrapOnMainAxis: true,
          items: [
            DockPanelDataItem(
              id: 'tools_main',
              title: 'Ferramentas',
              icon: Icons.handyman_outlined,
              contentPadding: EdgeInsets.zero,
              child: SizedBox.shrink(),
            ),
          ],
          activeItemId: 'tools_main',
        ),
      );
    }

    if (!hasAtributos) {
      next.insert(
        _findSecondFromRightInsertIndex(next),
        const DockPanelData(
          id: 'group_atributos',
          title: 'Atributos',
          area: DockArea.right,
          crossSpan: DockCrossSpan.inner,
          visible: true,
          dockWeight: 1.0,
          icon: Icons.info_outline,
          shrinkWrapOnMainAxis: false,
          items: [
            DockPanelDataItem(
              id: 'feature_attributes',
              title: 'Feição',
              icon: Icons.info_outline,
              contentPadding: EdgeInsets.all(8),
              child: SizedBox.shrink(),
            ),
          ],
          activeItemId: 'feature_attributes',
        ),
      );
    }

    if (!hasVisualizacoes) {
      const visualizationsGroup = DockPanelData(
        id: 'group_visualizacoes',
        title: 'Visualizações',
        area: DockArea.right,
        crossSpan: DockCrossSpan.inner,
        visible: true,
        dockWeight: 0.90,
        icon: Icons.dashboard_customize_outlined,
        shrinkWrapOnMainAxis: false,
        items: [
          DockPanelDataItem(
            id: 'catalogo_visualizacoes_itens',
            title: 'Itens',
            contentPadding: EdgeInsets.zero,
            child: SizedBox.shrink(),
          ),
          DockPanelDataItem(
            id: 'catalogo_visualizacoes_dados',
            title: 'Dados',
            contentPadding: EdgeInsets.zero,
            child: SizedBox.shrink(),
          ),
        ],
        activeItemId: 'catalogo_visualizacoes_itens',
      );

      final insertIndex = _findSecondFromRightInsertIndex(next);
      next.insert(insertIndex, visualizationsGroup);
    }

    if (!hasWorkspace) {
      next.add(
        const DockPanelData(
          id: 'group_area_trabalho',
          title: 'Área de trabalho',
          area: DockArea.bottom,
          crossSpan: DockCrossSpan.full,
          visible: true,
          dockWeight: 1.0,
          icon: Icons.space_dashboard_outlined,
          shrinkWrapOnMainAxis: false,
          items: [
            DockPanelDataItem(
              id: 'workspace_area_main',
              title: 'Área de trabalho',
              icon: Icons.space_dashboard_outlined,
              contentPadding: EdgeInsets.zero,
              child: SizedBox.shrink(),
            ),
          ],
          activeItemId: 'workspace_area_main',
        ),
      );
    }

    return next;
  }

  List<DockPanelData> _composePanelGroups({
    required BuildContext context,
    required MapState editorState,
    required LayerDataMap mapData,
    required GeoFeatureState genericState,
    required ToolboxState measurementState,
  }) {
    return SipgedPerf.traceSync(
      'GeoNetworkPage._composePanelGroups',
          () {
        final editorCubit = context.read<MapCubit>();
        final baseGroups = _ensureDefaultGroups(editorState.panelGroups);

        final workspaceItemsToken = _workspaceItemsToken();
        final selectedWorkspaceToken = _selectedWorkspaceItemToken();

        return baseGroups.map((group) {
          switch (group.id) {
            case 'group_ferramentas':
              return group.copyWith(
                shrinkWrapOnMainAxis: true,
                items: [
                  DockPanelDataItem(
                    id: 'tools_main',
                    title: 'Ferramentas',
                    icon: Icons.handyman_outlined,
                    contentPadding: EdgeInsets.zero,
                    contentToken: Object.hash(
                      editorState.selectedLayerPanelItemId,
                      editorState.selectedToolId,
                      editorState.activeEditingPointLayerId,
                      editorState.activeEditingLineLayerId,
                      editorState.activeEditingPolygonLayerId,
                      measurementState.points.length,
                    ),
                    child: RepaintBoundary(
                      child: ToolboxContent(
                        key: ValueKey(
                          'toolbox_content_'
                              '${editorState.selectedLayerPanelItemId ?? 'none'}_'
                              '${editorState.selectedToolId ?? 'none'}_'
                              '${editorState.activeEditingPointLayerId ?? 'none'}_'
                              '${editorState.activeEditingLineLayerId ?? 'none'}_'
                              '${editorState.activeEditingPolygonLayerId ?? 'none'}_'
                              '${measurementState.points.length}',
                        ),
                        onToolSelected: (message) => _showSnack(context, message),
                        selectedToolId: editorState.selectedToolId,
                        onSelectedTool: (id) async {
                          final error = await editorCubit.selectTool(id);
                          if (!mounted || error == null) return;
                          _showSnack(context, error);
                        },
                        selectedLayerGeometryKind:
                        editorCubit.selectedLayerGeometryKind(
                          mapData.currentTree,
                        ),
                        selectedItemIsGroup:
                        editorCubit.selectedItemIsGroup(mapData.currentTree),
                        pointEditingActive:
                        editorState.activeEditingPointLayerId != null,
                        lineEditingActive:
                        editorState.activeEditingLineLayerId != null,
                        polygonEditingActive:
                        editorState.activeEditingPolygonLayerId != null,
                      ),
                    ),
                  ),
                ],
                activeItemId: 'tools_main',
              );

            case 'group_vectorizacao':
              return group.copyWith(
                shrinkWrapOnMainAxis: false,
                dockExtent: 240,
                items: [
                  DockPanelDataItem(
                    id: 'layers_tree',
                    title: 'Camadas',
                    icon: Icons.account_tree_outlined,
                    contentPadding: EdgeInsets.zero,
                    contentToken: Object.hash(
                      mapData.currentTree.length,
                      Object.hashAll(mapData.currentTree),
                      mapData.activeLayerIds.length,
                      Object.hashAll(mapData.activeLayerIds),
                      editorState.selectedLayerPanelItemId,
                      editorState.activeEditingPointLayerId,
                      editorState.activeEditingLineLayerId,
                      editorState.activeEditingPolygonLayerId,
                      Object.hashAll(
                        mapData.hasDataByLayer.entries
                            .map((e) => Object.hash(e.key, e.value)),
                      ),
                    ),
                    child: RepaintBoundary(
                      child: LayerPanel(
                        key: ValueKey(
                          'layers_panel_'
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
                        onSelectedChanged: (id) {
                          context.read<GeoFeatureCubit>().clearSelection();
                          editorCubit.selectLayerPanelItem(id);
                        },
                        onToggleLayer: (id, active) => editorCubit.toggleLayer(
                          id,
                          active,
                          mapData.currentTree,
                        ),
                        hasDataByLayer: mapData.hasDataByLayer,
                        supportsConnect: (layer) =>
                        layer.supportsConnect && !layer.isGroup,
                        onMoveUp: (id) =>
                            editorCubit.moveLayerUp(id, mapData.currentTree),
                        onMoveDown: (id) =>
                            editorCubit.moveLayerDown(id, mapData.currentTree),
                        onCreateEmptyGroup: () =>
                            editorCubit.createEmptyGroup(mapData.currentTree),
                        onCreateLayer: () =>
                            editorCubit.createLayer(mapData.currentTree),
                        onDropItem: (draggedId, targetParentId, targetIndex) =>
                            editorCubit.dropItem(
                              draggedId,
                              targetParentId,
                              targetIndex,
                              mapData.currentTree,
                            ),
                        onRenameSelected: (id) =>
                            _editSelectedItem(id, mapData.currentTree),
                        onRemoveSelected: (id) =>
                            editorCubit.removeSelectedItem(
                              id,
                              mapData.currentTree,
                            ),
                        onConnectLayer: (id) =>
                            _handleConnectLayer(id, mapData.currentTree),
                        onOpenTable: (id) =>
                            _openLayerTable(context, id, mapData.currentTree),
                      ),
                    ),
                  ),
                ],
                activeItemId: 'layers_tree',
              );

            case 'group_atributos':
              return group.copyWith(
                shrinkWrapOnMainAxis: false,
                items: [
                  DockPanelDataItem(
                    id: 'feature_attributes',
                    title: 'Feição',
                    icon: Icons.info_outline,
                    contentToken: Object.hash(
                      genericState.selected?.feature.selectionKey,
                      editorState.selectedLayerPanelItemId,
                      Object.hashAll(
                        genericState.availableFieldsByLayer.entries.map(
                              (e) => Object.hash(e.key, Object.hashAll(e.value)),
                        ),
                      ),
                      Object.hashAll(
                        mapData.hasDataByLayer.entries.map(
                              (e) => Object.hash(e.key, e.value),
                        ),
                      ),
                    ),
                    child: RepaintBoundary(
                      child: AttributePanel(
                        key: ValueKey(
                          'attributes_panel_'
                              '${genericState.selected?.feature.selectionKey ?? 'none'}_'
                              '${editorState.selectedLayerPanelItemId ?? 'none'}_'
                              '${Object.hashAll(genericState.availableFieldsByLayer.entries.map((e) => Object.hash(e.key, Object.hashAll(e.value))))}_'
                              '${Object.hashAll(mapData.hasDataByLayer.entries.map((e) => Object.hash(e.key, e.value)))}',
                        ),
                        genericState: genericState,
                        layersById: mapData.layersById,
                        selectedLayerId: editorState.selectedLayerPanelItemId,
                        availableFieldsByLayer:
                        genericState.availableFieldsByLayer,
                        hasDataByLayer: mapData.hasDataByLayer,
                        onImportLayer: (layer) async {
                          await AttributeImportFeature.openImportDialog(
                            context,
                            layer: layer,
                          );

                          if (!mounted) return;

                          final shouldLoadOnMap =
                          mapData.activeLayerIds.contains(layer.id);

                          await AttributeImportFeature.reloadLayerAfterImport(
                            context,
                            layer: layer,
                            shouldLoadOnMap: shouldLoadOnMap,
                          );

                          if (!mounted) return;

                          await context.read<LayerCubit>().refreshLayerData(
                            layer,
                            force: true,
                          );

                          if (!mounted) return;

                          await context
                              .read<GeoFeatureCubit>()
                              .ensureLayerFieldNames(
                            layer,
                            force: true,
                          );

                          await context.read<GeoFeatureCubit>().ensureLayerLoaded(
                            layer,
                            force: true,
                          );
                        },
                        onOpenTable: (layer) async {
                          await _openLayerTable(
                            context,
                            layer.id,
                            mapData.currentTree,
                          );
                        },
                      ),
                    ),
                  ),
                ],
                activeItemId: 'feature_attributes',
              );

            case 'group_visualizacoes':
              return group.copyWith(
                shrinkWrapOnMainAxis: false,
                items: [
                  DockPanelDataItem(
                    id: 'catalogo_visualizacoes_itens',
                    title: 'Itens',
                    contentPadding: EdgeInsets.zero,
                    contentToken: Object.hash(
                      _selectedCatalogItemId,
                      'visual_items',
                    ),
                    child: RepaintBoundary(
                      child: ComponentPanel(
                        selectedItemId: _selectedCatalogItemId,
                        onItemTap: (item) {
                          if (_selectedCatalogItemId != item.id) {
                            setState(() {
                              _selectedCatalogItemId = item.id;
                            });
                          }

                          _showSnack(
                            context,
                            'Arraste "${item.title}" para a área de trabalho',
                          );
                        },
                      ),
                    ),
                  ),
                  DockPanelDataItem(
                    id: 'catalogo_visualizacoes_dados',
                    title: 'Dados',
                    contentPadding: EdgeInsets.zero,
                    contentToken: Object.hash(
                      selectedWorkspaceToken,
                      workspaceItemsToken,
                    ),
                    child: RepaintBoundary(
                      child: PropertyPanel(
                        key: ValueKey(
                          'visualizations_data_'
                              '$selectedWorkspaceToken'
                              '_$workspaceItemsToken',
                        ),
                        selectedItem: _selectedWorkspaceItem,
                        onPropertyChanged: _handleWorkspacePropertyChanged,
                        onBindingDropped: (itemId, propertyKey, data) {
                          _handleWorkspaceBindingDropped(
                            itemId,
                            propertyKey,
                            data,
                            mapData.currentTree,
                          );
                        },
                      ),
                    ),
                  ),
                ],
                activeItemId:
                group.activeItemId ?? 'catalogo_visualizacoes_itens',
              );

            case 'group_area_trabalho':
              return group.copyWith(
                shrinkWrapOnMainAxis: false,
                items: [
                  DockPanelDataItem(
                    id: 'workspace_area_main',
                    title: 'Área de trabalho',
                    icon: Icons.space_dashboard_outlined,
                    contentToken: 'workspace_area_main_stable',
                    contentPadding: EdgeInsets.zero,
                    child: RepaintBoundary(
                      child: WorkspacePanel(
                        items: _workspaceItems,
                        featuresByLayer: genericState.featuresByLayer,
                        onCatalogItemDropped: _handleWorkspaceCatalogDrop,
                        onItemChanged: _handleWorkspaceItemChanged,
                        onItemRemoved: _handleWorkspaceItemRemoved,
                        onSelectedCatalogItemChanged: (catalogItemId) {
                          if (_selectedCatalogItemId == catalogItemId) return;
                          setState(() {
                            _selectedCatalogItemId = catalogItemId;
                          });
                        },
                        onSelectedWorkspaceItemChanged:
                        _handleWorkspaceItemSelected,
                      ),
                    ),
                  ),
                ],
                activeItemId: 'workspace_area_main',
              );

            default:
              return group;
          }
        }).toList(growable: false);
      },
      warnMs: 12,
      data: {
        'panelGroups': editorState.panelGroups.length,
        'workspaceItems': _workspaceItems.length,
        'featureLayers': genericState.featuresByLayer.length,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LayerCubit, LayerState>(
          listenWhen: (p, c) =>
          p.error != c.error || p.tree != c.tree || p.loaded != c.loaded,
          listener: (context, state) {
            if (state.error != null && state.error!.trim().isNotEmpty) {
              _showSnack(context, state.error!);
            }

            if (state.loaded) {
              context.read<MapCubit>().syncWithTree(state.tree);

              final layersCubit = context.read<LayerCubit>();
              final ids = layersCubit
                  .flattenAllNodes(tree: state.tree)
                  .where((e) => !e.isGroup)
                  .map((e) => e.id)
                  .toSet();

              layersCubit.syncWithExistingTreeIds(ids);
            }
          },
        ),
        BlocListener<GeoFeatureCubit, GeoFeatureState>(
          listenWhen: (p, c) =>
          p.error != c.error || p.selected != c.selected,
          listener: (context, state) {
            if (state.error != null && state.error!.trim().isNotEmpty) {
              _showSnack(context, state.error!);
            }

            if (state.selected != null) {
              context.read<MapCubit>().showPanel('group_atributos');
              context
                  .read<MapCubit>()
                  .selectLayerPanelItem(state.selected!.layerId);
            }
          },
        ),
        BlocListener<MapCubit, MapState>(
          listenWhen: (p, c) =>
          p.selectedLayerPanelItemId != c.selectedLayerPanelItemId,
          listener: (context, state) async {
            final selectedId = state.selectedLayerPanelItemId;
            if (selectedId == null || selectedId.trim().isEmpty) return;

            final layersCubit = context.read<LayerCubit>();
            final layer = layersCubit.findNodeById(selectedId);

            if (layer == null || layer.isGroup) return;

            await context.read<GeoFeatureCubit>().ensureLayerFieldNames(
              layer,
              force: false,
            );

            await context.read<GeoFeatureCubit>().ensureLayerLoaded(
              layer,
              force: false,
            );
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          return SipgedPerf.traceSync(
            'GeoNetworkPage.build',
                () {
              final layersState = context.select((LayerCubit c) => c.state);
              final editorState = context.select((MapCubit c) => c.state);
              final measurementState =
              context.select((ToolboxCubit c) => c.state);
              final genericState =
              context.select((GeoFeatureCubit c) => c.state);

              final layersCubit = context.read<LayerCubit>();
              final editorCubit = context.read<MapCubit>();
              final featureCubit = context.read<GeoFeatureCubit>();

              final mapData = LayerDataMap.fromStates(
                layersCubit: layersCubit,
                mapCubit: editorCubit,
                featureCubit: featureCubit,
                layersState: layersState,
                mapState: editorState,
                featureState: genericState,
                toolboxState: measurementState,
              );

              final statusIdentity = _buildStatusIdentity(
                editorState: editorState,
                measurementState: measurementState,
                activePointLayer: mapData.activePointLayer,
                activeLineLayer: mapData.activeLineLayer,
                activePolygonLayer: mapData.activePolygonLayer,
              );

              if (_lastStatusIdentity != statusIdentity) {
                _lastStatusIdentity = statusIdentity;
                _statusDismissed = false;
              }

              final map = SizedBox.expand(
                child: RepaintBoundary(
                  child: MapChange(
                    features: mapData.visibleFeatures,
                    layersById: mapData.layersById,
                    orderedActiveLayerIds: mapData.orderedActiveLayerIdsForMap,
                    selectedFeatureKey: mapData.selectedFeatureKey,
                    loading: mapData.isLoading,
                    onControllerReady: (c) => controller = c,
                    onCameraChanged: (_, _) {},
                    cursor: editorState.mapCursor,
                    temporaryPointLayers: mapData.visiblePointDrafts,
                    temporaryLineLayers: mapData.visibleLineDrafts,
                    temporaryPolygonLayers: mapData.visiblePolygonDrafts,
                    distanceMeasurementPoints: measurementState.points,
                    onBackgroundTap: (latLng) {
                      editorCubit
                          .handleMapBackgroundTap(latLng, mapData.currentTree)
                          .then(
                            (error) {
                          if (!mounted) return;
                          if (error != null) _showSnack(context, error);
                        },
                      );

                      return editorState.isPointToolSelected ||
                          editorState.isLineToolSelected ||
                          editorState.isPolygonToolSelected ||
                          editorState.isMeasureDistanceToolSelected ||
                          editorState.isMeasureAreaToolSelected;
                    },
                    onFeatureTap: (feature) {
                      if (feature == null) {
                        context.read<GeoFeatureCubit>().clearSelection();
                        return;
                      }

                      final featureLayerId = (feature.layerId ?? '').trim();
                      if (featureLayerId.isEmpty) {
                        context.read<GeoFeatureCubit>().clearSelection();
                        return;
                      }

                      context.read<GeoFeatureCubit>().selectFeature(
                        layerId: featureLayerId,
                        feature: feature,
                      );

                      context
                          .read<MapCubit>()
                          .selectLayerPanelItem(featureLayerId);
                      context.read<MapCubit>().showPanel('group_atributos');
                    },
                  ),
                ),
              );

              final panelGroups = _composePanelGroups(
                context: context,
                editorState: editorState,
                mapData: mapData,
                genericState: genericState,
                measurementState: measurementState,
              );

              final showFloatingStatus =
                  !_statusDismissed && mapData.showFloatingStatus;

              return Scaffold(
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(70),
                  child: UpBar(
                    showPhotoMenu: true,
                    leading: const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: BackCircleButton(),
                    ),
                  ),
                ),
                body: ScreenLock(
                  locked: mapData.isLoading,
                  message: 'Carregando dados do mapa',
                  icon: Icons.map_outlined,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const Positioned.fill(
                        child: BackgroundChange(),
                      ),
                      Positioned.fill(
                        child: DockPanelWorkspace(
                          groups: panelGroups,
                          onChanged: context.read<MapCubit>().updatePanels,
                          child: map,
                        ),
                      ),
                      if (showFloatingStatus)
                        Positioned(
                          top: 10,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            bottom: false,
                            child: IgnorePointer(
                              ignoring: false,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints:
                                  const BoxConstraints(maxWidth: 820),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: StatusBar(
                                      editorState: editorState,
                                      measurementState: measurementState,
                                      activePointLayer: mapData.activePointLayer,
                                      activeLineLayer: mapData.activeLineLayer,
                                      activePolygonLayer:
                                      mapData.activePolygonLayer,
                                      onUndoDistanceMeasurementPoint: () =>
                                          context
                                              .read<ToolboxCubit>()
                                              .removeLastPoint(),
                                      onClearDistanceMeasurement: () =>
                                          context.read<ToolboxCubit>().clear(),
                                      onFinishDistanceMeasurement: () {
                                        context.read<ToolboxCubit>().clear();
                                        context.read<MapCubit>().selectTool(
                                          editorState.selectedToolId,
                                        );
                                      },
                                      onFinalizeCurrentPointEditing:
                                      editorCubit.finalizeCurrentPointEditing,
                                      onCancelCurrentPointEditing:
                                      editorCubit.cancelCurrentPointEditing,
                                      onFinalizeCurrentLineEditing:
                                      editorCubit.finalizeCurrentLineEditing,
                                      onCancelCurrentLineEditing:
                                      editorCubit.cancelCurrentLineEditing,
                                      onFinalizeCurrentPolygonEditing: editorCubit
                                          .finalizeCurrentPolygonEditing,
                                      onCancelCurrentPolygonEditing:
                                      editorCubit.cancelCurrentPolygonEditing,
                                      onClose: () {
                                        setState(() {
                                          _statusDismissed = true;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            warnMs: 16,
            data: {
              'workspaceItems': _workspaceItems.length,
              'selectedWorkspaceItemId': _selectedWorkspaceItemId,
            },
          );
        },
      ),
    );
  }
}