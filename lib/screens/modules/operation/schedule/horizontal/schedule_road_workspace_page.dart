import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_header.dart';
import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_menu_buttons.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_state.dart';

import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_road_map.dart';
import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_road_panel.dart';
import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_road_board.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_status_legend.dart';

import 'schedule_road_debug.dart';

class ScheduleRoadWorkspacePage extends StatefulWidget {
  final ContractData contractData;

  const ScheduleRoadWorkspacePage({
    super.key,
    required this.contractData,
  });

  @override
  State<ScheduleRoadWorkspacePage> createState() =>
      _ScheduleRoadWorkspacePageState();
}

enum _ViewMode { board, map }

class _ScheduleRoadWorkspacePageState extends State<ScheduleRoadWorkspacePage> {
  _ViewMode _mode = _ViewMode.board;
  bool _panelOpen = false;

  final ValueNotifier<bool> _panelVN = ValueNotifier<bool>(false);

  static final Map<String, Future<double>> _extKmCache = {};

  Widget? _board;

  bool _warmupRequested = false;

  @override
  void initState() {
    super.initState();

    ScheduleRoadDebug.log('WorkspacePage', 'initState');

    final String contractId = widget.contractData.id ?? '';
    _loadExtentAndInit(contractId);
  }

  @override
  void didUpdateWidget(covariant ScheduleRoadWorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldId = oldWidget.contractData.id ?? '';
    final newId = widget.contractData.id ?? '';

    ScheduleRoadDebug.log(
      'WorkspacePage',
      'didUpdateWidget old=$oldId new=$newId',
    );

    if (oldId != newId) {
      _warmupRequested = false;
      _board = null;
      _loadExtentAndInit(newId);
    }
  }

  Future<void> _loadExtentAndInit(String contractId) async {
    ScheduleRoadDebug.log(
      'WorkspacePage',
      '_loadExtentAndInit(contractId=$contractId)',
    );

    if (contractId.isEmpty) return;

    final km = await _readExtentKmFromDfd(context, contractId);
    if (!mounted) return;

    _ensureWarmupOnce(km);

    setState(() {
      _board = ScheduleRoadBoard(
        contractData: widget.contractData,
        extensao: km,
      );
    });
  }

