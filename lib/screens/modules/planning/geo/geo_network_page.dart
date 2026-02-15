// lib/screens/modules/planning/geo/geo_network_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

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

// ✅ RAILWAYS
import 'package:sipged/_blocs/modules/planning/geo/transportes/railways/railways_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/railways/railways_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/railways/railways_state.dart';

import 'package:sipged/_widgets/geo/attributes_table/attributes_table_dialog.dart';

// SIGMINE
import 'package:sipged/_blocs/modules/planning/geo/sig_miner/sigmine_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/sig_miner/sigmine_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/sig_miner/sigmine_repository.dart';

// IBGE
import 'package:sipged/_blocs/modules/planning/geo/ibge_location/ibge_localidade_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/ibge_location/ibge_localidade_state.dart';

// ✅ ENERGY PLANTS
import 'package:sipged/_blocs/modules/planning/geo/unidades_produtivas/energy_plants/energy_plants_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/unidades_produtivas/energy_plants/energy_plants_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/unidades_produtivas/energy_plants/energy_plants_state.dart';

// SETUP
import 'package:sipged/_blocs/system/setup/setup_data.dart';

// UI
import 'package:sipged/_widgets/background/background_cleaner.dart';
import 'package:sipged/_widgets/geo/layer/layers_drawer.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/buttons/back_circle_button.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';

// Layers & Map
import 'package:sipged/screens/modules/planning/geo/layer/layers_geo.dart';
import 'package:sipged/screens/modules/planning/geo/geo_map.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layers_controller.dart';
import 'package:sipged/screens/modules/planning/geo/geo_right_pane.dart';

// Import vetorial
import 'package:sipged/_blocs/modules/planning/geo/attributes_table/attributes_table_cubit.dart';

// ✅ Polyline type
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

        // ✅ USINAS DE ENERGIA
        BlocProvider(
          create: (_) => EnergyPlantsCubit(
            repository: EnergyPlantsRepository(),
          ),
        ),

        // ✅ Provider do status de DB (ícone no drawer)
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

