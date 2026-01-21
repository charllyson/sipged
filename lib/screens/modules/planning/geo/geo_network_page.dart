import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:siged/screens/modules/planning/geo/layer/layer_db_status_cubit.dart';

import 'package:siged/_blocs/modules/planning/geo/transportes/roads_federal/roads_federal_cubit.dart';
import 'package:siged/_blocs/modules/planning/geo/transportes/roads_federal/roads_federal_repository.dart';
import 'package:siged/_blocs/modules/planning/geo/transportes/roads_federal/roads_federal_state.dart';

import 'package:siged/_widgets/geo/attributes_table/attributes_table_dialog.dart';

// SIGMINE
import 'package:siged/_blocs/modules/planning/geo/sig_miner/sigmine_cubit.dart';
import 'package:siged/_blocs/modules/planning/geo/sig_miner/sigmine_state.dart';
import 'package:siged/_blocs/modules/planning/geo/sig_miner/sigmine_repository.dart';

// IBGE
import 'package:siged/_blocs/modules/planning/geo/ibge_location/ibge_localidade_cubit.dart';
import 'package:siged/_blocs/modules/planning/geo/ibge_location/ibge_localidade_state.dart';

// SETUP
import 'package:siged/_blocs/system/setup/setup_data.dart';

// UI
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/geo/layer/layers_drawer.dart';
import 'package:siged/_widgets/menu/upBar/up_bar.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/layout/split_layout/split_layout.dart';
import 'package:siged/_widgets/overlays/screen_lock.dart';

// Layers & Map
import 'package:siged/screens/modules/planning/geo/layer/layers_geo.dart';
import 'package:siged/screens/modules/planning/geo/geo_map.dart';
import 'package:siged/screens/modules/planning/geo/layer/layers_controller.dart';
import 'package:siged/screens/modules/planning/geo/geo_right_pane.dart';

// Import vetorial
import 'package:siged/_blocs/modules/planning/geo/attributes_table/attributes_table_cubit.dart';

// ✅ Railways repo (hasData)
import 'package:siged/_blocs/modules/planning/geo/transportes/railways/railways_repository.dart';

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

        // ✅ Provider do status de DB (para pintar correntinha)
        BlocProvider(
          create: (_) => LayerDbStatusCubit(
            roadsFederalHasData: (uf) => RoadsFederalRepository().hasData(uf: uf),
            railwaysHasData: (uf) => RailwaysRepository().hasData(uf: uf),
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

  // UF atual
  late String _currentUF;

  // Controle “carregou ao menos 1x”
  final Set<String> _loadedOnce = <String>{};

  @override
  void initState() {
    super.initState();
    _currentUF = widget.initialUf;

    // ✅ Inicia só com o mapa base (sem SIGMINE / IBGE / etc.)
    _layersController = LayersController({'base_normal'});
  }

  Set<String> get _activeLayerIds => _layersController.activeLayerIds;

  bool get _isSigMineVisible => _layersController.isSigMineVisible;
  bool get _isIbgeVisible => _layersController.isIbgeVisible;

  bool get _isFederalRoadVisible =>
      _layersController.activeLayerIds.contains('federal_road');

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

  // ===========================================================================
  // VIEW FIRESTORE (tabela QGIS-like usando MESMO dialog)
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
          targetFields: const [], // não usado no modo firestore (mantido compat)
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
              final bounds =
              SigMineRepository.boundsFromFeatures(state.features);
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
                SnackBar(content: Text('Rodovias Federais: ${state.errorMessage}')),
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

          // ✅ status do banco para o Drawer
          final hasDbByLayer =
              context.watch<LayerDbStatusCubit>().state.hasDbByLayer;

          final derived =
          sigCubit.buildDerived(sigmineAtivo: _isSigMineVisible);
          Color getColor(String s) => sigCubit.getColorForMinerio(s);

          final federalOn = _isFederalRoadVisible;

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
              if (!federalOn) return;
              context
                  .read<RoadsFederalCubit>()
                  .onZoomChanged(uf: _currentUF, zoom: zoom);
            },
            onRequestDetails: sigCubit.openDetailsByFeature,
            onRequestDetailsByProcess: sigCubit.openDetailsByProcess,
            showSigmine: _isSigMineVisible,
            roadPolylines: federalOn ? roadsFederalState.polylines : const [],
            showRoads: federalOn,
            ufs: SetupData.ufs,
            selectedUF: _currentUF,
            loading: (sigState.isLoading && _isSigMineVisible) ||
                (ibgeState.isLoading && _isIbgeVisible) ||
                (roadsFederalState.isLoading && federalOn),
            onChangeUF: (uf) {
              setState(() => _currentUF = uf);

              // ✅ atualiza status do DB (correntinha)
              context.read<LayerDbStatusCubit>().refreshAll(uf: uf);

              // SIGMINE
              if (_loadedOnce.contains('sigmine') || _isSigMineVisible) {
                context.read<SigMineCubit>().loadUF(uf);
              }

              // IBGE
              if (_loadedOnce.contains('ibge_cities') || _isIbgeVisible) {
                ibgeCubit.changeSelectedStateBySigla(uf);
              }

              // Rodovias Federais
              final federalOnNow =
              _layersController.activeLayerIds.contains('federal_road');
              if (_loadedOnce.contains('federal_road') || federalOnNow) {
                final zoom = _controller?.camera.zoom ?? 8.5;
                final bucket = RoadsFederalCubit.bucketForZoom(zoom);
                context.read<RoadsFederalCubit>().loadByUF(uf, bucket: bucket);
              }
            },
            ibgeCityPolygons: ibgeState.cityPolygons,
            showIbgeCities: _isIbgeVisible,
            onMunicipioTap: (id) => _handleMunicipioTap(context, id),
            selectedBaseIndex: _selectedBaseIndex,
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
              (roadsFederalState.isLoading && federalOn);

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
              layers: kEnvironmentLayers,
              activeLayerIds: _activeLayerIds,
              onToggleLayer: _toggleLayer,
              hasDbByLayer: hasDbByLayer,

              onConnectLayer: (id) async {
                final hasDb = hasDbByLayer[id] == true;

                // Map layer -> coleção
                final collectionByLayer = <String, String>{
                  'federal_road': 'geo/transportes/rodovias_federais',
                  'railways': 'geo/transportes/ferrovias',
                };

                final path = collectionByLayer[id];
                if (path == null) return;

                if (hasDb) {
                  // ✅ NOVO: abre o MESMO dialog em modo Firestore
                  await _openFirestoreTable(
                    collectionPath: path,
                    title: 'Tabela de atributos',
                  );
                  return;
                }

                // ❌ sem dados -> abre import
                if (id == 'federal_road') {
                  await _openImportForFederalRoads();

                  // atualiza correntinha
                  context.read<LayerDbStatusCubit>().refreshAll(uf: _currentUF);

                  // se layer está ligada, recarrega desenho
                  final federalOnNow =
                  _layersController.activeLayerIds.contains('federal_road');
                  if (federalOnNow) {
                    _loadedOnce.add('federal_road');
                    final zoom = _controller?.camera.zoom ?? 8.5;
                    final bucket = RoadsFederalCubit.bucketForZoom(zoom);
                    context
                        .read<RoadsFederalCubit>()
                        .loadByUF(_currentUF, bucket: bucket);
                  }
                }

                if (id == 'railways') {
                  await _openImportForRailways();
                  context.read<LayerDbStatusCubit>().refreshAll(uf: _currentUF);
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
                    left: map,
                    right: rightPane,
                    showRightPanel: sigState.showPanel || _isIbgeVisible,
                    breakpoint: 1300,
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
