import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_state.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_services_data.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';

import 'package:sipged/screens/modules/operation/schedule/linear/schedule_buttons_services.dart';
import 'package:sipged/screens/modules/operation/schedule/common/header/schedule_header.dart';
import 'package:sipged/screens/modules/operation/schedule/common/header/schedule_percent.dart';

import 'package:sipged/screens/modules/operation/schedule/linear/editor/schedule_lane_edit.dart';
import 'package:sipged/screens/modules/operation/schedule/linear/schedule_linear_board.dart';
import 'package:sipged/screens/modules/operation/schedule/linear/schedule_linear_map.dart';
import 'package:sipged/screens/modules/operation/schedule/linear/schedule_linear_panel.dart';

class ScheduleLinearWorkspace extends StatefulWidget {
  const ScheduleLinearWorkspace({
    super.key,
    required this.contractData,
  });

  final ContractData contractData;

  @override
  State<ScheduleLinearWorkspace> createState() =>
      _ScheduleLinearWorkspaceState();
}

enum _ViewMode { board, map }

class _ScheduleLinearWorkspaceState extends State<ScheduleLinearWorkspace> {
  _ViewMode _mode = _ViewMode.board;

  bool _panelOpen = false;
  bool _warmupRequested = false;
  bool _configDialogOpen = false;

  final ValueNotifier<bool> _panelVN = ValueNotifier<bool>(false);

  static final Map<String, Future<double>> _extKmCache =
  <String, Future<double>>{};

  Widget? _board;

  static const double _upBarTitleHeight = 56.0;
  static const double _upBarSubtitleHeight = 35.0;
  static const double _upBarTotalHeight =
      _upBarTitleHeight + _upBarSubtitleHeight;

  @override
  void initState() {
    super.initState();
    _loadExtentBuildBoardAndWarmup(_currentContractId);
  }

  @override
  void didUpdateWidget(covariant ScheduleLinearWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldId = oldWidget.contractData.id ?? '';
    final newId = widget.contractData.id ?? '';

    if (oldId == newId) return;

    _warmupRequested = false;
    _board = null;

    _loadExtentBuildBoardAndWarmup(newId);
  }

  @override
  void dispose() {
    _panelVN.dispose();
    super.dispose();
  }

  String get _currentContractId {
    return (widget.contractData.id ?? '').trim();
  }

