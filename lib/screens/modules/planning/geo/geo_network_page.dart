import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:sipged/_blocs/modules/planning/geo/attributes_table/attributes_table_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/generic/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/generic/geo_feature_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/generic/geo_feature_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/generic/geo_feature_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_state.dart';
import 'package:sipged/_widgets/background/background_cleaner.dart';
import 'package:sipged/_widgets/buttons/back_circle_button.dart';
import 'package:sipged/_widgets/geo/properties/dialog/layer_properties_dialog.dart';
import 'package:sipged/_widgets/geo/layers_drawer.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/catalogs/colors_catalog.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/catalogs/marker_icons_catalog.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';
import 'package:sipged/screens/modules/planning/geo/geo_network_layer.dart';
import 'package:sipged/screens/modules/planning/geo/geo_network_map.dart';
import 'package:sipged/screens/modules/planning/geo/geo_network_controller.dart';
import 'package:sipged/_blocs/modules/planning/geo/db/layer_db_status_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/db/layer_db_controller.dart';

class GeoNetworkPage extends StatelessWidget {
  const GeoNetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final geoLayersRepository = GeoLayersRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AttributesTableCubit()),
        BlocProvider(
          create: (_) => GeoLayersCubit(
            repository: geoLayersRepository,
          )..load(),
        ),
        BlocProvider(
          create: (_) => LayerDbStatusCubit(
            repository: geoLayersRepository,
          ),
        ),
        BlocProvider(
          create: (_) => GeoFeatureCubit(
            repository: GeoFeatureRepository(),
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  MapController? controller;

  late final LayerDbController _layersController;

  @override
  void initState() {
    super.initState();
    _layersController = LayerDbController();
  }

  Set<String> get _activeLayerIds => _layersController.activeLayerIds;

  void _toggleLayer(
      String id,
      bool isActiveFromUI,
      List<GeoLayersData> currentTree,
      ) {
    setState(() {
      _layersController.toggleLayer(id, isActiveFromUI);
    });

    final treeController = GeoNetworkController(initialTree: currentTree);
    final layer = treeController.findNodeById(currentTree, id);

    if (layer == null || layer.isGroup) return;

    if (isActiveFromUI) {
      context.read<GeoFeatureCubit>().ensureLayerLoaded(layer);
    } else {
      context.read<GeoFeatureCubit>().unloadLayer(id);
    }
  }

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

  Future<void> _persistTree(List<GeoLayersData> tree) async {
    await context.read<GeoLayersCubit>().saveTree(tree);
  }

  Future<void> _editSelectedItem(
      String id,
      List<GeoLayersData> currentTree,
      ) async {
    final treeController = GeoNetworkController(initialTree: currentTree);
    final node = treeController.findNodeById(currentTree, id);
    if (node == null) return;

    final edited = await _askEditLayerData(
      context: context,
      current: node,
    );

    if (!mounted || edited == null) return;
    if (edited.title.trim().isEmpty) return;

    treeController.updateNodeById(
      treeController.layersTree,
      id,
          (_) => edited,
    );

    await _persistTree(treeController.layersTree);
    setState(() {});
  }

  Future<void> _createLayer(List<GeoLayersData> currentTree) async {
    final treeController = GeoNetworkController(initialTree: currentTree);
    treeController.addNewLayer();
    await _persistTree(treeController.layersTree);
  }

  Future<void> _createEmptyGroup(List<GeoLayersData> currentTree) async {
    final treeController = GeoNetworkController(initialTree: currentTree);
    treeController.createEmptyGroup();
    await _persistTree(treeController.layersTree);
  }

  Future<void> _moveLayerUp(String id, List<GeoLayersData> currentTree) async {
    final treeController = GeoNetworkController(initialTree: currentTree);
    final ok = treeController.moveLayerUp(id);
    if (!ok) return;
    await _persistTree(treeController.layersTree);
  }

  Future<void> _moveLayerDown(
      String id,
      List<GeoLayersData> currentTree,
      ) async {
    final treeController = GeoNetworkController(initialTree: currentTree);
    final ok = treeController.moveLayerDown(id);
    if (!ok) return;
    await _persistTree(treeController.layersTree);
  }

  Future<void> _dropItem(
      String draggedId,
      String? targetParentId,
      int targetIndex,
      List<GeoLayersData> currentTree,
      ) async {
    final treeController = GeoNetworkController(initialTree: currentTree);
    final ok = treeController.dropItem(draggedId, targetParentId, targetIndex);
    if (!ok) return;
    await _persistTree(treeController.layersTree);
  }

  Future<void> _removeSelectedItem(
      String id,
      List<GeoLayersData> currentTree,
      ) async {
    final treeController = GeoNetworkController(initialTree: currentTree);
    final node = treeController.findNodeById(currentTree, id);
    if (node == null || node.isSystem) return;

    final ok = treeController.removeNodeById(id);
    if (!ok) return;

    _layersController.removeLayer(id);

    final existingIds = treeController
        .flattenAllNodes(treeController.layersTree)
        .map((e) => e.id)
        .toSet();

    _layersController.syncWithExistingTreeIds(existingIds);

    context.read<GeoFeatureCubit>().unloadLayer(id);

    await _persistTree(treeController.layersTree);
    setState(() {});
  }

  Future<void> _handleConnectLayer(
      String rawId,
      List<GeoLayersData> currentTree,
      ) async {
    final treeController = GeoNetworkController(initialTree: currentTree);
    final layer = treeController.findNodeById(currentTree, rawId);
    if (layer == null) return;

    final isAlreadyActive = _layersController.activeLayerIds.contains(layer.id);

    await GeoNetworkLayer.handleConnectLayer(
      context,
      layer: layer,
      shouldLoadOnMap: isAlreadyActive,
    );

    if (!mounted) return;

    final refreshedTree = context.read<GeoLayersCubit>().state.tree;
    await context.read<LayerDbStatusCubit>().refreshAll(refreshedTree);

    final hasDbNow =
        context.read<LayerDbStatusCubit>().state.hasDbByLayer[layer.id] == true;

    if (!hasDbNow) {
      setState(() {});
      return;
    }

    if (!_layersController.activeLayerIds.contains(layer.id)) {
      setState(() {
        _layersController.toggleLayer(layer.id, true);
      });
    }

    await context.read<GeoFeatureCubit>().ensureLayerLoaded(
      layer,
      force: true,
    );

    setState(() {});
  }

  Widget _buildRightPane(
      BuildContext context, {
        required GeoFeatureState genericState,
        required Map<String, GeoLayersData> layersById,
      }) {
    final selection = genericState.selected;

    if (selection == null) {
      return const Center(
        child: Text(
          'Selecione uma feição no mapa para visualizar os atributos.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final layer = layersById[selection.layerId];
    final feature = selection.feature;

    final entries = feature.properties.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: (layer?.color ?? Colors.blue).withValues(alpha: 0.10),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    layer?.title ?? 'Camada',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    feature.title,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tipo geométrico: ${feature.geometryType.name}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                child: Text('Esta feição não possui atributos.'),
              )
                  : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final e = entries[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      e.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      e.value == null ? '' : e.value.toString(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GeoLayersCubit, GeoLayersState>(
          listenWhen: (p, c) =>
          p.error != c.error || p.tree != c.tree || p.loaded != c.loaded,
          listener: (context, state) async {
            if (state.error != null && state.error!.trim().isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!)),
              );
            }

            if (state.loaded) {
              final ids = GeoNetworkController(initialTree: state.tree)
                  .flattenAllNodes(state.tree)
                  .map((e) => e.id)
                  .toSet();

              _layersController.syncWithExistingTreeIds(ids);
              await context.read<LayerDbStatusCubit>().refreshAll(state.tree);

              if (mounted) {
                setState(() {});
              }
            }
          },
        ),
        BlocListener<GeoFeatureCubit, GeoFeatureState>(
          listenWhen: (p, c) => p.error != c.error,
          listener: (context, state) {
            if (state.error != null && state.error!.trim().isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!)),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<GeoLayersCubit, GeoLayersState>(
        builder: (context, layersState) {
          final currentTree = layersState.tree;
          final treeController =
          GeoNetworkController(initialTree: currentTree);

          return BlocBuilder<GeoFeatureCubit, GeoFeatureState>(
            builder: (context, genericState) {
              final hasDbByLayer =
                  context.watch<LayerDbStatusCubit>().state.hasDbByLayer;

              final allNodes = treeController.flattenAllNodes(currentTree);
              final layersById = <String, GeoLayersData>{
                for (final e in allNodes.where((e) => !e.isGroup)) e.id: e,
              };

              final orderedLeafIdsTopToBottom = treeController
                  .flattenOrderedLeafIds(currentTree)
                  .where((id) => _layersController.activeLayerIds.contains(id))
                  .toList();

              final orderedForMap = orderedLeafIdsTopToBottom.reversed.toList();

              final visibleFeatures = <GeoFeatureData>[];
              for (final layerId in orderedForMap) {
                visibleFeatures.addAll(
                  genericState.featuresByLayer[layerId] ??
                      const <GeoFeatureData>[],
                );
              }

              final map = GeoNetworkMap(
                features: visibleFeatures,
                layersById: layersById,
                orderedActiveLayerIds: orderedForMap,
                selectedFeatureKey: genericState.selected?.feature.selectionKey,
                loading: genericState.isAnyLoading || layersState.isSaving,
                onControllerReady: (c) => controller = c,
                onCameraChanged: (_, _) {},
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
              );

              final isLoading =
                  genericState.isAnyLoading || layersState.isSaving;

              return Scaffold(
                key: _scaffoldKey,
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(70),
                  child: UpBar(
                    leading: const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: BackCircleButton(),
                    ),
                    actions: [
                      BackCircleButton(
                        tooltip: 'Camadas do mapa',
                        icon: Icons.layers_outlined,
                        onPressed: () =>
                            _scaffoldKey.currentState?.openEndDrawer(),
                      ),
                    ],
                  ),
                ),
                endDrawer: LayersDrawer(
                  layers: currentTree,
                  activeLayerIds: _activeLayerIds,
                  onToggleLayer: (id, active) =>
                      _toggleLayer(id, active, currentTree),
                  hasDbByLayer: hasDbByLayer,
                  supportsConnect: (layer) =>
                  layer.supportsConnect && !layer.isGroup,
                  onMoveUp: (id) => _moveLayerUp(id, currentTree),
                  onMoveDown: (id) => _moveLayerDown(id, currentTree),
                  onCreateEmptyGroup: () => _createEmptyGroup(currentTree),
                  onCreateLayer: () => _createLayer(currentTree),
                  onDropItem: (draggedId, targetParentId, targetIndex) =>
                      _dropItem(
                        draggedId,
                        targetParentId,
                        targetIndex,
                        currentTree,
                      ),
                  onRenameSelected: (id) => _editSelectedItem(id, currentTree),
                  onRemoveSelected: (id) =>
                      _removeSelectedItem(id, currentTree),
                  onConnectLayer: (id) => _handleConnectLayer(id, currentTree),
                ),
                body: ScreenLock(
                  locked: isLoading,
                  message: 'Carregando dados do mapa',
                  icon: Icons.map_outlined,
                  child: Stack(
                    children: [
                      const BackgroundClean(),
                      SplitLayout(
                        rightPanelWidth: 460,
                        left: map,
                        right: _buildRightPane(
                          context,
                          genericState: genericState,
                          layersById: layersById,
                        ),
                        showRightPanel: genericState.selected != null,
                        showDividers: true,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}