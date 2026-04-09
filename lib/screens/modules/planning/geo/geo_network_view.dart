import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:sipged/_blocs/modules/planning/geo/attribute/attribute_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_cubit.dart';
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
import 'package:sipged/_blocs/system/docking/dock_panel_data.dart';
import 'package:sipged/_widgets/buttons/back_circle_button.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_workspace.dart';
import 'package:sipged/_widgets/panels/push/push_panel_data.dart';
import 'package:sipged/_widgets/panels/push/push_panels.dart';
import 'package:sipged/_widgets/panels/push/push_panels_controller.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/attribute_panel.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/attribute_table.dart';
import 'package:sipged/screens/modules/planning/geo/catalog/catalog_panel.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layer_drawer.dart';
import 'package:sipged/screens/modules/planning/geo/map/map_change.dart';
import 'package:sipged/screens/modules/planning/geo/properties/dialog/layer_properties_dialog.dart';
import 'package:sipged/screens/modules/planning/geo/status/status_bar.dart';
import 'package:sipged/screens/modules/planning/geo/toolbox/toolbox_panel.dart';
import 'package:sipged/screens/modules/planning/geo/workspace/workspace_panel.dart';

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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PushPanelsController _pushPanelsController = PushPanelsController();

  MapController? controller;

  List<WorkspaceData> _workspaceItems = const <WorkspaceData>[];
  int _workspaceCounter = 0;

  String? _selectedCatalogItemId;
  String? _selectedWorkspaceItemId;

  bool _statusDismissed = false;
  String _lastStatusIdentity = '';

  List<WorkspaceData>? _lastWorkspaceItemsRef;
  Object? _lastWorkspaceItemsToken;

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

  WorkspaceData? get _selectedWorkspaceItem {
    for (final item in _workspaceItems) {
      if (item.id == _selectedWorkspaceItemId) return item;
    }
    return null;
  }

  DockPanelData? _findWorkspaceGroup(MapState state) {
    for (final group in state.panelGroups) {
      if (group.id == _workspaceGroupId) return group;
    }
    return null;
  }

  bool _isWorkspaceVisible(MapState state) {
    return _findWorkspaceGroup(state)?.visible ?? true;
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

    final token = Object.hashAll(_workspaceItems.map(_workspaceItemToken));

    _lastWorkspaceItemsRef = _workspaceItems;
    _lastWorkspaceItemsToken = token;
    return token;
  }

  Object _selectedWorkspaceItemToken() {
    final item = _selectedWorkspaceItem;
    return item?.id ?? 'no_selected_workspace_item';
  }

  Future<LayerData?> _askEditLayerData({
    required BuildContext context,
    required LayerData current,
  }) async {
    final geoFeatureCubit = context.read<FeatureCubit>();
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

  Future<void> _openImportDialog(
      BuildContext context, {
        required LayerData layer,
      }) async {
    final featureCubit = context.read<FeatureCubit>();
    final path = layer.effectiveCollectionPath ?? '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: featureCubit,
        child: AttributeTable(
          mode: AttributeTableMode.importFile,
          collectionPath: path,
          targetFields: const [],
          title: 'Importar ${layer.title}',
          description:
          'Importe GeoJSON / KML / KMZ. Após salvar, as feições desta camada serão gravadas no Firebase dentro da coleção principal geo e poderão ser desenhadas dinamicamente no mapa.',
        ),
      ),
    );
  }

  Future<void> _openFirestoreTableDialog(
      BuildContext context, {
        required LayerData layer,
      }) async {
    final featureCubit = context.read<FeatureCubit>();
    final path = layer.effectiveCollectionPath ?? '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: featureCubit,
        child: AttributeTable(
          mode: AttributeTableMode.firestore,
          collectionPath: path,
          targetFields: const [],
          title: 'Tabela de atributos - ${layer.title}',
          description:
          'Visualização dinâmica do Firebase. Cada documento é uma feição geográfica desta camada.',
        ),
      ),
    );
  }

  Future<void> _reloadLayerAfterImport(
      BuildContext context, {
        required LayerData layer,
        required bool shouldLoadOnMap,
      }) async {
    await context.read<LayerCubit>().refreshLayerData(
      layer,
      force: true,
    );

    if (shouldLoadOnMap) {
      await context.read<FeatureCubit>().reloadLayer(layer);
    }
  }

  Future<void> _handleConnectLayer(
      String rawId,
      List<LayerData> currentTree,
      ) async {
    final layersCubit = context.read<LayerCubit>();
    final layer = layersCubit.findNodeById(rawId, tree: currentTree);

    if (layer == null || layer.isGroup || !layer.supportsConnect) return;

    final path = (layer.effectiveCollectionPath ?? '').trim();
    if (path.isEmpty) return;

    final isAlreadyActive = layersCubit.state.activeLayerIds.contains(layer.id);
    final hasData = layersCubit.state.hasDataByLayer[layer.id] == true;

    if (hasData) {
      await _openFirestoreTableDialog(
        context,
        layer: layer,
      );
      return;
    }

    await _openImportDialog(
      context,
      layer: layer,
    );

    if (!mounted) return;

    await _reloadLayerAfterImport(
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

    await context.read<FeatureCubit>().ensureLayerLoaded(layer, force: true);
    await context.read<FeatureCubit>().ensureLayerFieldNames(
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

    await context.read<FeatureCubit>().ensureLayerLoaded(
      layer,
      force: true,
    );

    await context.read<FeatureCubit>().ensureLayerFieldNames(
      layer,
      force: false,
    );

    if (!mounted) return;

    await _openFirestoreTableDialog(
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
    required CatalogData catalogItem,
    required Offset localOffset,
  }) {
    final catalogId = catalogItem.id ?? '';
    final type = ComponentTypeMapper.fromCatalogItemId(catalogId);
    if (type == null) {
      throw Exception('Tipo não implementado: $catalogId');
    }

    return WorkspaceData(
      id: 'workspace_item_${_workspaceCounter++}',
      title: catalogItem.title ?? type.defaultTitle,
      type: type,
      offset: localOffset,
      size: type.defaultSize,
      properties: type.defaultProperties,
    );
  }

  void _handleWorkspaceCatalogDrop(
      CatalogData item,
      Offset localOffset,
      ) {
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
  }

  void _handleWorkspaceItemChanged(
      String itemId,
      Offset newOffset,
      Size newSize,
      ) {
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
      CatalogData property,
      ) {
    final index = _workspaceItems.indexWhere((e) => e.id == itemId);
    if (index < 0) return;

    final current = _workspaceItems[index];
    final propertyKey = property.key;
    if (propertyKey == null || propertyKey.isEmpty) return;

    final updated = current.copyWithUpdatedProperty(propertyKey, property);

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
      AttributeData data,
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
            fieldValues: data.fieldValues,
          ),
        );
      }

      if (property.key == 'source') {
        final currentBinding = property.bindingValue;
        final currentSourceId = currentBinding?.sourceId?.trim() ?? '';
        final newSourceId = data.sourceId?.trim() ?? '';

        if (newSourceId.isNotEmpty &&
            (currentSourceId.isEmpty || currentSourceId != newSourceId)) {
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

    final sourceId = data.sourceId?.trim() ?? '';
    if (sourceId.isEmpty) return;

    final layersCubit = context.read<LayerCubit>();
    final featureCubit = context.read<FeatureCubit>();

    final layer = layersCubit.findNodeById(sourceId, tree: currentTree);
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

  List<DockPanelData> _composeWorkspaceDockGroups({
    required MapState editorState,
    required FeatureState genericState,
  }) {
    final existing = editorState.panelGroups
        .where((group) => group.id == _workspaceGroupId)
        .toList(growable: false);

    final base = existing.isNotEmpty
        ? existing.first
        : const DockPanelData(
      id: _workspaceGroupId,
      title: 'Área de trabalho',
      area: DockArea.bottom,
      crossSpan: DockCrossSpan.full,
      visible: true,
      dockExtent: 260,
      dockWeight: 1.0,
      icon: Icons.space_dashboard_outlined,
      shrinkWrapOnMainAxis: false,
      items: [
        DockPanelData(
          id: 'workspace_area_main',
          title: 'Área de trabalho',
          icon: Icons.space_dashboard_outlined,
          contentPadding: EdgeInsets.zero,
          child: SizedBox.shrink(),
        ),
      ],
      activeItemId: 'workspace_area_main',
    );

    final workspaceToken = _workspaceItemsToken();

    return [
      base.copyWith(
        shrinkWrapOnMainAxis: false,
        items: [
          DockPanelData(
            id: 'workspace_area_main',
            title: 'Área de trabalho',
            icon: Icons.space_dashboard_outlined,
            contentToken: 'workspace_area_main_$workspaceToken',
            contentPadding: EdgeInsets.zero,
            child: RepaintBoundary(
              child: WorkspacePanel(
                key: ValueKey('workspace_panel_$workspaceToken'),
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
                onSelectedWorkspaceItemChanged: _handleWorkspaceItemSelected,
              ),
            ),
          ),
        ],
        activeItemId: 'workspace_area_main',
      ),
    ];
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required bool active,
    required VoidCallback onTap,
  }) {
    return BackCircleButton(
      icon: icon,
      tooltip: tooltip,
      radius: 19,
      outlined: true,
      onPressed: onTap,
      backgroundColor:
      active ? Colors.white : Colors.grey.withValues(alpha: 0.1),
      iconColor: active ? const Color(0xFF3F3F46) : Colors.grey,
      borderColor: active ? Colors.white : Colors.grey,
    );
  }

  List<Widget> _buildAppBarActions(MapState editorState) {
    final workspaceVisible = _isWorkspaceVisible(editorState);

    return [
      _buildActionButton(
        icon: Icons.space_dashboard_outlined,
        tooltip: workspaceVisible
            ? 'Ocultar Área de trabalho'
            : 'Mostrar Área de trabalho',
        active: workspaceVisible,
        onTap: () => _toggleWorkspaceVisibility(context),
      ),
      _buildActionButton(
        icon: Icons.handyman_outlined,
        tooltip: 'Ferramentas',
        active: _isPushPanelOpen(_panelFerramentasId),
        onTap: () => _togglePushPanel(_panelFerramentasId),
      ),
      _buildActionButton(
        icon: Icons.dashboard_customize_outlined,
        tooltip: 'Catálogo',
        active: _isPushPanelOpen(_panelVisualizacoesId),
        onTap: () => _togglePushPanel(_panelVisualizacoesId),
      ),
      _buildActionButton(
        icon: Icons.info_outline,
        tooltip: 'Atributos',
        active: _isPushPanelOpen(_panelAtributosId),
        onTap: () => _togglePushPanel(_panelAtributosId),
      ),
    ];
  }

  bool _isContextDrawerOpen() {
    return _scaffoldKey.currentState?.isDrawerOpen ?? false;
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
          listenWhen: (p, c) =>
          p.error != c.error || p.selected != c.selected,
          listener: (context, state) {
            if (state.error != null && state.error!.trim().isNotEmpty) {
              _showSnack(context, state.error!);
            }

            if (state.selected != null) {
              context
                  .read<MapCubit>()
                  .selectLayerPanelItem(state.selected!.layerId);
              _openPushPanel(_panelAtributosId);
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

          return Scaffold(
            key: _scaffoldKey,
            drawer: LayerDrawer(
              mapData: mapData,
              editorState: editorState,
              onSelectedChanged: (id) {
                context.read<FeatureCubit>().clearSelection();
                context.read<MapCubit>().selectLayerPanelItem(id);
              },
              onToggleLayer: (id, active) => context.read<MapCubit>().toggleLayer(
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
              onRenameSelected: (id) => _editSelectedItem(id, mapData.currentTree),
              onRemoveSelected: (id) =>
                  context.read<MapCubit>().removeSelectedItem(
                    id,
                    mapData.currentTree,
                  ),
              onConnectLayer: (id) => _handleConnectLayer(id, mapData.currentTree),
              onOpenTable: (id) => _openLayerTable(context, id, mapData.currentTree),
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
                      panels: [
                        const PushPanelData(
                          id: _panelFerramentasId,
                          title: 'Ferramentas',
                          icon: Icons.handyman_outlined,
                        ),
                        const PushPanelData(
                          id: _panelVisualizacoesId,
                          title: 'Catálogo',
                          icon: Icons.dashboard_customize_outlined,
                        ),
                        const PushPanelData(
                          id: _panelAtributosId,
                          title: 'Atributos',
                          icon: Icons.info_outline,
                        ),
                      ].map((panel) {
                        if (panel.id == _panelFerramentasId) {
                          return panel.copyWith(
                            child: GeoFerramentasPanel(
                              mapData: mapData,
                              editorState: editorState,
                              measurementState: measurementState,
                              onShowMessage: (message) =>
                                  _showSnack(context, message),
                            ),
                          );
                        }

                        if (panel.id == _panelVisualizacoesId) {
                          return panel.copyWith(
                            child: CatalogPanel(
                              selectedCatalogItemId: _selectedCatalogItemId,
                              selectedWorkspaceItem: _selectedWorkspaceItem,
                              workspaceItemsToken: _workspaceItemsToken(),
                              selectedWorkspaceToken:
                              _selectedWorkspaceItemToken(),
                              onCatalogItemTap: (item) {
                                final itemId = item.id;
                                if (_selectedCatalogItemId != itemId) {
                                  setState(() {
                                    _selectedCatalogItemId = itemId;
                                  });
                                }

                                _showSnack(
                                  context,
                                  'Arraste "${item.title ?? ''}" para a área de trabalho',
                                );
                              },
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
                      }).toList(),
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