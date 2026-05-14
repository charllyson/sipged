import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/screens/modules/operation/schedule/common/header/schedule_header.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_state.dart';

import 'package:sipged/screens/modules/operation/schedule/linear/schedule_linear_map.dart';
import 'package:sipged/screens/modules/operation/schedule/linear/schedule_linear_panel.dart';
import 'package:sipged/screens/modules/operation/schedule/linear/schedule_linear_board.dart';

import 'package:sipged/screens/modules/operation/schedule/common/buttons/schedule_buttons_services.dart';

import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/screens/modules/operation/schedule/common/header/schedule_percent.dart';

class ScheduleLinearWorkspace extends StatefulWidget {
  final ContractData contractData;

  const ScheduleLinearWorkspace({
    super.key,
    required this.contractData,
  });

  @override
  State<ScheduleLinearWorkspace> createState() =>
      _ScheduleLinearWorkspaceState();
}

enum _ViewMode { board, map }

class _ScheduleLinearWorkspaceState extends State<ScheduleLinearWorkspace> {
  _ViewMode _mode = _ViewMode.board;
  bool _panelOpen = false;

  final ValueNotifier<bool> _panelVN = ValueNotifier<bool>(false);

  static final Map<String, Future<double>> _extKmCache = {};

  Widget? _board;

  bool _warmupRequested = false;

  static const double _upBarTitleHeight = 56.0;
  static const double _upBarSubtitleHeight = 35.0;
  static const double _upBarTotalHeight =
      _upBarTitleHeight + _upBarSubtitleHeight;

  @override
  void initState() {
    super.initState();

    final String contractId = widget.contractData.id ?? '';
    _loadExtentAndInit(contractId);
  }

  @override
  void didUpdateWidget(covariant ScheduleLinearWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldId = oldWidget.contractData.id ?? '';
    final newId = widget.contractData.id ?? '';

    if (oldId != newId) {
      _warmupRequested = false;
      _board = null;
      _loadExtentAndInit(newId);
    }
  }

