import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:sipged/_blocs/modules/planning/geo/attributes/geo_attributes_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/map/geo_map_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/map/geo_map_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/toolbox/geo_toolbox_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/toolbox/geo_toolbox_state.dart';
import 'package:sipged/_widgets/background/background_cleaner.dart';
import 'package:sipged/_widgets/buttons/back_circle_button.dart';
import 'package:sipged/_widgets/docking/dock_panel_types.dart';
import 'package:sipged/_widgets/docking/dock_panel_workspace.dart';
import 'package:sipged/_widgets/geo/layer/layer_panel.dart';
import 'package:sipged/_widgets/geo/properties/dialog/layer_properties_dialog.dart';
import 'package:sipged/_widgets/geo/toolbox/toolbox_content.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/screens/modules/planning/geo/geo_network_attributes.dart';
import 'package:sipged/screens/modules/planning/geo/geo_network_layer.dart';
import 'package:sipged/screens/modules/planning/geo/geo_network_map.dart';

class GeoNetworkPage extends StatelessWidget {
  const GeoNetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final geoLayersRepository = GeoLayersRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GeoAttributesCubit()),
        BlocProvider(create: (_) => GeoToolboxCubit()),
        BlocProvider(
          create: (_) => GeoLayersCubit(
            repository: geoLayersRepository,
          )..load(),
        ),
        BlocProvider(
          create: (_) => GeoFeatureCubit(
            repository: GeoFeatureRepository(),
          ),
        ),
        BlocProvider(
          create: (context) => GeoMapCubit(
            layersCubit: context.read<GeoLayersCubit>(),
            featureCubit: context.read<GeoFeatureCubit>(),
            toolboxCubit: context.read<GeoToolboxCubit>(),
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

  Future<GeoLayersData?> _askEditLayerData({
    required BuildContext context,
    required GeoLayersData current,
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
      List<GeoLayersData> currentTree,
      ) async {
    final layersCubit = context.read<GeoLayersCubit>();
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
      List<GeoLayersData> currentTree,
      ) async {
    final layersCubit = context.read<GeoLayersCubit>();
    final layer = layersCubit.findNodeById(rawId, tree: currentTree);

    if (layer == null || layer.isGroup) return;

    final isAlreadyActive = layersCubit.state.activeLayerIds.contains(layer.id);

    await GeoNetworkLayer.handleConnectLayer(
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
  }

  void _showSnack(String message) {
    if (!mounted) return;
    if (message.trim().isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<DockPanelGroupData> _composePanelGroups({
    required BuildContext context,
    required GeoMapState editorState,
    required List<GeoLayersData> currentTree,
    required GeoFeatureState genericState,
    required Map<String, GeoLayersData> layersById,
    required Set<String> activeLayerIds,
    required Map<String, bool> hasDataByLayer,
    required GeoToolboxState measurementState,
  }) {
    final editorCubit = context.read<GeoMapCubit>();
    final layersCubit = context.read<GeoLayersCubit>();

    final activePointLayer = editorCubit.getActiveDraftPointLayer(currentTree);
    final activeLineLayer = editorCubit.getActiveDraftLineLayer(currentTree);
    final activePolygonLayer =
    editorCubit.getActiveDraftPolygonLayer(currentTree);

    return editorState.panelGroups.map((group) {
      switch (group.id) {
        case 'group_ferramentas':
          return group.copyWith(
            items: [
              DockPanelItemData(
                id: 'tools_main',
                title: 'Ferramentas',
                icon: Icons.handyman_outlined,
                contentPadding: EdgeInsets.zero,
                child: RepaintBoundary(
                  child: ToolboxContent(
                    key: ValueKey(
                      'toolbox_content_${editorState.selectedLayerPanelItemId ?? 'none'}_${editorState.selectedToolId ?? 'none'}_${editorState.activeEditingPointLayerId ?? 'none'}_${editorState.activeEditingLineLayerId ?? 'none'}_${editorState.activeEditingPolygonLayerId ?? 'none'}_${measurementState.points.length}',
                    ),
                    onToolSelected: _showSnack,
                    selectedToolId: editorState.selectedToolId,
                    onSelectedTool: (id) async {
                      final error = await editorCubit.selectTool(id);
                      if (!mounted || error == null) return;
                      _showSnack(error);
                    },
                    selectedLayerGeometryKind:
                    editorCubit.selectedLayerGeometryKind(currentTree),
                    selectedItemIsGroup:
                    editorCubit.selectedItemIsGroup(currentTree),
                    pointEditingActive:
                    editorState.activeEditingPointLayerId != null,
                    lineEditingActive:
                    editorState.activeEditingLineLayerId != null,
                    polygonEditingActive:
                    editorState.activeEditingPolygonLayerId != null,
                    editorState: editorState,
                    measurementState: measurementState,
                    activePointLayer: activePointLayer,
                    activeLineLayer: activeLineLayer,
                    activePolygonLayer: activePolygonLayer,
                    onUndoDistanceMeasurementPoint: () =>
                        context.read<GeoToolboxCubit>().removeLastPoint(),
                    onClearDistanceMeasurement: () =>
                        context.read<GeoToolboxCubit>().clear(),
                    onFinishDistanceMeasurement: () {
                      context.read<GeoToolboxCubit>().clear();
                      context
                          .read<GeoMapCubit>()
                          .selectTool(editorState.selectedToolId);
                    },
                    onFinalizeCurrentPointEditing:
                    editorCubit.finalizeCurrentPointEditing,
                    onCancelCurrentPointEditing:
                    editorCubit.cancelCurrentPointEditing,
                    onFinalizeCurrentLineEditing:
                    editorCubit.finalizeCurrentLineEditing,
                    onCancelCurrentLineEditing:
                    editorCubit.cancelCurrentLineEditing,
                    onFinalizeCurrentPolygonEditing:
                    editorCubit.finalizeCurrentPolygonEditing,
                    onCancelCurrentPolygonEditing:
                    editorCubit.cancelCurrentPolygonEditing,
                  ),
                ),
              ),
            ],
            activeItemId: 'tools_main',
          );

        case 'group_vectorizacao':
          return group.copyWith(
            items: [
              DockPanelItemData(
                id: 'layers_tree',
                title: 'Camadas',
                icon: Icons.account_tree_outlined,
                contentPadding: EdgeInsets.zero,
                child: RepaintBoundary(
                  child: LayerPanel(
                    key: ValueKey(
                      'layers_panel_${currentTree.length}_${activeLayerIds.length}_${editorState.selectedLayerPanelItemId ?? 'none'}_${editorState.activeEditingPointLayerId ?? 'none'}_${editorState.activeEditingLineLayerId ?? 'none'}_${editorState.activeEditingPolygonLayerId ?? 'none'}',
                    ),
                    layers: currentTree,
                    activeLayerIds: activeLayerIds,
                    selectedId: editorState.selectedLayerPanelItemId,
                    onSelectedChanged: editorCubit.selectLayerPanelItem,
                    onToggleLayer: (id, active) =>
                        editorCubit.toggleLayer(id, active, currentTree),
                    hasDataByLayer: hasDataByLayer,
                    supportsConnect: (layer) =>
                    layer.supportsConnect && !layer.isGroup,
                    onMoveUp: (id) => editorCubit.moveLayerUp(id, currentTree),
                    onMoveDown: (id) =>
                        editorCubit.moveLayerDown(id, currentTree),
                    onCreateEmptyGroup: () =>
                        editorCubit.createEmptyGroup(currentTree),
                    onCreateLayer: () => editorCubit.createLayer(currentTree),
                    onDropItem: (draggedId, targetParentId, targetIndex) =>
                        editorCubit.dropItem(
                          draggedId,
                          targetParentId,
                          targetIndex,
                          currentTree,
                        ),
                    onRenameSelected: (id) => _editSelectedItem(id, currentTree),
                    onRemoveSelected: (id) =>
                        editorCubit.removeSelectedItem(id, currentTree),
                    onConnectLayer: (id) => _handleConnectLayer(id, currentTree),
                    onOpenTable: (id) async {
                      final layer =
                      layersCubit.findNodeById(id, tree: currentTree);

                      if (layer == null || layer.isGroup) return;

                      editorCubit.selectLayerPanelItem(layer.id);

                      if (!layersCubit.state.activeLayerIds.contains(layer.id)) {
                        layersCubit.toggleLayer(layer.id, true);
                      }

                      await context.read<GeoFeatureCubit>().ensureLayerLoaded(
                        layer,
                        force: true,
                      );

                      if (!mounted) return;

                      await GeoNetworkLayer.openFirestoreTable(
                        context,
                        layer: layer,
                      );
                    },
                  ),
                ),
              ),
            ],
            activeItemId: 'layers_tree',
          );

        case 'group_atributos':
          return group.copyWith(
            items: [
              DockPanelItemData(
                id: 'feature_attributes',
                title: 'Feição',
                icon: Icons.info_outline,
                child: GeoNetworkAttributes(
                  genericState: genericState,
                  layersById: layersById,
                ),
              ),
            ],
            activeItemId: 'feature_attributes',
          );

        default:
          return group;
      }
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GeoLayersCubit, GeoLayersState>(
          listenWhen: (p, c) =>
          p.error != c.error || p.tree != c.tree || p.loaded != c.loaded,
          listener: (context, state) {
            if (state.error != null && state.error!.trim().isNotEmpty) {
              _showSnack(state.error!);
            }

            if (state.loaded) {
              context.read<GeoMapCubit>().syncWithTree(state.tree);

              final layersCubit = context.read<GeoLayersCubit>();
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
          listenWhen: (p, c) => p.error != c.error || p.selected != c.selected,
          listener: (context, state) {
            if (state.error != null && state.error!.trim().isNotEmpty) {
              _showSnack(state.error!);
            }

            if (state.selected != null) {
              context.read<GeoMapCubit>().showPanel('group_atributos');
            }
          },
        ),
      ],
      child: BlocBuilder<GeoLayersCubit, GeoLayersState>(
        builder: (context, layersState) {
          final currentTree = layersState.tree;
          final activeLayerIds = layersState.activeLayerIds;
          final hasDataByLayer = layersState.hasDataByLayer;
          final layersCubit = context.read<GeoLayersCubit>();

          return BlocBuilder<GeoMapCubit, GeoMapState>(
            builder: (context, editorState) {
              return BlocBuilder<GeoToolboxCubit, GeoToolboxState>(
                builder: (context, measurementState) {
                  return BlocBuilder<GeoFeatureCubit, GeoFeatureState>(
                    builder: (context, genericState) {
                      final allNodes =
                      layersCubit.flattenAllNodes(tree: currentTree);

                      final layersById = <String, GeoLayersData>{
                        for (final e in allNodes.where((e) => !e.isGroup))
                          e.id: e,
                      };

                      final orderedLeafIdsTopToBottom = layersCubit
                          .flattenOrderedLeafIds(tree: currentTree)
                          .where((id) => activeLayerIds.contains(id))
                          .toList(growable: false);

                      final orderedForMap =
                      orderedLeafIdsTopToBottom.reversed.toList();

                      final visibleFeatures = <GeoFeatureData>[];
                      for (final layerId in orderedForMap) {
                        visibleFeatures.addAll(
                          genericState.featuresByLayer[layerId] ??
                              const <GeoFeatureData>[],
                        );
                      }

                      final editorCubit = context.read<GeoMapCubit>();

                      final map = RepaintBoundary(
                        child: GeoNetworkMap(
                          features: visibleFeatures,
                          layersById: layersById,
                          orderedActiveLayerIds: orderedForMap,
                          selectedFeatureKey:
                          genericState.selected?.feature.selectionKey,
                          loading: genericState.isAnyLoading ||
                              layersState.isSaving ||
                              layersState.isRefreshingLayerData,
                          onControllerReady: (c) => controller = c,
                          onCameraChanged: (_, _) {},
                          cursor: editorState.mapCursor,
                          temporaryPointLayers:
                          editorCubit.buildVisiblePointDrafts(activeLayerIds),
                          temporaryLineLayers:
                          editorCubit.buildVisibleLineDrafts(activeLayerIds),
                          temporaryPolygonLayers:
                          editorCubit.buildVisiblePolygonDrafts(
                            activeLayerIds,
                          ),
                          distanceMeasurementPoints: measurementState.points,
                          onBackgroundTap: (latLng) {
                            editorCubit
                                .handleMapBackgroundTap(latLng, currentTree)
                                .then((error) {
                              if (!mounted || error == null) return;
                              _showSnack(error);
                            });

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

                            context.read<GeoFeatureCubit>().selectFeature(
                              layerId: feature.layerId,
                              feature: feature,
                            );
                          },
                        ),
                      );

                      final panelGroups = _composePanelGroups(
                        context: context,
                        editorState: editorState,
                        currentTree: currentTree,
                        genericState: genericState,
                        layersById: layersById,
                        activeLayerIds: activeLayerIds,
                        hasDataByLayer: hasDataByLayer,
                        measurementState: measurementState,
                      );

                      final isLoading = genericState.isAnyLoading ||
                          layersState.isSaving ||
                          layersState.isRefreshingLayerData;

                      return Scaffold(
                        appBar: PreferredSize(
                          preferredSize: const Size.fromHeight(70),
                          child: UpBar(
                            showPhotoMenu: true,
                            leading: const Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: BackCircleButton(),
                            ),
                            actions: [
                              BackCircleButton(
                                tooltip:
                                'Mostrar ou ocultar caixa de ferramentas',
                                icon: Icons.handyman_outlined,
                                onPressed: () => context
                                    .read<GeoMapCubit>()
                                    .togglePanelVisibility(
                                  'group_ferramentas',
                                ),
                              ),
                              BackCircleButton(
                                tooltip:
                                'Mostrar ou ocultar painel de camadas',
                                icon: Icons.layers_outlined,
                                onPressed: () => context
                                    .read<GeoMapCubit>()
                                    .togglePanelVisibility(
                                  'group_vectorizacao',
                                ),
                              ),
                              BackCircleButton(
                                tooltip:
                                'Mostrar ou ocultar painel de atributos',
                                icon: Icons.table_rows_outlined,
                                onPressed: () => context
                                    .read<GeoMapCubit>()
                                    .togglePanelVisibility(
                                  'group_atributos',
                                ),
                              ),
                            ],
                          ),
                        ),
                        body: ScreenLock(
                          locked: isLoading,
                          message: 'Carregando dados do mapa',
                          icon: Icons.map_outlined,
                          child: Stack(
                            children: [
                              const BackgroundClean(),
                              DockPanelWorkspace(
                                groups: panelGroups,
                                onChanged:
                                context.read<GeoMapCubit>().updatePanels,
                                child: map,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}