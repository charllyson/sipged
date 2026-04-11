import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:sipged/_blocs/modules/planning/geo/attribute/attribute_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_map.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/map/map_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/map/map_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/toolbox/toolbox_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/toolbox/toolbox_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_scope_data.dart';
import 'package:sipged/_blocs/system/panels/docking/dock_panel_data.dart';
import 'package:sipged/_widgets/buttons/back_circle_button.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_workspace.dart';
import 'package:sipged/_blocs/system/panels/push/push_panel_data.dart';
import 'package:sipged/_widgets/panels/push/push_panels.dart';
import 'package:sipged/_blocs/system/panels/push/push_panels_controller.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/attribute_panel.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/attribute_table.dart';
import 'package:sipged/screens/modules/planning/geo/catalog/catalog_panel.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layer_drawer.dart';
import 'package:sipged/screens/modules/planning/geo/map/map_change.dart';
import 'package:sipged/screens/modules/planning/geo/properties/dialog/layer_properties_dialog.dart';
import 'package:sipged/screens/modules/planning/geo/status/status_bar.dart';
import 'package:sipged/screens/modules/planning/geo/toolbox/toolbox_panel.dart';
import 'package:sipged/screens/modules/planning/geo/workspace/workspace_panel.dart';

part 'geo_network_layer.dart';
part 'geo_network_workspace.dart';
part 'geo_network_builders.dart';

class GeoNetworkView extends StatefulWidget {
  const GeoNetworkView({super.key});

  @override
  State<GeoNetworkView> createState() => _GeoNetworkViewState();
}

class _GeoNetworkViewState extends State<GeoNetworkView> {
  static const String _panelFerramentasId = 'push_panel_ferramentas';
  static const String _panelVisualizacoesId = 'push_panel_visualizacoes';
  static const String _panelAtributosId = 'push_panel_atributos';
  static const String _workspaceGroupId = 'group_area_trabalho';


  static const List<PushPanelData> _basePanels = [
    PushPanelData(
      id: _panelFerramentasId,
      title: 'Ferramentas',
      icon: Icons.handyman_outlined,
    ),
    PushPanelData(
      id: _panelVisualizacoesId,
      title: 'Catálogo',
      icon: Icons.dashboard_customize_outlined,
    ),
    PushPanelData(
      id: _panelAtributosId,
      title: 'Atributos',
      icon: Icons.info_outline,
    ),
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<WorkspacePanelState> _workspacePanelKey =
  GlobalKey<WorkspacePanelState>();

  final PushPanelsController _pushPanelsController = PushPanelsController();

  MapController? controller;

  final Map<String, List<WorkspaceData>> _workspaceItemsByScope =
  <String, List<WorkspaceData>>{};

  String? _selectedCatalogItemId;
  String? _selectedWorkspaceItemId;
  CatalogData? _pendingCatalogPlacement;

  bool _statusDismissed = false;
  String _lastStatusIdentity = '';

  List<WorkspaceData>? _lastWorkspaceItemsRef;
  Object? _lastWorkspaceItemsToken;

  Size _workspacePanelSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _pushPanelsController.addListener(_handlePushPanelsChanged);
  }

  @override
  void dispose() {
    _pushPanelsController.removeListener(_handlePushPanelsChanged);
    _pushPanelsController.dispose();
    super.dispose();
  }

  void _handlePushPanelsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  WorkspaceScopeData get _currentWorkspaceScope {
    final selectedId = context.read<MapCubit>().state.selectedLayerPanelItemId;
    if (selectedId == null || selectedId.trim().isEmpty) {
      return const WorkspaceScopeData.general();
    }

    final layerCubit = context.read<LayerCubit>();
    final node = layerCubit.findNodeById(selectedId);

    if (node == null) {
      return const WorkspaceScopeData.general();
    }

    if (node.isGroup) {
      return WorkspaceScopeData(
        type: WorkspaceScopeType.group,
        id: node.id,
      );
    }

    return WorkspaceScopeData(
      type: WorkspaceScopeType.layer,
      id: node.id,
    );
  }

  String _workspaceScopeKey(WorkspaceScopeData scope) {
    return '${scope.type.name}:${scope.documentId}';
  }

  List<WorkspaceData> get _workspaceItems {
    final scope = _currentWorkspaceScope;
    final key = _workspaceScopeKey(scope);
    return _workspaceItemsByScope[key] ?? const <WorkspaceData>[];
  }

  WorkspaceData? get _selectedWorkspaceItem {
    for (final item in _workspaceItems) {
      if (item.id == _selectedWorkspaceItemId) return item;
    }
    return null;
  }

