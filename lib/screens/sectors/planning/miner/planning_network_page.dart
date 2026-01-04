// lib/screens/sectors/planning/miner/planning_network_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:siged/_services/geoJson/vector_preview_dialog.dart';

// 🔹 ANA – estações pluviométricas
import 'package:siged/_services/geography/ana_rain/ana_stations_cubit.dart';
import 'package:siged/_services/geography/ana_rain/ana_stations_state.dart';

// 🔹 SIGMINE
import 'package:siged/_services/geography/sig_miner/sigmine_cubit.dart';
import 'package:siged/_services/geography/sig_miner/sigmine_state.dart';
import 'package:siged/_services/geography/sig_miner/sigmine_repository.dart';

// 🔹 IBGE Localidades
import 'package:siged/_services/geography/ibge_location/ibge_localidade_cubit.dart';
import 'package:siged/_services/geography/ibge_location/ibge_localidade_state.dart';

// 🔹 SETUP / UF
import 'package:siged/_blocs/system/setup/setup_data.dart';

// 🔹 Básicos UI
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/map/base/map_base_layer.dart';

// 🔹 Drawer de Camadas
import 'package:siged/_widgets/menu/drawer/layers_drawer.dart';

// 🔹 Layers & Map
import 'package:siged/screens/sectors/planning/miner/planning_layers.dart';
import 'package:siged/screens/sectors/planning/miner/planning_map.dart';
import 'package:siged/screens/sectors/planning/miner/planning_layers_controller.dart';
import 'package:siged/screens/sectors/planning/miner/planning_right_pane.dart';

// 🔹 Pluviometria – painel com tabela ANA
import 'package:siged/screens/sectors/planning/miner/hidroweb/pluviometric_stations.dart';

// 🔹 Comuns
import 'package:siged/_widgets/menu/upBar/up_bar.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/layout/split_layout/split_layout.dart';

// 🔹 RODOVIAS OSM
import 'package:siged/_services/geography/osm_road/osm_roads_cubit.dart';
import 'package:siged/_services/geography/osm_road/osm_roads_state.dart';

// 🔹 Overlay de bloqueio
import 'package:siged/_widgets/overlays/screen_lock.dart';

// 🔹 Import vetorial genérico (GeoJSON / KML / KMZ -> Firestore)
import 'package:siged/_services/geoJson/vector_import_cubit.dart';

class PlanningNetworkPage extends StatelessWidget {
  const PlanningNetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ufInicial = SetupData.selectedUF ?? 'AL';

    return MultiBlocProvider(
      providers: [
        BlocProvider<SigMineCubit>(
          create: (_) => SigMineCubit(
            repository: SigMineRepository(),
            initialUF: ufInicial,
          )..warmup(),
        ),
        BlocProvider<IBGELocationCubit>(
          create: (_) =>
          IBGELocationCubit()..loadInitialAuto(ufSiglaHint: ufInicial),
        ),
        BlocProvider<OSMRoadsCubit>(
          create: (_) => OSMRoadsCubit()..loadByUF(ufInicial),
        ),
       // 🔹 ANA – estações pluviométricas já sincronizadas com UF inicial
        BlocProvider<AnaStationsCubit>(
          create: (_) => AnaStationsCubit(
            stationType: 'TELEMETRICA',
            initialUf: ufInicial,
          )..loadStations(),
        ),
        // 🔹 Import vetorial genérico (reutilizável para ferrovias, etc.)
        BlocProvider<VectorImportCubit>(
          create: (_) => VectorImportCubit(),
        ),
      ],
      child: const _PlanningNetworkView(),
    );
  }
}

// =============================================================================
// VIEW
// =============================================================================

class _PlanningNetworkView extends StatefulWidget {
  const _PlanningNetworkView({super.key});

  @override
  State<_PlanningNetworkView> createState() => _PlanningNetworkViewState();
}

