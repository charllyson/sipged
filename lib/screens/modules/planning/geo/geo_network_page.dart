import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';

import 'package:sipged/screens/modules/planning/geo/layer/layer_db_status_cubit.dart';

import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_federal/roads_federal_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_federal/roads_federal_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_federal/roads_federal_state.dart';

import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_estadual/roads_state_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_estadual/roads_state_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_estadual/roads_state_state.dart';

import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_municipal/roads_municipal_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_municipal/roads_municipal_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_municipal/roads_municipal_state.dart';

import 'package:sipged/_blocs/modules/planning/geo/transportes/railways/railways_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/railways/railways_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/railways/railways_state.dart';

import 'package:sipged/_widgets/geo/attributes_table/attributes_table_dialog.dart';

import 'package:sipged/_blocs/modules/planning/geo/natural_resources/sig_miner/sigmine_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/natural_resources/sig_miner/sigmine_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/natural_resources/sig_miner/sigmine_repository.dart';

import 'package:sipged/_blocs/modules/planning/geo/territorial_boundaries/ibge_location/ibge_localidade_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/territorial_boundaries/ibge_location/ibge_localidade_state.dart';

import 'package:sipged/_blocs/modules/planning/geo/productive_units/energy_plants/energy_plants_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/productive_units/energy_plants/energy_plants_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/productive_units/energy_plants/energy_plants_state.dart';

import 'package:sipged/_blocs/system/setup/setup_data.dart';

import 'package:sipged/_widgets/background/background_cleaner.dart';
import 'package:sipged/_widgets/geo/layer/layers_drawer.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/buttons/back_circle_button.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';

import 'package:sipged/screens/modules/planning/geo/layer/layers_geo.dart';
import 'package:sipged/screens/modules/planning/geo/geo_map.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layers_controller.dart';
import 'package:sipged/screens/modules/planning/geo/geo_right_pane.dart';

import 'package:sipged/_blocs/modules/planning/geo/attributes_table/attributes_table_cubit.dart';

import 'package:sipged/_widgets/map/polylines/tappable_changed_polyline.dart';

class GeoNetworkPage extends StatelessWidget {
  const GeoNetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ufInicial = SetupData.selectedUF ?? 'AL';

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SigMineCubit(
            repository: SigMineRepository(),
            initialUF: ufInicial,
          ),
        ),
        BlocProvider(create: (_) => IBGELocationCubit()),
        BlocProvider(create: (_) => AttributesTableCubit()),
        BlocProvider(
          create: (_) => RoadsFederalCubit(
            repository: RoadsFederalRepository(),
          ),
        ),
        BlocProvider(
          create: (_) => RoadsStateCubit(
            repository: RoadsStateRepository(),
          ),
        ),
        BlocProvider(
          create: (_) => RoadsMunicipalCubit(
            repository: RoadsMunicipalRepository(),
          ),
        ),
        BlocProvider(
          create: (_) => RailwaysCubit(
            repository: RailwaysRepository(),
          ),
        ),
        BlocProvider(
          create: (_) => EnergyPlantsCubit(
            repository: EnergyPlantsRepository(),
          ),
        ),
        BlocProvider(
          create: (_) => LayerDbStatusCubit(
            roadsFederalHasData: (uf) => RoadsFederalRepository().hasData(uf: uf),
            roadsStateHasData: (uf) => RoadsStateRepository().hasData(uf: uf),
            roadsMunicipalHasData: (uf) => RoadsMunicipalRepository().hasData(uf: uf),
            railwaysHasData: (uf) => RailwaysRepository().hasData(uf: uf),
            energyPlantsHasData: (uf) => EnergyPlantsRepository().hasData(uf: uf),
          )..refreshAll(uf: ufInicial),
        ),
      ],
      child: _PlanningNetworkView(initialUf: ufInicial),
    );
  }
}

class _PlanningNetworkView extends StatefulWidget {
  const _PlanningNetworkView({required this.initialUf});
  final String initialUf;

  @override
  State<_PlanningNetworkView> createState() => _PlanningNetworkViewState();
}