  void _handleWorkspaceItemsChangedFromPanel(List<WorkspaceData> items) {
    final scope = _currentWorkspaceScope;
    final key = _workspaceScopeKey(scope);

    final current = _workspaceItemsByScope[key] ?? const <WorkspaceData>[];
    if (listEquals(current, items)) return;

    setState(() {
      _workspaceItemsByScope[key] = List<WorkspaceData>.from(items);
      _lastWorkspaceItemsRef = null;
      _lastWorkspaceItemsToken = null;
    });
  }

  void _handleWorkspacePanelSizeChanged(Size size) {
    if (_workspacePanelSize == size) return;

    setState(() {
      _workspacePanelSize = size;
    });
  }

  void _toggleWorkspaceVisibility(BuildContext context) {
    context.read<MapCubit>().toggleWorkspacePanelVisibility();
  }

  void _openContextDrawer() {
    final state = _scaffoldKey.currentState;
    if (state == null) return;

    if (state.isDrawerOpen) {
      Navigator.of(context).maybePop();
      return;
    }

    state.openDrawer();
  }

  void _togglePushPanel(String id) {
    _pushPanelsController.toggle(id);
  }

  void _openPushPanel(String id) {
    _pushPanelsController.open(id);
  }

  bool _isPushPanelOpen(String id) {
    return _pushPanelsController.isOpen(id);
  }

  bool _isContextDrawerOpen() {
    return _scaffoldKey.currentState?.isDrawerOpen ?? false;
  }

