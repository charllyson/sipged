import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:sipged/_blocs/modules/planning/geo/attributes_table/attributes_table_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/natural_resources/sig_miner/sigmine_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/natural_resources/sig_miner/sigmine_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/natural_resources/sig_miner/sigmine_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/productive_units/energy_plants/energy_plants_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/productive_units/energy_plants/energy_plants_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/productive_units/energy_plants/energy_plants_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/territorial_boundaries/ibge_location/ibge_localidade_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/territorial_boundaries/ibge_location/ibge_localidade_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/railways/railways_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/railways/railways_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/railways/railways_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_estadual/roads_state_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_estadual/roads_state_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_estadual/roads_state_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_federal/roads_federal_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_federal/roads_federal_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_federal/roads_federal_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_municipal/roads_municipal_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_municipal/roads_municipal_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_municipal/roads_municipal_state.dart';
import 'package:sipged/_blocs/system/setup/setup_data.dart';
import 'package:sipged/_widgets/background/background_cleaner.dart';
import 'package:sipged/_widgets/buttons/back_circle_button.dart';
import 'package:sipged/_widgets/geo/layer/layer_registry.dart';
import 'package:sipged/_widgets/geo/layer/layers_drawer.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';
import 'package:sipged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';
import 'package:sipged/screens/modules/planning/geo/geo_map.dart';
import 'package:sipged/screens/modules/planning/geo/geo_network_layer_actions.dart';
import 'package:sipged/screens/modules/planning/geo/geo_network_tree_controller.dart';
import 'package:sipged/screens/modules/planning/geo/geo_right_pane.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layer_db_status_cubit.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layers_controller.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layers_geo.dart';

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
            resolvers: {
              'federal_road': (uf) => RoadsFederalRepository().hasData(uf: uf),
              'state_road': (uf) => RoadsStateRepository().hasData(uf: uf),
              'municipal_road': (uf) =>
                  RoadsMunicipalRepository().hasData(uf: uf),
              'railways': (uf) => RailwaysRepository().hasData(uf: uf),
              'units_energy': (uf) =>
                  EnergyPlantsRepository().hasData(uf: uf),
            },
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

  late final LayersController _layersController;
  late final GeoNetworkTreeController _treeController;
  late String _currentUF;

  final Set<String> _loadedOnce = <String>{};

  @override
  void initState() {
    super.initState();
    _currentUF = widget.initialUf;
    _layersController = LayersController({'base_normal'});
    _treeController = GeoNetworkTreeController(initialTree: kEnvironmentLayers);
  }

  Set<String> get _activeLayerIds => _layersController.activeLayerIds;
  List<LayersGeo> get _layersTree => _treeController.layersTree;

  bool get _isSigMineVisible => _layersController.isSigMineVisible;
  bool get _isIbgeVisible => _layersController.isIbgeVisible;
  bool get _isFederalRoadVisible =>
      _layersController.activeLayerIds.contains('federal_road');
  bool get _isStateRoadVisible =>
      _layersController.activeLayerIds.contains('state_road');
  bool get _isMunicipalRoadVisible =>
      _layersController.activeLayerIds.contains('municipal_road');
  bool get _isRailwaysVisible =>
      _layersController.activeLayerIds.contains('railways');
  bool get _isUnitsEnergyVisible =>
      _layersController.activeLayerIds.contains('units_energy');

  int? get _selectedBaseIndex {
    final baseId = _layersController.activeBaseLayerId;
    if (baseId == 'base_normal') return 0;
    if (baseId == 'base_satellite') return 1;
    return null;
  }

  void _moveLayerUp(String id) {
    setState(() {
      _treeController.moveLayerUp(id);
    });
  }

  void _moveLayerDown(String id) {
    setState(() {
      _treeController.moveLayerDown(id);
    });
  }

  void _createGroupFromSelected(String selectedId) {
    setState(() {
      _treeController.createGroupFromSelected(selectedId);
    });
  }

  void _dropItem(String draggedId, String? targetParentId, int targetIndex) {
    setState(() {
      _treeController.dropItem(draggedId, targetParentId, targetIndex);
    });
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

  Future<void> _renameSelectedItem(String id) async {
    final node = _treeController.findNodeById(_layersTree, id);
    if (node == null) return;

    final newName = await _askNewLayerName(
      context: context,
      currentName: node.title,
    );

    if (!mounted || newName == null || newName.trim().isEmpty) return;

    setState(() {
      _treeController.renameNodeById(_layersTree, id, newName.trim());
    });
  }

  Future<void> _handleConnectLayer(String rawId) async {
    final zoom = _controller?.camera.zoom ?? 8.5;

    await GeoNetworkLayerActions.handleConnectLayer(
      context,
      rawId: rawId,
      currentUF: _currentUF,
      zoom: zoom,
      layersController: _layersController,
      loadedOnce: _loadedOnce,
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SigMineCubit, SigMineState>(
          listenWhen: (p, c) =>
          p.errorMessage != c.errorMessage || p.features != c.features,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }

            if (_controller != null &&
                _isSigMineVisible &&
                state.features.isNotEmpty) {
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
          listenWhen: (p, c) =>
          p.errorMessage != c.errorMessage ||
              p.polylines.length != c.polylines.length,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Rodovias Federais: ${state.errorMessage}'),
                ),
              );
            }
          },
        ),
        BlocListener<RoadsStateCubit, RoadsStateState>(
          listenWhen: (p, c) =>
          p.errorMessage != c.errorMessage ||
              p.polylines.length != c.polylines.length,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Rodovias Estaduais: ${state.errorMessage}'),
                ),
              );
            }
          },
        ),
        BlocListener<RoadsMunicipalCubit, RoadsMunicipalState>(
          listenWhen: (p, c) =>
          p.errorMessage != c.errorMessage ||
              p.polylines.length != c.polylines.length,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Rodovias Municipais: ${state.errorMessage}'),
                ),
              );
            }
          },
        ),
        BlocListener<RailwaysCubit, RailwaysState>(
          listenWhen: (p, c) =>
          p.errorMessage != c.errorMessage ||
              p.polylines.length != c.polylines.length,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ferrovias: ${state.errorMessage}')),
              );
            }
          },
        ),
        BlocListener<EnergyPlantsCubit, EnergyPlantsState>(
          listenWhen: (p, c) =>
          p.errorMessage != c.errorMessage ||
              p.markers.length != c.markers.length,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Usinas de Energia: ${state.errorMessage}'),
                ),
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
          final hasDbByLayer =
              context.watch<LayerDbStatusCubit>().state.hasDbByLayer;

          final derived = sigCubit.buildDerived(sigmineAtivo: _isSigMineVisible);
          Color getColor(String s) => sigCubit.getColorForMinerio(s);

          final federalOn = _isFederalRoadVisible;
          final stateOn = _isStateRoadVisible;
          final municipalOn = _isMunicipalRoadVisible;
          final railwaysOn = _isRailwaysVisible;
          final energyOn = _isUnitsEnergyVisible;

          final orderedLeafIdsTopToBottom = _treeController
              .flattenOrderedLeafIds(_layersTree)
              .where((id) => _layersController.activeLayerIds.contains(id))
              .toList();

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
                if (municipalOn) {
                  combinedRoads.addAll(roadsMunicipalState.polylines);
                }
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
                context.read<RoadsFederalCubit>().onZoomChanged(
                  uf: _currentUF,
                  zoom: zoom,
                );
              }
              if (stateOn) {
                context.read<RoadsStateCubit>().onZoomChanged(
                  uf: _currentUF,
                  zoom: zoom,
                );
              }
              if (municipalOn) {
                context.read<RoadsMunicipalCubit>().onZoomChanged(
                  uf: _currentUF,
                  zoom: zoom,
                );
              }
              if (railwaysOn) {
                context.read<RailwaysCubit>().onZoomChanged(
                  uf: _currentUF,
                  zoom: zoom,
                );
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

              final federalOnNow =
              _layersController.activeLayerIds.contains('federal_road');
              if (_loadedOnce.contains('federal_road') || federalOnNow) {
                final bucket = RoadsFederalCubit.bucketForZoom(zoom);
                context.read<RoadsFederalCubit>().loadByUF(uf, bucket: bucket);
              }

              final stateOnNow =
              _layersController.activeLayerIds.contains('state_road');
              if (_loadedOnce.contains('state_road') || stateOnNow) {
                final bucket = RoadsStateCubit.bucketForZoom(zoom);
                context.read<RoadsStateCubit>().loadByUF(uf, bucket: bucket);
              }

              final municipalOnNow =
              _layersController.activeLayerIds.contains('municipal_road');
              if (_loadedOnce.contains('municipal_road') || municipalOnNow) {
                final bucket = RoadsMunicipalCubit.bucketForZoom(zoom);
                context.read<RoadsMunicipalCubit>().loadByUF(uf, bucket: bucket);
              }

              final railwaysOnNow =
              _layersController.activeLayerIds.contains('railways');
              if (_loadedOnce.contains('railways') || railwaysOnNow) {
                final bucket = RailwaysCubit.bucketForZoom(zoom);
                context.read<RailwaysCubit>().loadByUF(
                  uf,
                  zoom: zoom,
                  bucket: bucket,
                );
              }

              final energyOnNow =
              _layersController.activeLayerIds.contains('units_energy');
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
              supportsConnect: LayerRegistry.supportsConnect,
              onMoveUp: _moveLayerUp,
              onMoveDown: _moveLayerDown,
              onCreateGroup: _createGroupFromSelected,
              onDropItem: _dropItem,
              onRenameSelected: _renameSelectedItem,
              onConnectLayer: _handleConnectLayer,
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