class _PlanningNetworkViewState extends State<_PlanningNetworkView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  MapController? _controller;

  late PlanningLayersController _layersController;

  @override
  void initState() {
    super.initState();
    final initialIds = _collectDefaultVisibleLeafIds(kEnvironmentLayers);
    _layersController = PlanningLayersController(initialIds);
  }

  // =============================================================================
  // CAMADAS
  // =============================================================================

  Set<String> _collectDefaultVisibleLeafIds(List<PlanningLayers> layers) {
    final result = <String>{};

    void walk(List<PlanningLayers> list) {
      for (final l in list) {
        if (l.isGroup) {
          if (l.children.isNotEmpty) walk(l.children);
        } else if (l.defaultVisible) {
          result.add(l.id);
        }
      }
    }

    walk(layers);
    return result;
  }

  // Shortcuts
  Set<String> get _activeLayerIds => _layersController.activeLayerIds;

  bool get _isSigMineVisible => _layersController.isSigMineVisible;
  bool get _isIbgeVisible => _layersController.isIbgeVisible;
  bool get _isAnyRoadVisible => _layersController.isAnyRoadVisible;
  bool get _isWeatherVisible => _layersController.isWeatherVisible;
  bool get _isRainVisible => _layersController.isRainVisible;

  int? get _selectedBaseIndex {
    final semMapaIndex =
    MapBaseLayer.mapBase.indexWhere((e) => e.url.isEmpty);
    final baseId = _layersController.activeBaseLayerId;

    if (baseId == 'base_normal') return 0;
    if (baseId == 'base_satellite') return 1;
    if (baseId == null && semMapaIndex >= 0) return semMapaIndex;

    return null;
  }

  void _toggleLayer(String id, bool isActive) {
    final roadsCubit = context.read<OSMRoadsCubit>();

    setState(() {
      final rodoviaTipo = _layersController.toggleLayer(id, isActive);

      if (rodoviaTipo != null) {
        roadsCubit.updateFilter(rodoviaTipo);

        if (_controller != null) {
          final c = _controller!;
          roadsCubit.onViewportChanged(c.camera.center, c.camera.zoom);
        }
      }
    });
  }

  void _handleMunicipioTap(BuildContext context, String idIbge) {
    context.read<IBGELocationCubit>().openMunicipioDetailsById(idIbge);
  }

  void _handleDeselection() {
    context.read<SigMineCubit>().closeDetails();
    context.read<IBGELocationCubit>().closeMunicipioDetails();
  }

  // =============================================================================
  // IMPORT VETORIAL – FERROVIAS
  // =============================================================================

  Future<void> _openImportForRailways() async {
    // Aqui você escolhe a coleção onde as ferrovias serão salvas.
    // Pode trocar para o que fizer mais sentido: 'actives_railways', etc.
    const collectionPath = 'planning_railways';

    // Campos de destino "genéricos" para ferrovias.
    // O usuário vai mapear as colunas do arquivo (ex: NOME, UF, CODIGO) para isso.
    const targetFields = <String>[
      'uf',
      'name',
      'code',
      'owner',
      'points', // ⚠️ importante: é o campo padrão para a geometria
    ];

    final importCubit = context.read<VectorImportCubit>();

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: importCubit,
          child: const VectorPreviewDialog(
            collectionPath: collectionPath,
            targetFields: targetFields,
            title: 'Importar Ferrovias (GeoJSON / KML / KMZ)',
            description:
            'Selecione as colunas do arquivo (ou a geometria) para preencher os campos de ferrovias.\n'
                'Use o campo "points" para receber as coordenadas (lista de GeoPoint).',
          ),
        );
      },
    );

    // Depois do import, você pode disparar um Cubit próprio de ferrovias
    // para recarregar os dados e desenhá-los no mapa como polylines.
    //
    // Exemplo futuro:
    // context.read<RailwaysCubit>().loadFromFirestore();
  }

  // =============================================================================
  // BUILD
  // =============================================================================

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

            if (_controller != null && state.features.isNotEmpty) {
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
        BlocListener<OSMRoadsCubit, OSMRoadsState>(
          listenWhen: (p, c) => p.error != c.error,
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Rodovias: ${state.error}")),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<SigMineCubit, SigMineState>(
        builder: (context, sigState) {
          final sigCubit = context.read<SigMineCubit>();
          final ibgeState = context.watch<IBGELocationCubit>().state;
          final roadState = context.watch<OSMRoadsCubit>().state;

          final derived =
          sigCubit.buildDerived(sigmineAtivo: _isSigMineVisible);
          final visibleFeatures = derived.visibleFeatures;

          Color getColor(String s) => sigCubit.getColorForMinerio(s);

          // -------------------------------------------------------------------
          // MAPA INTERATIVO
          // -------------------------------------------------------------------
          final map = PlanningMap(
            featuresAtivos: visibleFeatures,
            mineriosAtivos: sigState.mineriosAtivos,
            getColorForMinerio: getColor,
            onRegionTap: (processo) {
              if (processo == null) return _handleDeselection();
              sigCubit.openDetailsByProcess(processo);
            },
            onControllerReady: (c) {
              _controller = c;

              c.mapEventStream.listen((event) {
                final center = c.camera.center;
                final zoom = c.camera.zoom;
                context
                    .read<OSMRoadsCubit>()
                    .onViewportChanged(center, zoom);
              });
            },
            // callback global de câmera (se precisar em outro lugar)
            onCameraChanged: (center, zoom) {
              // hoje quem usa viewport é apenas OSMRoadsCubit,
              // que já está ouvindo no onControllerReady acima.
            },

            onRequestDetails: sigCubit.openDetailsByFeature,
            onRequestDetailsByProcess: sigCubit.openDetailsByProcess,
            showSigmine: _isSigMineVisible,

            // UF – AGORA CONTROLA TUDO (SIGMINE, IBGE, OSM, CLIMA, ANA)
            ufs: SetupData.ufs,
            selectedUF: sigState.selectedUF,
            loading: sigState.isLoading || ibgeState.isLoading,
            onChangeUF: (uf) {
              // SIGMINE + MUNICÍPIOS
              sigCubit.loadUF(uf);
              context
                  .read<IBGELocationCubit>()
                  .changeSelectedStateBySigla(uf);

              // Rodovias OSM
              context.read<OSMRoadsCubit>().loadByUF(uf);

              // ANA – estações pluviométricas sincronizadas com o mesmo UF
              context.read<AnaStationsCubit>().changeUf(uf);

              if (_controller != null) {
                final c = _controller!;
                context
                    .read<OSMRoadsCubit>()
                    .onViewportChanged(c.camera.center, c.camera.zoom);
              }
            },

            // IBGE
            ibgeCityPolygons: ibgeState.cityPolygons,
            showIbgeCities: _isIbgeVisible,
            onMunicipioTap: (id) => _handleMunicipioTap(context, id),

            selectedBaseIndex: _selectedBaseIndex,

            // Rodovias
            roadPolylines: roadState.polylines,
            showRoads: _isAnyRoadVisible,

            // Pluviometria – (futuro) heatmap; por enquanto só visibilidade
            showPluviometria: _isRainVisible,
          );

          // -------------------------------------------------------------------
          // PAINEL DIREITO
          // -------------------------------------------------------------------
          Widget rightPane;

          if (_isRainVisible) {
            // 🔹 Quando a camada "Pluviometria" estiver ligada,
            //     o painel direito vira a tabela de estações ANA
            rightPane = const PluviometricStationsPanel();
          } else {
            // 🔹 Comportamento padrão (SIGMINE / IBGE / CLIMA)
            rightPane = PlanningRightPane(
              sigmineState: sigState,
              ibgeState: ibgeState,
              derived: derived,
              showSigmine: _isSigMineVisible,
              showIbge: _isIbgeVisible,
              showWeather: _isWeatherVisible,
              getColorForMinerio: getColor,
            );
          }

          // -------------------------------------------------------------------
          // ESTADO DE CARREGAMENTO
          // -------------------------------------------------------------------
          final bool isLoading = sigState.isLoading ||
              ibgeState.isLoading ||
              roadState.isLoading;

          final List<String> loadingParts = [];
          if (sigState.isLoading) loadingParts.add('Jazidas (SIGMINE)');
          if (ibgeState.isLoading) loadingParts.add('Municípios (IBGE)');
          if (roadState.isLoading) loadingParts.add('Rodovias (OSM)');

          final String loadingDescription = loadingParts.isEmpty
              ? 'Carregando dados do mapa...'
              : loadingParts.join(' • ');

          // -------------------------------------------------------------------
          // UI
          // -------------------------------------------------------------------
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
              onConnectLayer: (id) async {
                if (id == 'railways') {
                  await _openImportForRailways();
                }
                // Para outros ids, você pode no futuro abrir outros imports
                // ou telas específicas.
              },
            ),
            body: ScreenLock(
              locked: isLoading,
              message: 'Carregando dados do mapa',
              details: loadingDescription,
              icon: Icons.map_outlined,
              child: Stack(
                children: [
                  const BackgroundClean(),
                  SplitLayout(
                    left: map,
                    right: rightPane,
                    showRightPanel: sigState.showPanel ||
                        _isIbgeVisible ||
                        _isWeatherVisible ||
                        _isRainVisible,
                    breakpoint: 1300,
                    showDividers: true,
                    dividerThickness: 12,
                    dividerBackgroundColor: Colors.white,
                    dividerBorderColor: Colors.black12,
                    gripColor: const Color(0xFF9E9E9E),
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