  List<PushPanelData> _buildPushPanels({
    required LayerDataMap mapData,
    required MapState editorState,
    required ToolboxState measurementState,
    required FeatureState genericState,
  }) {
    return _basePanels.map((panel) {
      if (panel.id == _panelFerramentasId) {
        return panel.copyWith(
          child: GeoFerramentasPanel(
            mapData: mapData,
            editorState: editorState,
            measurementState: measurementState,
            onShowMessage: (message) => _showSnack(context, message),
          ),
        );
      }

      if (panel.id == _panelVisualizacoesId) {
        return panel.copyWith(
          child: CatalogPanel(
            selectedCatalogItemId: _selectedCatalogItemId,
            selectedWorkspaceItem: _selectedWorkspaceItem,
            workspaceItemsToken: _workspaceItemsToken(),
            selectedWorkspaceToken: _selectedWorkspaceItemToken(),
            onCatalogItemTap: _handleCatalogItemTap,
            onPropertyChanged: _handleWorkspacePropertyChanged,
            onBindingDropped: (itemId, propertyKey, data) {
              _handleWorkspaceBindingDropped(
                itemId,
                propertyKey,
                data,
                context.read<LayerCubit>().state.tree,
              );
            },
          ),
        );
      }

      return panel.copyWith(
        child: AttributePanel(
          mapData: mapData,
          editorState: editorState,
          genericState: genericState,
          onOpenLayerTable: (layer) async {
            await _openLayerTable(
              context,
              layer.id,
              mapData.currentTree,
            );
          },
        ),
      );
    }).toList(growable: false);
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
        BlocListener<FeatureCubit, FeatureState>(
          listenWhen: (p, c) => p.error != c.error || p.selected != c.selected,
          listener: (context, state) {
            if (state.error != null && state.error!.trim().isNotEmpty) {
              _showSnack(context, state.error!);
            }

            if (state.selected != null) {
              context.read<MapCubit>().selectLayerPanelItem(
                state.selected!.layerId,
              );
              _openPushPanel(_panelAtributosId);
            }
          },
        ),
        BlocListener<MapCubit, MapState>(
          listenWhen: (p, c) =>
          p.selectedLayerPanelItemId != c.selectedLayerPanelItemId,
          listener: (context, state) async {
            final selectedId = state.selectedLayerPanelItemId;

            setState(() {
              _selectedWorkspaceItemId = null;
              _selectedCatalogItemId = null;
              _pendingCatalogPlacement = null;
            });

            if (selectedId == null || selectedId.trim().isEmpty) return;

            final layersCubit = context.read<LayerCubit>();
            final layer = layersCubit.findNodeById(selectedId);

            if (layer == null || layer.isGroup) return;

            await context.read<FeatureCubit>().ensureLayerFieldNames(
              layer,
              force: false,
            );

            await context.read<FeatureCubit>().ensureLayerLoaded(
              layer,
              force: false,
            );
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          final layersState = context.select((LayerCubit c) => c.state);
          final editorState = context.select((MapCubit c) => c.state);
          final measurementState = context.select((ToolboxCubit c) => c.state);
          final genericState = context.select((FeatureCubit c) => c.state);

          final layersCubit = context.read<LayerCubit>();
          final editorCubit = context.read<MapCubit>();
          final featureCubit = context.read<FeatureCubit>();

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
                      .then((error) {
                    if (!mounted) return;
                    if (error != null) _showSnack(context, error);
                  });

                  return editorState.isPointToolSelected ||
                      editorState.isLineToolSelected ||
                      editorState.isPolygonToolSelected ||
                      editorState.isMeasureDistanceToolSelected ||
                      editorState.isMeasureAreaToolSelected;
                },
                onFeatureTap: (feature) {
                  if (feature == null) {
                    context.read<FeatureCubit>().clearSelection();
                    return;
                  }

                  final featureLayerId = (feature.layerId ?? '').trim();
                  if (featureLayerId.isEmpty) {
                    context.read<FeatureCubit>().clearSelection();
                    return;
                  }

                  context.read<FeatureCubit>().selectFeature(
                    layerId: featureLayerId,
                    feature: feature,
                  );

                  context.read<MapCubit>().selectLayerPanelItem(featureLayerId);
                  _openPushPanel(_panelAtributosId);
                },
              ),
            ),
          );

          final workspaceDockGroups = _composeWorkspaceDockGroups(
            editorState: editorState,
            genericState: genericState,
          );

          final showFloatingStatus =
              !_statusDismissed && mapData.showFloatingStatus;

          final content = Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: DockPanelWorkspace(
                  groups: workspaceDockGroups,
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
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: StatusBar(
                              editorState: editorState,
                              measurementState: measurementState,
                              activePointLayer: mapData.activePointLayer,
                              activeLineLayer: mapData.activeLineLayer,
                              activePolygonLayer: mapData.activePolygonLayer,
                              onUndoDistanceMeasurementPoint: () =>
                                  context.read<ToolboxCubit>().removeLastPoint(),
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
                              onFinalizeCurrentPolygonEditing:
                              editorCubit.finalizeCurrentPolygonEditing,
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
          );

          final pushPanels = _buildPushPanels(
            mapData: mapData,
            editorState: editorState,
            measurementState: measurementState,
            genericState: genericState,
          );

          return Scaffold(
            key: _scaffoldKey,
            drawer: LayerDrawer(
              mapData: mapData,
              editorState: editorState,
              onSelectedChanged: (id) {
                context.read<FeatureCubit>().clearSelection();
                context.read<MapCubit>().selectLayerPanelItem(id);
              },
              onToggleLayer: (id, active) =>
                  context.read<MapCubit>().toggleLayer(
                    id,
                    active,
                    mapData.currentTree,
                  ),
              onMoveUp: (id) => context.read<MapCubit>().moveLayerUp(
                id,
                mapData.currentTree,
              ),
              onMoveDown: (id) => context.read<MapCubit>().moveLayerDown(
                id,
                mapData.currentTree,
              ),
              onCreateLayer: (parentId, targetIndex) async {
                await context.read<LayerCubit>().createLayer(
                  parentId: parentId,
                  targetIndex: targetIndex,
                );
              },
              onCreateEmptyGroup: (parentId, targetIndex) async {
                await context.read<LayerCubit>().createEmptyGroup(
                  parentId: parentId,
                  targetIndex: targetIndex,
                );
              },
              onDropItem: (draggedId, targetParentId, targetIndex) =>
                  context.read<MapCubit>().dropItem(
                    draggedId,
                    targetParentId,
                    targetIndex,
                    mapData.currentTree,
                  ),
              onRenameSelected: (id) =>
                  _editSelectedItem(id, mapData.currentTree),
              onRemoveSelected: (id) =>
                  context.read<MapCubit>().removeSelectedItem(
                    id,
                    mapData.currentTree,
                  ),
              onConnectLayer: (id) =>
                  _handleConnectLayer(id, mapData.currentTree),
              onOpenTable: (id) =>
                  _openLayerTable(context, id, mapData.currentTree),
            ),
            endDrawerEnableOpenDragGesture: true,
            appBar: UpBar(
              includeSafeTop: true,
              showPhotoMenu: true,
              leadingActions: [
                _buildActionButton(
                  icon: Icons.tune_outlined,
                  tooltip: 'Camadas',
                  active: _isContextDrawerOpen(),
                  onTap: _openContextDrawer,
                ),
              ],
              actions: _buildAppBarActions(editorState),
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
                    child: PushPanels(
                      controller: _pushPanelsController,
                      panels: pushPanels,
                      child: content,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}