  Future<void> _loadExtentAndInit(String contractId) async {
    if (contractId.isEmpty) return;

    final km = await _readExtentKmFromDfd(context, contractId);
    if (!mounted) return;

    _ensureWarmupOnce(km);

    setState(() {
      _board = ScheduleLinearBoard(
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

    if (_warmupRequested) return;

    if (st.initialized && st.contractId == contractId) return;

    _warmupRequested = true;

    final km = extensaoKm > 0 ? extensaoKm : 0.0;
    final totalEstacas = ((km * 1000) / 20).ceil();
    final int safeTotalEstacas = totalEstacas > 0 ? totalEstacas : 200;

    final summary = contract.id;

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

    if (_extKmCache.containsKey(contractId)) {
      return _extKmCache[contractId]!;
    }

    final fut = () async {
      try {
        final dfdCubit = context.read<DfdCubit>();
        final DfdData? dfd = await dfdCubit.getDataForContract(contractId);

        return (dfd?.extensaoKm ?? 0.0).toDouble();
      } catch (_) {
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

  double _serviceButtonRightOffset({
    required double screenWidth,
    required double breakpoint,
    required double rightPanelWidth,
  }) {
    final isDesktopSplit = screenWidth >= breakpoint;

    if (_panelOpen && isDesktopSplit) {
      return rightPanelWidth + 20;
    }

    return 20;
  }

  Widget _buildFloatingServicesButton({
    required double screenWidth,
    required double breakpoint,
    required double rightPanelWidth,
  }) {
    return BlocBuilder<ScheduleRoadCubit, ScheduleRoadState>(
      buildWhen: (prev, curr) {
        return prev.currentServiceKey != curr.currentServiceKey ||
            prev.servicesRevision != curr.servicesRevision ||
            prev.loadingServices != curr.loadingServices ||
            prev.savingOrImporting != curr.savingOrImporting ||
            prev.busyReason != curr.busyReason ||
            prev.initialized != curr.initialized;
      },
      builder: (context, state) {
        if (!state.initialized) {
          return const SizedBox.shrink();
        }

        final rightOffset = _serviceButtonRightOffset(
          screenWidth: screenWidth,
          breakpoint: breakpoint,
          rightPanelWidth: rightPanelWidth,
        );

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          right: rightOffset,
          bottom: 20,
          child: SafeArea(
            minimum: const EdgeInsets.only(
              right: 8,
              bottom: 8,
            ),
            child: ScheduleButtonsServices(
              options: state.services,
              current: state.currentServiceKey,
              enabled: !state.loadingServices && !state.isBusy,
              initiallyExpanded: true,
              spacing: 10,
              onSelect: (key) {
                context.read<ScheduleRoadCubit>().selectService(key);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double kBottomPanelHeight = 420.0;
    const double kBreakpoint = 980.0;

    final bool isMap = _mode == _ViewMode.map;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double initialRightPanelWidth = screenWidth * 0.25;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(_upBarTotalHeight),
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

            const labels = [
              'Concluído',
              'Em andamento',
              'A iniciar',
            ];

            final values = <double>[
              vConcluido,
              vAndamento,
              vAIniciar,
            ];

            return UpBar(
              titleHeight: _upBarTitleHeight,
              subtitleHeight: _upBarSubtitleHeight,
              subtitleWidgetsHeight: _upBarSubtitleHeight,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SchedulePercent(
                      color: Colors.green.shade800,
                      label: labels[0],
                      value: values[0],
                      percent: vConcluido,
                    ),
                    const SizedBox(width: 4),
                    SchedulePercent(
                      color: Colors.yellow.shade800,
                      label: labels[1],
                      value: values[1],
                      percent: vAndamento,
                    ),
                    const SizedBox(width: 4),
                    SchedulePercent(
                      color: Colors.grey.shade500,
                      label: labels[2],
                      value: values[2],
                      percent: vAIniciar,
                    ),
                  ],
                ),
              ],
              actions: [
                CircleButtonChange(
                  tooltip: isMap ? 'Ver Board' : 'Ver Mapa',
                  icon: isMap ? Icons.table_view : Icons.map_outlined,
                  selected: isMap,
                  iconColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  borderColor: Colors.white.withValues(alpha: 0.24),
                  selectedBackgroundColor: Colors.white,
                  selectedIconColor: const Color(0xFF1B2031),
                  selectedBorderColor: Colors.white,
                  outlined: true,
                  radius: 20,
                  onPressed: _toggleView,
                ),
                CircleButtonChange(
                  tooltip: _panelOpen ? 'Ocultar painel' : 'Mostrar painel',
                  icon: _panelOpen
                      ? Icons.view_sidebar
                      : Icons.view_sidebar_outlined,
                  selected: _panelOpen,
                  iconColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  borderColor: Colors.white.withValues(alpha: 0.24),
                  selectedBackgroundColor: Colors.white,
                  selectedIconColor: const Color(0xFF1B2031),
                  selectedBorderColor: Colors.white,
                  outlined: true,
                  radius: 20,
                  onPressed: _togglePanel,
                ),
              ],
            );
          },
        ),
      ),
      body: BlocBuilder<ScheduleRoadCubit, ScheduleRoadState>(
        buildWhen: (prev, curr) {
          return prev.initialized != curr.initialized ||
              prev.savingOrImporting != curr.savingOrImporting;
        },
        builder: (context, state) {
          final bool locked = !state.initialized || state.savingOrImporting;

          final String message = !state.initialized
              ? 'Preparando dados...'
              : 'Aplicando alterações...';

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
                    final left = IndexedStack(
                      index: isMap ? 1 : 0,
                      children: [
                        _board ??
                            const Center(
                              child: CircularProgressIndicator(),
                            ),
                        ScheduleLinearMap(
                          key: ValueKey(
                            'road_map_${widget.contractData.id ?? ""}',
                          ),
                          contractData: widget.contractData,
                          externalPanelController: _panelVN,
                        ),
                      ],
                    );

                    final rightPanel = ScheduleLinearPanel(
                      contract: widget.contractData,
                    );

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
                _buildFloatingServicesButton(
                  screenWidth: screenWidth,
                  breakpoint: kBreakpoint,
                  rightPanelWidth: initialRightPanelWidth,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}