  void _ensureWarmupOnce(double extensaoKm) {
    final contract = widget.contractData;
    final contractId = contract.id ?? '';
    if (contractId.isEmpty) return;

    final cubit = context.read<ScheduleRoadCubit>();
    final st = cubit.state;

    if (_warmupRequested) {
      ScheduleRoadDebug.log(
        'WorkspacePage',
        '_ensureWarmupOnce ignorado: _warmupRequested=true',
      );
      return;
    }

    if (st.initialized && st.contractId == contractId) {
      ScheduleRoadDebug.log(
        'WorkspacePage',
        '_ensureWarmupOnce ignorado: cubit já inicializado',
      );
      return;
    }

    _warmupRequested = true;

    final km = extensaoKm > 0 ? extensaoKm : 0.0;
    final totalEstacas = ((km * 1000) / 20).ceil();
    final int safeTotalEstacas = totalEstacas > 0 ? totalEstacas : 200;
    final summary = contract.id;

    ScheduleRoadDebug.log(
      'WorkspacePage',
      'disparando warmup contractId=$contractId totalEstacas=$safeTotalEstacas',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      cubit.warmup(
        contractId: contractId,
        totalEstacas: safeTotalEstacas,
        initialServiceKey: 'geral',
        summarySubjectContract: summary,
      );
    });
  }

  Future<double> _readExtentKmFromDfd(
      BuildContext context,
      String contractId,
      ) {
    if (contractId.isEmpty) return Future.value(0.0);
    if (_extKmCache.containsKey(contractId)) return _extKmCache[contractId]!;

    final fut = () async {
      try {
        ScheduleRoadDebug.log(
          'WorkspacePage',
          'lendo extensão DFD para contractId=$contractId',
        );

        final dfdCubit = context.read<DfdCubit>();
        final DfdData? dfd = await dfdCubit.getDataForContract(contractId);
        final km = (dfd?.extensaoKm ?? 0.0).toDouble();

        ScheduleRoadDebug.log(
          'WorkspacePage',
          'extensão carregada => $km km',
        );

        return km;
      } catch (_) {
        ScheduleRoadDebug.log(
          'WorkspacePage',
          'falha ao ler extensão DFD; usando 0.0',
        );
        return 0.0;
      }
    }();

    _extKmCache[contractId] = fut;
    return fut;
  }

  void _toggleView() {
    setState(() {
      _mode = (_mode == _ViewMode.board) ? _ViewMode.map : _ViewMode.board;
    });
  }

  void _togglePanel() {
    setState(() => _panelOpen = !_panelOpen);
    _panelVN.value = _panelOpen;
  }

  @override
  void dispose() {
    _panelVN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScheduleRoadDebug.log(
      'WorkspacePage',
      'rebuild => mode=$_mode, panel=$_panelOpen',
    );

    const double kBottomPanelHeight = 420.0;
    const double kBreakpoint = 980.0;
    const double kCardMaxWidth = 520.0;

    final bool isMap = _mode == _ViewMode.map;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double initialRightPanelWidth = screenWidth * 0.25;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: BlocBuilder<ScheduleRoadCubit, ScheduleRoadState>(
          buildWhen: (prev, curr) {
            return prev.currentServiceKey != curr.currentServiceKey ||
                prev.servicesRevision != curr.servicesRevision ||
                prev.execRevision != curr.execRevision ||
                prev.loadingExecucoes != curr.loadingExecucoes ||
                prev.initialized != curr.initialized;
          },
          builder: (ctx, state) {
            final double vConcluido =
            state.pctConcluido.isFinite ? state.pctConcluido : 0;
            final double vAndamento =
            state.pctAndamento.isFinite ? state.pctAndamento : 0;
            final double vAIniciar =
            state.pctAIniciar.isFinite ? state.pctAIniciar : 0;

            const labels = ['Concluído', 'Em andamento', 'A iniciar'];
            final values = <double>[vConcluido, vAndamento, vAIniciar];

            return UpBar(
              leading: const Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: CircleButtonChange(),
              ),
              titleWidgets: [
                ScheduleHeader(
                  title: state.titleForHeader.isEmpty
                      ? (state.summarySubjectContract ?? 'Cronograma')
                      : state.titleForHeader,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  colorStripe: state.colorForHeader,
                  leftPadding: 0,
                ),
              ],
              subtitleWidgets: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ScheduleStatusLegend(
                        color: Colors.green.shade800,
                        label: labels[0],
                        value: values[0],
                        percent: vConcluido,
                      ),
                      const SizedBox(width: 4),
                      ScheduleStatusLegend(
                        color: Colors.yellow.shade800,
                        label: labels[1],
                        value: values[1],
                        percent: vAndamento,
                      ),
                      const SizedBox(width: 4),
                      ScheduleStatusLegend(
                        color: Colors.grey.shade500,
                        label: labels[2],
                        value: values[2],
                        percent: vAIniciar,
                      ),
                    ],
                  ),
                ),
              ],
              subtitleHeight: 20,
              actions: [
                IconButton(
                  tooltip: isMap ? 'Ver Board' : 'Ver Mapa',
                  icon: Icon(
                    isMap ? Icons.table_view : Icons.map_outlined,
                    color: Colors.white,
                  ),
                  onPressed: _toggleView,
                ),
                IconButton(
                  tooltip: _panelOpen ? 'Ocultar painel' : 'Mostrar painel',
                  icon: Icon(
                    _panelOpen
                        ? Icons.view_sidebar
                        : Icons.view_sidebar_outlined,
                    color: Colors.white,
                  ),
                  onPressed: _togglePanel,
                ),
              ],
            );
          },
        ),
      ),
      body: BlocBuilder<ScheduleRoadCubit, ScheduleRoadState>(
        buildWhen: (prev, curr) =>
        prev.initialized != curr.initialized ||
            prev.savingOrImporting != curr.savingOrImporting,
        builder: (context, state) {
          final bool locked = !state.initialized || state.savingOrImporting;

          final String message =
          !state.initialized ? 'Preparando dados...' : 'Aplicando alterações...';

          final String details = !state.initialized
              ? 'Carregando cronograma e geometria da obra.'
              : 'Aguarde enquanto o cronograma é atualizado.';

          return ScreenLock(
            locked: locked,
            message: message,
            details: details,
            icon: Icons.alt_route,
            keepAppBarUndimmed: true,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const BackgroundChange(),
                Builder(
                  builder: (context) {
                    final left = Stack(
                      fit: StackFit.expand,
                      children: [
                        IndexedStack(
                          index: isMap ? 1 : 0,
                          children: [
                            _board ??
                                const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            ScheduleRoadMap(
                              key: ValueKey(
                                'road_map_${widget.contractData.id ?? ""}',
                              ),
                              contractData: widget.contractData,
                              externalPanelController: _panelVN,
                            ),
                          ],
                        ),
                        Positioned(
                          right: 16,
                          bottom: 12,
                          child: BlocBuilder<ScheduleRoadCubit, ScheduleRoadState>(
                            buildWhen: (prev, curr) {
                              return prev.servicesRevision != curr.servicesRevision ||
                                  prev.currentServiceKey != curr.currentServiceKey;
                            },
                            builder: (context, st) {
                              if (st.services.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: kCardMaxWidth,
                                ),
                                child: ScheduleMenuButtons(
                                  options: st.services,
                                  current: st.currentServiceKey,
                                  onSelect: (key) => context
                                      .read<ScheduleRoadCubit>()
                                      .selectService(key),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );

                    final rightPanel =
                    ScheduleRoadPanel(contract: widget.contractData);

                    return Positioned.fill(
                      child: SplitLayout(
                        left: left,
                        right: rightPanel,
                        showRightPanel: _panelOpen,
                        breakpoint: kBreakpoint,
                        rightPanelWidth: initialRightPanelWidth,
                        bottomPanelHeight: kBottomPanelHeight,
                        showDividers: true,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}