// =============================================================================
// VIEW
// =============================================================================

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

  final Set<String> _loadedOnce = <String>{};

  @override
  void initState() {
    super.initState();
    _currentUF = widget.initialUf;

    // ✅ Inicia só com o mapa base
    _layersController = LayersController({'base_normal'});
  }

  Set<String> get _activeLayerIds => _layersController.activeLayerIds;

  bool get _isSigMineVisible => _layersController.isSigMineVisible;
  bool get _isIbgeVisible => _layersController.isIbgeVisible;

  bool get _isFederalRoadVisible => _layersController.activeLayerIds.contains('federal_road');
  bool get _isStateRoadVisible => _layersController.activeLayerIds.contains('state_road');
  bool get _isMunicipalRoadVisible => _layersController.activeLayerIds.contains('municipal_road');
  bool get _isRailwaysVisible => _layersController.activeLayerIds.contains('railways');

  // ✅ ENERGY PLANTS (ID REAL DO LAYER)
  bool get _isUnitsEnergyVisible => _layersController.activeLayerIds.contains('units_energy');

  int? get _selectedBaseIndex {
    final baseId = _layersController.activeBaseLayerId;
    if (baseId == 'base_normal') return 0;
    if (baseId == 'base_satellite') return 1;
    return null;
  }

  // ===========================================================================
  // LAZY LOAD (primeira vez)
  // ===========================================================================

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

    // ✅ ENERGY PLANTS (markers) - usando ID REAL: units_energy
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

  // ===========================================================================
  // EVENTS
  // ===========================================================================

  void _handleMunicipioTap(BuildContext context, String idIbge) {
    context.read<IBGELocationCubit>().openMunicipioDetailsById(idIbge);
  }

  void _handleDeselection() {
    context.read<SigMineCubit>().closeDetails();
    context.read<IBGELocationCubit>().closeMunicipioDetails();
  }

  // ===========================================================================
  // IMPORTAÇÃO (arquivo)
  // ===========================================================================

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
        child: AttributesTableDialog(
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
        child: AttributesTableDialog(
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
        child: AttributesTableDialog(
          mode: AttributesTableMode.importFile,
          collectionPath: collectionPath,
          targetFields: targetFields,
          title: 'Importar Rodovias Municipais',
          description: 'Importe GeoJSON / KML / KMZ contendo rodovias municipais (linhas).',
        ),
      ),
    );
  }

  // ✅ ENERGY PLANTS import (mesmo repository/cubit, mas path por layer)
  Future<void> _openImportForUnitsEnergy() async {
    const collectionPath = 'geo/unidades_produtivas/usinas_de_energia';
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

  // ✅ AIRPORT import (generic)
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

  // ===========================================================================
  // VIEW FIRESTORE
  // ===========================================================================
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

  // ===========================================================================
  // BUILD
  // ===========================================================================
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

        // ✅ ENERGY PLANTS listener
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

          // ✅ status do banco para o Drawer
          final hasDbByLayer = context.watch<LayerDbStatusCubit>().state.hasDbByLayer;

          final derived = sigCubit.buildDerived(sigmineAtivo: _isSigMineVisible);
          Color getColor(String s) => sigCubit.getColorForMinerio(s);

          final federalOn = _isFederalRoadVisible;
          final stateOn = _isStateRoadVisible;
          final municipalOn = _isMunicipalRoadVisible;
          final railwaysOn = _isRailwaysVisible;
          final energyOn = _isUnitsEnergyVisible;

          final List<TappableChangedPolyline> combinedRoads = <TappableChangedPolyline>[
            if (federalOn) ...roadsFederalState.polylines,
            if (stateOn) ...roadsStateState.polylines,
            if (municipalOn) ...roadsMunicipalState.polylines,
            if (railwaysOn) ...railwaysState.polylines,
          ];

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
              if (federalOn) context.read<RoadsFederalCubit>().onZoomChanged(uf: _currentUF, zoom: zoom);
              if (stateOn) context.read<RoadsStateCubit>().onZoomChanged(uf: _currentUF, zoom: zoom);
              if (municipalOn) context.read<RoadsMunicipalCubit>().onZoomChanged(uf: _currentUF, zoom: zoom);
              if (railwaysOn) context.read<RailwaysCubit>().onZoomChanged(uf: _currentUF, zoom: zoom);
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

            // ✅ AQUI ESTÁ A PARTE QUE FALTAVA
            showUnitsEnergy: energyOn,
            unitsEnergyMarkers: energyState.markers,
            onEnergyMarkerTap: (item) {
            },

            showPluviometria: false,
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
              layers: kEnvironmentLayers,
              activeLayerIds: _activeLayerIds,
              onToggleLayer: _toggleLayer,
              hasDbByLayer: hasDbByLayer,
              onConnectLayer: (rawId) async {
                // ✅ Capturas antes de qualquer await
                final layerDbCubit = context.read<LayerDbStatusCubit>();
                final roadsFederalCubit = context.read<RoadsFederalCubit>();
                final roadsStateCubit = context.read<RoadsStateCubit>();
                final roadsMunicipalCubit = context.read<RoadsMunicipalCubit>();
                final railwaysCubit = context.read<RailwaysCubit>();
                final energyCubit = context.read<EnergyPlantsCubit>();

                // -----------------------------------------------------------------------
                // ✅ 1) Normaliza o ID (mantém compatibilidade com possíveis aliases)
                // -----------------------------------------------------------------------
                String normalizeLayerId(String id) {
                  const aliases = <String, String>{
                    // Energy
                    'energy_plants': 'units_energy',
                    'usinas_de_energia': 'units_energy',
                    'energyPlants': 'units_energy',
                    'energy_plant': 'units_energy',
                    'usinas_energia': 'units_energy',

                    // Airport (se algum dia vier com outro id)
                    'aeroportos': 'airport',
                    'airports': 'airport',
                  };
                  return aliases[id] ?? id;
                }

                final id = normalizeLayerId(rawId);

                // -----------------------------------------------------------------------
                // ✅ 2) hasDb consultado com ID normalizado (usa snapshot do state atual)
                // -----------------------------------------------------------------------
                final hasDbByLayer = layerDbCubit.state.hasDbByLayer;
                final hasDb = hasDbByLayer[id] == true;

                // -----------------------------------------------------------------------
                // ✅ 3) Mapa de paths
                // -----------------------------------------------------------------------
                final collectionByLayer = <String, String>{
                  'federal_road': 'geo/transportes/rodovias_federais',
                  'state_road': 'geo/transportes/rodovias_estaduais',
                  'municipal_road': 'geo/transportes/rodovias_municipais',
                  'railways': 'geo/transportes/ferrovias',
                  'units_energy': 'geo/unidades_produtivas/usinas_de_energia',
                  'airport': 'geo/transportes/aeroportos',
                };

                final path = collectionByLayer[id];
                if (path == null) return;

                // -----------------------------------------------------------------------
                // ✅ 4) Se tem dados → abre tabela Firestore
                // -----------------------------------------------------------------------
                if (hasDb) {
                  await _openFirestoreTable(
                    collectionPath: path,
                    title: 'Tabela de atributos',
                  );

                  if (!mounted) return;
                  return;
                }

                // -----------------------------------------------------------------------
                // ✅ 5) Sem dados → abre import por tipo
                // -----------------------------------------------------------------------
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