  Future<void> _loadExtentBuildBoardAndWarmup(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _board = ScheduleLinearBoard(
          contractData: widget.contractData,
          extensao: 0.0,
        );
      });

      return;
    }

    final km = await _readExtentKmFromDfd(context, cleanContractId);

    if (!mounted) return;

    setState(() {
      _board = ScheduleLinearBoard(
        key: ValueKey<String>('schedule_board_$cleanContractId'),
        contractData: widget.contractData,
        extensao: km,
      );
    });

    _ensureWarmupOnce(
      contractId: cleanContractId,
      extensaoKm: km,
    );
  }

  void _ensureWarmupOnce({
    required String contractId,
    required double extensaoKm,
  }) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return;
    if (_warmupRequested) return;

    final cubit = context.read<ScheduleLinearCubit>();
    final currentState = cubit.state;

    if (currentState.initialized && currentState.contractId == cleanContractId) {
      return;
    }

    _warmupRequested = true;

    final summary = _summaryForScheduleHeader();
    final extensaoDfdMetros = extensaoKm * 1000.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<ScheduleLinearCubit>().warmup(
        contractId: cleanContractId,
        extensaoDfdMetros: extensaoDfdMetros,
        initialServiceKey: ScheduleLinearServicesData.geralKey,
        summarySubjectContract: summary,
      );
    });
  }

  String _summaryForScheduleHeader() {
    final contractId = _currentContractId;

    if (contractId.isNotEmpty) {
      return contractId;
    }

    return 'Cronograma';
  }

  Future<double> _readExtentKmFromDfd(
      BuildContext context,
      String contractId,
      ) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      return Future<double>.value(0.0);
    }

    final cached = _extKmCache[cleanContractId];

    if (cached != null) {
      return cached;
    }

    final future = () async {
      try {
        final dfdCubit = context.read<DfdCubit>();
        final DfdData? dfd = await dfdCubit.getDataForContract(cleanContractId);

        return (dfd?.extensaoKm ?? 0.0).toDouble();
      } catch (_) {
        return 0.0;
      }
    }();

    _extKmCache[cleanContractId] = future;

    return future;
  }

  void _toggleView() {
    setState(() {
      _mode = _mode == _ViewMode.board ? _ViewMode.map : _ViewMode.board;
    });
  }

  void _togglePanel() {
    setState(() {
      _panelOpen = !_panelOpen;
    });

    _panelVN.value = _panelOpen;
  }

  Future<void> _importOrReimportGeometryFromConfig() async {
    final cubit = context.read<ScheduleLinearCubit>();

    await cubit.importGeoJson();
  }

  Future<void> _openLanesAndServicesConfig() async {
    if (_configDialogOpen) return;

    final cubit = context.read<ScheduleLinearCubit>();
    final state = cubit.state;

    if (!state.initialized || state.isBusy) return;

    _configDialogOpen = true;

    try {
      final result = await showDialog<ScheduleLaneResult>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return BlocProvider.value(
            value: cubit,
            child: ScheduleLaneEdit(
              initialRows: state.lanes,
              initialServices: state.services,
              selectedServiceKey: state.currentServiceKey,
              selectedServiceLabel: state.titleForHeader,
              onImportGeometry: _importOrReimportGeometryFromConfig,
            ),
          );
        },
      );

      if (!mounted || result == null) return;

      await cubit.saveLanesAndServices(
        lanes: result.lanes,
        services: result.services,
      );
    } finally {
      _configDialogOpen = false;
    }
  }

  double _serviceButtonRightOffset({
    required double screenWidth,
    required double breakpoint,
    required double rightPanelWidth,
  }) {
    final isDesktopSplit = screenWidth >= breakpoint;

    if (_panelOpen && isDesktopSplit) {
      return rightPanelWidth + 20.0;
    }

    return 20.0;
  }

  Widget _buildFloatingServicesButton({
    required double screenWidth,
    required double breakpoint,
    required double rightPanelWidth,
  }) {
    return BlocBuilder<ScheduleLinearCubit, ScheduleLinearState>(
      buildWhen: (previous, current) {
        return previous.currentServiceKey != current.currentServiceKey ||
            previous.servicesRevision != current.servicesRevision ||
            previous.loadingServices != current.loadingServices ||
            previous.savingOrImporting != current.savingOrImporting ||
            previous.busyReason != current.busyReason ||
            previous.initialized != current.initialized;
      },
      builder: (context, state) {
        if (!state.initialized || state.services.isEmpty) {
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
          bottom: 20.0,
          child: SafeArea(
            minimum: const EdgeInsets.only(
              right: 8.0,
              bottom: 8.0,
            ),
            child: ScheduleButtonsServices(
              options: state.services,
              current: state.currentServiceKey,
              enabled: !state.loadingServices && !state.isBusy,
              initiallyExpanded: true,
              spacing: 10.0,
              onSelect: (serviceKey) {
                context.read<ScheduleLinearCubit>().changeService(serviceKey);
              },
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar({
    required bool isMap,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(_upBarTotalHeight),
      child: BlocBuilder<ScheduleLinearCubit, ScheduleLinearState>(
        buildWhen: (previous, current) {
          return previous.currentServiceKey != current.currentServiceKey ||
              previous.servicesRevision != current.servicesRevision ||
              previous.lanesRevision != current.lanesRevision ||
              previous.execRevision != current.execRevision ||
              previous.loadingExecucoes != current.loadingExecucoes ||
              previous.loadingServices != current.loadingServices ||
              previous.loadingLanes != current.loadingLanes ||
              previous.savingOrImporting != current.savingOrImporting ||
              previous.busyReason != current.busyReason ||
              previous.initialized != current.initialized ||
              previous.summarySubjectContract != current.summarySubjectContract;
        },
        builder: (context, state) {
          final vConcluido =
          state.pctConcluido.isFinite ? state.pctConcluido : 0.0;

          final vAndamento =
          state.pctAndamento.isFinite ? state.pctAndamento : 0.0;

          final vAIniciar =
          state.pctAIniciar.isFinite ? state.pctAIniciar : 0.0;

          final title = state.titleForHeader.isEmpty
              ? (state.summarySubjectContract ?? 'Cronograma')
              : state.titleForHeader;

          final canOpenConfig = state.initialized && !state.isBusy;

          return UpBar(
            titleHeight: _upBarTitleHeight,
            subtitleHeight: _upBarSubtitleHeight,
            subtitleWidgetsHeight: _upBarSubtitleHeight,
            leading: const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: CircleButtonChange(),
            ),
            subtitleWidgets: <Widget>[
              Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.sizeOf(context).width;
                  final isCompact = screenWidth < 720.0;

                  final headerMaxWidth = isCompact
                      ? 150.0
                      : screenWidth < 980.0
                      ? 240.0
                      : 420.0;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      ScheduleHeader(
                        title: title,
                        titleStyle: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 14.0 : 16.0,
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                        colorStripe: state.colorForHeader,
                        leftPadding: 0.0,
                        shrinkToFit: true,
                        maxWidth: headerMaxWidth,
                      ),
                      SizedBox(width: isCompact ? 4.0 : 8.0),
                      SchedulePercent(
                        color: Colors.green.shade800,
                        label: 'Concluído',
                        value: vConcluido,
                        percent: vConcluido,
                      ),
                      SizedBox(width: isCompact ? 2.0 : 4.0),
                      SchedulePercent(
                        color: Colors.yellow.shade800,
                        label: 'Em andamento',
                        value: vAndamento,
                        percent: vAndamento,
                      ),
                      SizedBox(width: isCompact ? 2.0 : 4.0),
                      SchedulePercent(
                        color: Colors.grey.shade500,
                        label: 'A iniciar',
                        value: vAIniciar,
                        percent: vAIniciar,
                      ),
                    ],
                  );
                },
              ),
            ],
            actions: <Widget>[
              CircleButtonChange(
                tooltip: 'Faixas e serviços',
                icon: Icons.tune_outlined,
                selected: false,
                iconColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                borderColor: Colors.white.withValues(alpha: 0.24),
                selectedBackgroundColor: Colors.white,
                selectedIconColor: const Color(0xFF1B2031),
                selectedBorderColor: Colors.white,
                outlined: true,
                radius: 20.0,
                onPressed: canOpenConfig ? _openLanesAndServicesConfig : null,
              ),
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
                radius: 20.0,
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
                radius: 20.0,
                onPressed: _togglePanel,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody({
    required bool isMap,
    required double screenWidth,
    required double breakpoint,
    required double rightPanelWidth,
    required double bottomPanelHeight,
  }) {
    return BlocBuilder<ScheduleLinearCubit, ScheduleLinearState>(
      buildWhen: (previous, current) {
        return previous.initialized != current.initialized ||
            previous.savingOrImporting != current.savingOrImporting ||
            previous.busyReason != current.busyReason;
      },
      builder: (context, state) {
        final locked = !state.initialized || state.savingOrImporting;

        final message = !state.initialized
            ? 'Preparando dados...'
            : (state.busyReason ?? 'Aplicando alterações...');

        final details = !state.initialized
            ? 'Carregando os dados.'
            : 'Atualizando os dados...';

        return ScreenLock(
          locked: locked,
          message: message,
          details: details,
          icon: Icons.alt_route,
          keepAppBarUndimmed: true,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const BackgroundChange(),
              Positioned.fill(
                child: SplitLayout(
                  left: IndexedStack(
                    index: isMap ? 1 : 0,
                    children: <Widget>[
                      _board ??
                          const Center(
                            child: CircularProgressIndicator(),
                          ),
                      ScheduleLinearMap(
                        key: ValueKey<String>(
                          'road_map_${widget.contractData.id ?? ""}',
                        ),
                        contractData: widget.contractData,
                        externalPanelController: _panelVN,
                      ),
                    ],
                  ),
                  right: ScheduleLinearPanel(
                    contract: widget.contractData,
                  ),
                  showRightPanel: _panelOpen,
                  breakpoint: breakpoint,
                  rightPanelWidth: rightPanelWidth,
                  bottomPanelHeight: bottomPanelHeight,
                  showDividers: true,
                ),
              ),
              _buildFloatingServicesButton(
                screenWidth: screenWidth,
                breakpoint: breakpoint,
                rightPanelWidth: rightPanelWidth,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double bottomPanelHeight = 420.0;
    const double breakpoint = 980.0;

    final isMap = _mode == _ViewMode.map;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final rightPanelWidth = screenWidth * 0.25;

    return Scaffold(
      appBar: _buildAppBar(isMap: isMap),
      body: _buildBody(
        isMap: isMap,
        screenWidth: screenWidth,
        breakpoint: breakpoint,
        rightPanelWidth: rightPanelWidth,
        bottomPanelHeight: bottomPanelHeight,
      ),
    );
  }
}