class _PlanningNetworkViewState extends State<_PlanningNetworkView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  MapController? _controller;

  late LayersController _layersController;
  late String _currentUF;
  late List<LayersGeo> _layersTree;

  final Set<String> _loadedOnce = <String>{};
  int _groupSequence = 1;

  @override
  void initState() {
    super.initState();
    _currentUF = widget.initialUf;
    _layersController = LayersController({'base_normal'});
    _layersTree = _cloneLayersTree(kEnvironmentLayers);
  }

  List<LayersGeo> _cloneLayersTree(List<LayersGeo> source) {
    return source.map((item) {
      return LayersGeo(
        id: item.id,
        title: item.title,
        icon: item.icon,
        color: item.color,
        defaultVisible: item.defaultVisible,
        isGroup: item.isGroup,
        children: _cloneLayersTree(item.children),
      );
    }).toList();
  }

  List<int>? _findPathById(List<LayersGeo> nodes, String id, [List<int> current = const []]) {
    for (int i = 0; i < nodes.length; i++) {
      final path = [...current, i];
      final node = nodes[i];

      if (node.id == id) return path;

      if (node.isGroup && node.children.isNotEmpty) {
        final found = _findPathById(node.children, id, path);
        if (found != null) return found;
      }
    }
    return null;
  }

  LayersGeo? _getNodeByPath(List<int> path) {
    if (path.isEmpty) return null;

    List<LayersGeo> current = _layersTree;
    LayersGeo? node;

    for (int i = 0; i < path.length; i++) {
      final index = path[i];
      if (index < 0 || index >= current.length) return null;
      node = current[index];
      if (i < path.length - 1) {
        current = node.children;
      }
    }
    return node;
  }

  List<LayersGeo> _getListByParentPath(List<int> parentPath) {
    if (parentPath.isEmpty) return _layersTree;

    LayersGeo? node = _getNodeByPath(parentPath);
    if (node == null) return _layersTree;
    return node.children;
  }

  bool _pathStartsWith(List<int> full, List<int> prefix) {
    if (prefix.length > full.length) return false;
    for (int i = 0; i < prefix.length; i++) {
      if (full[i] != prefix[i]) return false;
    }
    return true;
  }

  void _moveLayerUp(String id) {
    final path = _findPathById(_layersTree, id);
    if (path == null || path.isEmpty) return;

    final parentPath = path.sublist(0, path.length - 1);
    final currentIndex = path.last;
    final list = _getListByParentPath(parentPath);
    final newIndex = currentIndex - 1;

    if (newIndex < 0 || newIndex >= list.length) return;

    setState(() {
      final item = list.removeAt(currentIndex);
      list.insert(newIndex, item);
    });
  }

  void _moveLayerDown(String id) {
    final path = _findPathById(_layersTree, id);
    if (path == null || path.isEmpty) return;

    final parentPath = path.sublist(0, path.length - 1);
    final currentIndex = path.last;
    final list = _getListByParentPath(parentPath);
    final newIndex = currentIndex + 1;

    if (newIndex < 0 || newIndex >= list.length) return;

    setState(() {
      final item = list.removeAt(currentIndex);
      list.insert(newIndex, item);
    });
  }

  void _createGroupFromSelected(String selectedId) {
    final path = _findPathById(_layersTree, selectedId);
    if (path == null || path.isEmpty) return;

    final parentPath = path.sublist(0, path.length - 1);
    final index = path.last;
    final list = _getListByParentPath(parentPath);

    if (index < 0 || index >= list.length) return;

    setState(() {
      final selectedNode = list.removeAt(index);

      final newGroup = LayersGeo(
        id: 'custom_group_${DateTime.now().microsecondsSinceEpoch}',
        title: 'NOVO GRUPO ${_groupSequence++}',
        icon: Icons.folder_open_outlined,
        color: const Color(0xFF374151),
        defaultVisible: false,
        isGroup: true,
        children: [selectedNode],
      );

      list.insert(index, newGroup);
    });
  }

  void _dropItem(String draggedId, String? targetParentId, int targetIndex) {
    final draggedPath = _findPathById(_layersTree, draggedId);
    if (draggedPath == null || draggedPath.isEmpty) return;

    final oldParentPath = draggedPath.sublist(0, draggedPath.length - 1);
    final oldParentNode =
    oldParentPath.isEmpty ? null : _getNodeByPath(oldParentPath);
    final oldParentId = oldParentNode?.id;
    final oldIndex = draggedPath.last;

    if (targetParentId == draggedId) return;

    if (targetParentId != null) {
      final targetParentPathBeforeRemoval = _findPathById(_layersTree, targetParentId);
      if (targetParentPathBeforeRemoval != null &&
          _pathStartsWith(targetParentPathBeforeRemoval, draggedPath)) {
        return;
      }
    }

    setState(() {
      final sourceList = _getListByParentPath(oldParentPath);
      if (oldIndex < 0 || oldIndex >= sourceList.length) return;

      final draggedNode = sourceList.removeAt(oldIndex);

      List<LayersGeo> targetList;
      if (targetParentId == null) {
        targetList = _layersTree;
      } else {
        final targetParentPathAfterRemoval = _findPathById(_layersTree, targetParentId);
        if (targetParentPathAfterRemoval == null) {
          sourceList.insert(oldIndex, draggedNode);
          return;
        }
        final targetParentNode = _getNodeByPath(targetParentPathAfterRemoval);
        if (targetParentNode == null) {
          sourceList.insert(oldIndex, draggedNode);
          return;
        }
        targetList = targetParentNode.children;
      }

      var adjustedIndex = targetIndex;
      if (oldParentId == targetParentId && oldIndex < adjustedIndex) {
        adjustedIndex -= 1;
      }

      if (adjustedIndex < 0) adjustedIndex = 0;
      if (adjustedIndex > targetList.length) adjustedIndex = targetList.length;

      targetList.insert(adjustedIndex, draggedNode);
    });
  }

  List<String> _flattenOrderedLeafIds(List<LayersGeo> nodes) {
    final out = <String>[];

    void walk(List<LayersGeo> list) {
      for (final item in list) {
        if (item.isGroup) {
          walk(item.children);
        } else {
          out.add(item.id);
        }
      }
    }

    walk(nodes);
    return out;
  }

  Set<String> get _activeLayerIds => _layersController.activeLayerIds;

  bool get _isSigMineVisible => _layersController.isSigMineVisible;
  bool get _isIbgeVisible => _layersController.isIbgeVisible;

  bool get _isFederalRoadVisible => _layersController.activeLayerIds.contains('federal_road');
  bool get _isStateRoadVisible => _layersController.activeLayerIds.contains('state_road');
  bool get _isMunicipalRoadVisible => _layersController.activeLayerIds.contains('municipal_road');
  bool get _isRailwaysVisible => _layersController.activeLayerIds.contains('railways');
  bool get _isUnitsEnergyVisible => _layersController.activeLayerIds.contains('units_energy');

  int? get _selectedBaseIndex {
    final baseId = _layersController.activeBaseLayerId;
    if (baseId == 'base_normal') return 0;
    if (baseId == 'base_satellite') return 1;
    return null;
  }

  void _handleLayerToggleLoad(String id, bool isActiveNow) {
    if (!isActiveNow) return;

    if (id == 'sigmine' && !_loadedOnce.contains('sigmine')) {
      _loadedOnce.add('sigmine');
      context.read<SigMineCubit>().loadUF(_currentUF);
      return;
    }

    if (id == 'ibge_cities' && !_loadedOnce.contains('ibge_cities')) {
      _loadedOnce.add('ibge_cities');
      context.read<IBGELocationCubit>().loadInitialAuto(ufSiglaHint: _currentUF);
      return;
    }

    if (id == 'federal_road' && !_loadedOnce.contains('federal_road')) {
      _loadedOnce.add('federal_road');

      final zoom = _controller?.camera.zoom ?? 8.5;
      final bucket = RoadsFederalCubit.bucketForZoom(zoom);

      context.read<RoadsFederalCubit>().loadByUF(_currentUF, bucket: bucket);
      return;
    }

    if (id == 'state_road' && !_loadedOnce.contains('state_road')) {
      _loadedOnce.add('state_road');

      final zoom = _controller?.camera.zoom ?? 8.5;
      final bucket = RoadsStateCubit.bucketForZoom(zoom);

      context.read<RoadsStateCubit>().loadByUF(_currentUF, bucket: bucket);
      return;
    }

    if (id == 'municipal_road' && !_loadedOnce.contains('municipal_road')) {
      _loadedOnce.add('municipal_road');

      final zoom = _controller?.camera.zoom ?? 8.5;
      final bucket = RoadsMunicipalCubit.bucketForZoom(zoom);

      context.read<RoadsMunicipalCubit>().loadByUF(_currentUF, bucket: bucket);
      return;
    }

    if (id == 'railways' && !_loadedOnce.contains('railways')) {
      _loadedOnce.add('railways');

      final zoom = _controller?.camera.zoom ?? 8.5;
      final bucket = RailwaysCubit.bucketForZoom(zoom);

      context.read<RailwaysCubit>().loadByUF(
        _currentUF,
        zoom: zoom,
        bucket: bucket,
      );
      return;
    }

    if (id == 'units_energy' && !_loadedOnce.contains('units_energy')) {
      _loadedOnce.add('units_energy');
      context.read<EnergyPlantsCubit>().loadByUF(_currentUF);
      return;
    }
  }

  void _toggleLayer(String id, bool isActiveFromUI) {
    setState(() {
      _layersController.toggleLayer(id, isActiveFromUI);
      final nowActive = _layersController.activeLayerIds.contains(id);
      _handleLayerToggleLoad(id, nowActive);
    });
  }

  void _handleMunicipioTap(BuildContext context, String idIbge) {
    context.read<IBGELocationCubit>().openMunicipioDetailsById(idIbge);
  }

  void _handleDeselection() {
    context.read<SigMineCubit>().closeDetails();
    context.read<IBGELocationCubit>().closeMunicipioDetails();
  }

  Future<void> _openImportForRailways() async {
    const collectionPath = 'geo/transportes/ferrovias';
    const targetFields = ['uf', 'name', 'code', 'owner', 'points'];

    final importCubit = context.read<AttributesTableCubit>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: importCubit,
        child: const AttributesTableDialog(
          mode: AttributesTableMode.importFile,
          collectionPath: collectionPath,
          targetFields: targetFields,
          title: 'Importar Ferrovias',
          description: 'Importe GeoJSON / KML / KMZ para cadastro de ferrovias.',
        ),
      ),
    );
  }

  Future<void> _openImportForFederalRoads() async {
    const collectionPath = 'geo/transportes/rodovias_federais';
    const targetFields = ['uf', 'name', 'code', 'owner', 'points'];

    final importCubit = context.read<AttributesTableCubit>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: importCubit,
        child: const AttributesTableDialog(
          mode: AttributesTableMode.importFile,
          collectionPath: collectionPath,
          targetFields: targetFields,
          title: 'Importar Rodovias Federais',
          description: 'Importe GeoJSON / KML / KMZ contendo rodovias federais (linhas).',
        ),
      ),
    );
  }

  Future<void> _openImportForStateRoads() async {
    const collectionPath = 'geo/transportes/rodovias_estaduais';
    const targetFields = ['uf', 'name', 'code', 'owner', 'points'];

    final importCubit = context.read<AttributesTableCubit>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: importCubit,
        child: const AttributesTableDialog(
          mode: AttributesTableMode.importFile,
          collectionPath: collectionPath,
          targetFields: targetFields,
          title: 'Importar Rodovias Estaduais',
          description: 'Importe GeoJSON / KML / KMZ contendo rodovias estaduais (linhas).',
        ),
      ),
    );
  }

  Future<void> _openImportForMunicipalRoads() async {
    const collectionPath = 'geo/transportes/rodovias_municipais';
    const targetFields = ['uf', 'name', 'code', 'owner', 'points'];

    final importCubit = context.read<AttributesTableCubit>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: importCubit,
        child: const AttributesTableDialog(
          mode: AttributesTableMode.importFile,
          collectionPath: collectionPath,
          targetFields: targetFields,
          title: 'Importar Rodovias Municipais',
          description: 'Importe GeoJSON / KML / KMZ contendo rodovias municipais (linhas).',
        ),
      ),
    );
  }

  Future<void> _openImportForUnitsEnergy() async {
    const collectionPath = 'geo/productive_units/usinas_de_energia';
    const targetFields = ['uf', 'name', 'code', 'owner', 'point'];

    final importCubit = context.read<AttributesTableCubit>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: importCubit,
        child: const AttributesTableDialog(
          mode: AttributesTableMode.importFile,
          collectionPath: collectionPath,
          targetFields: targetFields,
          title: 'Importar Usinas de Energia',
          description: 'Importe GeoJSON / KML / KMZ contendo pontos (usinas).',
        ),
      ),
    );
  }

  Future<void> _openImportForAirports() async {
    const collectionPath = 'geo/transportes/aeroportos';
    const targetFields = ['uf', 'name', 'code', 'owner', 'point'];

    final importCubit = context.read<AttributesTableCubit>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: importCubit,
        child: const AttributesTableDialog(
          mode: AttributesTableMode.importFile,
          collectionPath: collectionPath,
          targetFields: targetFields,
          title: 'Importar Aeroportos',
          description: 'Importe GeoJSON / KML / KMZ contendo pontos (aeroportos).',
        ),
      ),
    );
  }

  Future<void> _openFirestoreTable({
    required String collectionPath,
    String? title,
  }) async {
    final importCubit = context.read<AttributesTableCubit>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: importCubit,
        child: AttributesTableDialog(
          mode: AttributesTableMode.firestore,
          collectionPath: collectionPath,
          targetFields: const [],
          title: title ?? 'Tabela de atributos',
          description: 'Visualização Firestore: cada documento é uma linha. '
              'Você pode filtrar, selecionar e excluir documentos.',
        ),
      ),
    );
  }

  bool _renameNodeById(
      List<LayersGeo> nodes,
      String id,
      String newTitle,
      ) {
    for (int i = 0; i < nodes.length; i++) {
      final item = nodes[i];

      if (item.id == id) {
        nodes[i] = LayersGeo(
          id: item.id,
          title: newTitle,
          icon: item.icon,
          color: item.color,
          defaultVisible: item.defaultVisible,
          isGroup: item.isGroup,
          children: item.children,
        );
        return true;
      }

      if (item.isGroup && item.children.isNotEmpty) {
        final renamed = _renameNodeById(item.children, id, newTitle);
        if (renamed) return true;
      }
    }

    return false;
  }

  Future<String?> _askNewLayerName({
    required BuildContext context,
    required String currentName,
  }) async {
    final controller = TextEditingController(text: currentName);

    return showWindowDialog<String>(
      context: context,
      title: 'Renomear item',
      width: 480,
      barrierDismissible: true,
      usePointerInterceptor: true,
      child: Builder(
        builder: (dialogCtx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: controller,
                  labelText: 'Novo nome',
                  onSubmitted: (value) {
                    Navigator.of(dialogCtx).pop(value.trim());
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(dialogCtx).pop(controller.text.trim());
                      },
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  LayersGeo? _findNodeById(List<LayersGeo> nodes, String id) {
    for (final item in nodes) {
      if (item.id == id) return item;

      if (item.isGroup && item.children.isNotEmpty) {
        final found = _findNodeById(item.children, id);
        if (found != null) return found;
      }
    }
    return null;
  }

  Future<void> _renameSelectedItem(String id) async {
    final node = _findNodeById(_layersTree, id);
    if (node == null) return;

    final newName = await _askNewLayerName(
      context: context,
      currentName: node.title,
    );

    if (!mounted) return;
    if (newName == null) return;
    if (newName.trim().isEmpty) return;

    setState(() {
      _renameNodeById(_layersTree, id, newName.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SigMineCubit, SigMineState>(
          listenWhen: (p, c) => p.errorMessage != c.errorMessage || p.features != c.features,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }

            if (_controller != null && _isSigMineVisible && state.features.isNotEmpty) {
              final bounds = SigMineRepository.boundsFromFeatures(state.features);
              _controller!.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(18),
                ),
              );
            }
          },
        ),
        BlocListener<IBGELocationCubit, IBGELocationState>(
          listenWhen: (p, c) => p.errorMessage != c.errorMessage,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
          },
        ),
        BlocListener<RoadsFederalCubit, RoadsFederalState>(
          listenWhen: (p, c) => p.errorMessage != c.errorMessage || p.polylines.length != c.polylines.length,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Rodovias Federais: ${state.errorMessage}')),
              );
            }
          },
        ),
        BlocListener<RoadsStateCubit, RoadsStateState>(
          listenWhen: (p, c) => p.errorMessage != c.errorMessage || p.polylines.length != c.polylines.length,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Rodovias Estaduais: ${state.errorMessage}')),
              );
            }
          },
        ),
        BlocListener<RoadsMunicipalCubit, RoadsMunicipalState>(
          listenWhen: (p, c) => p.errorMessage != c.errorMessage || p.polylines.length != c.polylines.length,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Rodovias Municipais: ${state.errorMessage}')),
              );
            }
          },
        ),
        BlocListener<RailwaysCubit, RailwaysState>(
          listenWhen: (p, c) => p.errorMessage != c.errorMessage || p.polylines.length != c.polylines.length,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ferrovias: ${state.errorMessage}')),
              );
            }
          },
        ),
        BlocListener<EnergyPlantsCubit, EnergyPlantsState>(
          listenWhen: (p, c) => p.errorMessage != c.errorMessage || p.markers.length != c.markers.length,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Usinas de Energia: ${state.errorMessage}')),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<SigMineCubit, SigMineState>(
        builder: (context, sigState) {
          final sigCubit = context.read<SigMineCubit>();
          final ibgeCubit = context.read<IBGELocationCubit>();

          final ibgeState = context.watch<IBGELocationCubit>().state;

          final roadsFederalState = context.watch<RoadsFederalCubit>().state;
          final roadsStateState = context.watch<RoadsStateCubit>().state;
          final roadsMunicipalState = context.watch<RoadsMunicipalCubit>().state;
          final railwaysState = context.watch<RailwaysCubit>().state;
          final energyState = context.watch<EnergyPlantsCubit>().state;

          final hasDbByLayer = context.watch<LayerDbStatusCubit>().state.hasDbByLayer;

          final derived = sigCubit.buildDerived(sigmineAtivo: _isSigMineVisible);
          Color getColor(String s) => sigCubit.getColorForMinerio(s);

          final federalOn = _isFederalRoadVisible;
          final stateOn = _isStateRoadVisible;
          final municipalOn = _isMunicipalRoadVisible;
          final railwaysOn = _isRailwaysVisible;
          final energyOn = _isUnitsEnergyVisible;

          final orderedLeafIdsTopToBottom = _flattenOrderedLeafIds(_layersTree)
              .where((id) => _layersController.activeLayerIds.contains(id))
              .toList();

          /// topo do drawer deve ficar por cima no mapa
          final orderedForMap = orderedLeafIdsTopToBottom.reversed.toList();

          final combinedRoads = <TappableChangedPolyline>[];
          for (final id in orderedForMap) {
            switch (id) {
              case 'federal_road':
                if (federalOn) combinedRoads.addAll(roadsFederalState.polylines);
                break;
              case 'state_road':
                if (stateOn) combinedRoads.addAll(roadsStateState.polylines);
                break;
              case 'municipal_road':
                if (municipalOn) combinedRoads.addAll(roadsMunicipalState.polylines);
                break;
              case 'railways':
                if (railwaysOn) combinedRoads.addAll(railwaysState.polylines);
                break;
            }
          }

          final map = GeoMap(
            featuresAtivos: derived.visibleFeatures,
            mineriosAtivos: sigState.mineriosAtivos,
            getColorForMinerio: getColor,
            onRegionTap: (processo) {
              if (processo == null) return _handleDeselection();
              sigCubit.openDetailsByProcess(processo);
            },
            onControllerReady: (c) => _controller = c,
            onCameraChanged: (_, zoom) {
              if (federalOn) {
                context.read<RoadsFederalCubit>().onZoomChanged(uf: _currentUF, zoom: zoom);
              }
              if (stateOn) {
                context.read<RoadsStateCubit>().onZoomChanged(uf: _currentUF, zoom: zoom);
              }
              if (municipalOn) {
                context.read<RoadsMunicipalCubit>().onZoomChanged(uf: _currentUF, zoom: zoom);
              }
              if (railwaysOn) {
                context.read<RailwaysCubit>().onZoomChanged(uf: _currentUF, zoom: zoom);
              }
            },
            onRequestDetails: sigCubit.openDetailsByFeature,
            onRequestDetailsByProcess: sigCubit.openDetailsByProcess,
            showSigmine: _isSigMineVisible,
            roadPolylines: combinedRoads,
            showRoads: federalOn || stateOn || municipalOn || railwaysOn,
            ufs: SetupData.ufs,
            selectedUF: _currentUF,
            loading: (sigState.isLoading && _isSigMineVisible) ||
                (ibgeState.isLoading && _isIbgeVisible) ||
                (roadsFederalState.isLoading && federalOn) ||
                (roadsStateState.isLoading && stateOn) ||
                (roadsMunicipalState.isLoading && municipalOn) ||
                (railwaysState.isLoading && railwaysOn) ||
                (energyState.isLoading && energyOn),
            onChangeUF: (uf) {
              setState(() => _currentUF = uf);

              context.read<LayerDbStatusCubit>().refreshAll(uf: uf);

              if (_loadedOnce.contains('sigmine') || _isSigMineVisible) {
                context.read<SigMineCubit>().loadUF(uf);
              }

              if (_loadedOnce.contains('ibge_cities') || _isIbgeVisible) {
                ibgeCubit.changeSelectedStateBySigla(uf);
              }

              final zoom = _controller?.camera.zoom ?? 8.5;

              final federalOnNow = _layersController.activeLayerIds.contains('federal_road');
              if (_loadedOnce.contains('federal_road') || federalOnNow) {
                final bucket = RoadsFederalCubit.bucketForZoom(zoom);
                context.read<RoadsFederalCubit>().loadByUF(uf, bucket: bucket);
              }

              final stateOnNow = _layersController.activeLayerIds.contains('state_road');
              if (_loadedOnce.contains('state_road') || stateOnNow) {
                final bucket = RoadsStateCubit.bucketForZoom(zoom);
                context.read<RoadsStateCubit>().loadByUF(uf, bucket: bucket);
              }

              final municipalOnNow = _layersController.activeLayerIds.contains('municipal_road');
              if (_loadedOnce.contains('municipal_road') || municipalOnNow) {
                final bucket = RoadsMunicipalCubit.bucketForZoom(zoom);
                context.read<RoadsMunicipalCubit>().loadByUF(uf, bucket: bucket);
              }

              final railwaysOnNow = _layersController.activeLayerIds.contains('railways');
              if (_loadedOnce.contains('railways') || railwaysOnNow) {
                final bucket = RailwaysCubit.bucketForZoom(zoom);
                context.read<RailwaysCubit>().loadByUF(
                  uf,
                  zoom: zoom,
                  bucket: bucket,
                );
              }

              final energyOnNow = _layersController.activeLayerIds.contains('units_energy');
              if (_loadedOnce.contains('units_energy') || energyOnNow) {
                context.read<EnergyPlantsCubit>().loadByUF(uf);
              }
            },
            ibgeCityPolygons: ibgeState.cityPolygons,
            showIbgeCities: _isIbgeVisible,
            onMunicipioTap: (id) => _handleMunicipioTap(context, id),
            selectedBaseIndex: _selectedBaseIndex,
            showUnitsEnergy: energyOn,
            unitsEnergyMarkers: energyState.markers,
            onEnergyMarkerTap: (item) {},
            showPluviometria: false,
            orderedActiveLayerIds: orderedForMap,
          );

          final rightPane = GeoRightPane(
            sigmineState: sigState,
            ibgeState: ibgeState,
            derived: derived,
            showSigmine: _isSigMineVisible,
            showIbge: _isIbgeVisible,
            showWeather: false,
            getColorForMinerio: getColor,
          );

          final bool isLoading = (sigState.isLoading && _isSigMineVisible) ||
              (ibgeState.isLoading && _isIbgeVisible) ||
              (roadsFederalState.isLoading && federalOn) ||
              (roadsStateState.isLoading && stateOn) ||
              (roadsMunicipalState.isLoading && municipalOn) ||
              (railwaysState.isLoading && railwaysOn) ||
              (energyState.isLoading && energyOn);

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
                    onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                  ),
                ],
              ),
            ),
            endDrawer: LayersDrawer(
              layers: _layersTree,
              activeLayerIds: _activeLayerIds,
              onToggleLayer: _toggleLayer,
              hasDbByLayer: hasDbByLayer,
              onMoveUp: _moveLayerUp,
              onMoveDown: _moveLayerDown,
              onCreateGroup: _createGroupFromSelected,
              onDropItem: _dropItem,
              onRenameSelected: _renameSelectedItem,
              onConnectLayer: (rawId) async {
                final layerDbCubit = context.read<LayerDbStatusCubit>();
                final roadsFederalCubit = context.read<RoadsFederalCubit>();
                final roadsStateCubit = context.read<RoadsStateCubit>();
                final roadsMunicipalCubit = context.read<RoadsMunicipalCubit>();
                final railwaysCubit = context.read<RailwaysCubit>();
                final energyCubit = context.read<EnergyPlantsCubit>();

                String normalizeLayerId(String id) {
                  const aliases = <String, String>{
                    'energy_plants': 'units_energy',
                    'usinas_de_energia': 'units_energy',
                    'energyPlants': 'units_energy',
                    'energy_plant': 'units_energy',
                    'usinas_energia': 'units_energy',
                    'aeroportos': 'airport',
                    'airports': 'airport',
                  };
                  return aliases[id] ?? id;
                }

                final id = normalizeLayerId(rawId);
                final hasDbByLayer = layerDbCubit.state.hasDbByLayer;
                final hasDb = hasDbByLayer[id] == true;

                final collectionByLayer = <String, String>{
                  'federal_road': 'geo/transportes/rodovias_federais',
                  'state_road': 'geo/transportes/rodovias_estaduais',
                  'municipal_road': 'geo/transportes/rodovias_municipais',
                  'railways': 'geo/transportes/ferrovias',
                  'units_energy': 'geo/productive_units/usinas_de_energia',
                  'airport': 'geo/transportes/aeroportos',
                };

                final path = collectionByLayer[id];
                if (path == null) return;

                if (hasDb) {
                  await _openFirestoreTable(
                    collectionPath: path,
                    title: 'Tabela de atributos',
                  );
                  if (!mounted) return;
                  return;
                }

                if (id == 'federal_road') {
                  await _openImportForFederalRoads();
                  if (!mounted) return;

                  layerDbCubit.refreshAll(uf: _currentUF);

                  final onNow = _layersController.activeLayerIds.contains('federal_road');
                  if (onNow) {
                    _loadedOnce.add('federal_road');
                    final zoom = _controller?.camera.zoom ?? 8.5;
                    final bucket = RoadsFederalCubit.bucketForZoom(zoom);
                    roadsFederalCubit.loadByUF(_currentUF, bucket: bucket);
                  }
                  return;
                }

                if (id == 'state_road') {
                  await _openImportForStateRoads();
                  if (!mounted) return;

                  layerDbCubit.refreshAll(uf: _currentUF);

                  final onNow = _layersController.activeLayerIds.contains('state_road');
                  if (onNow) {
                    _loadedOnce.add('state_road');
                    final zoom = _controller?.camera.zoom ?? 8.5;
                    final bucket = RoadsStateCubit.bucketForZoom(zoom);
                    roadsStateCubit.loadByUF(_currentUF, bucket: bucket);
                  }
                  return;
                }

                if (id == 'municipal_road') {
                  await _openImportForMunicipalRoads();
                  if (!mounted) return;

                  layerDbCubit.refreshAll(uf: _currentUF);

                  final onNow = _layersController.activeLayerIds.contains('municipal_road');
                  if (onNow) {
                    _loadedOnce.add('municipal_road');
                    final zoom = _controller?.camera.zoom ?? 8.5;
                    final bucket = RoadsMunicipalCubit.bucketForZoom(zoom);
                    roadsMunicipalCubit.loadByUF(_currentUF, bucket: bucket);
                  }
                  return;
                }

                if (id == 'railways') {
                  await _openImportForRailways();
                  if (!mounted) return;

                  layerDbCubit.refreshAll(uf: _currentUF);

                  final onNow = _layersController.activeLayerIds.contains('railways');
                  if (onNow) {
                    _loadedOnce.add('railways');
                    final zoom = _controller?.camera.zoom ?? 8.5;
                    final bucket = RailwaysCubit.bucketForZoom(zoom);
                    railwaysCubit.loadByUF(
                      _currentUF,
                      zoom: zoom,
                      bucket: bucket,
                    );
                  }
                  return;
                }

                if (id == 'units_energy') {
                  await _openImportForUnitsEnergy();
                  if (!mounted) return;

                  layerDbCubit.refreshAll(uf: _currentUF);

                  final onNow = _layersController.activeLayerIds.contains('units_energy');
                  if (onNow) {
                    _loadedOnce.add('units_energy');
                    energyCubit.loadByUF(_currentUF);
                  }
                  return;
                }

                if (id == 'airport') {
                  await _openImportForAirports();
                  if (!mounted) return;
                  return;
                }
              },
            ),
            body: ScreenLock(
              locked: isLoading,
              message: 'Carregando dados do mapa',
              icon: Icons.map_outlined,
              child: Stack(
                children: [
                  const BackgroundClean(),
                  SplitLayout(
                    rightPanelWidth: 550,
                    left: map,
                    right: rightPane,
                    showRightPanel: sigState.showPanel || _isIbgeVisible,
                    showDividers: true,
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