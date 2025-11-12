// lib/screens/sectors/operation/schedule/road/schedule_road_workspace_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_event.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

import 'package:siged/_widgets/schedule/linear/schedule_header.dart';
import 'package:siged/_widgets/schedule/linear/schedule_sub_header.dart';
import 'package:siged/_widgets/schedule/linear/schedule_menu_buttons.dart';

import 'package:siged/_blocs/_process/process_data.dart';

// BLoC do cronograma rodoviário
import 'package:siged/_blocs/sectors/operation/road/schedule_road_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_state.dart';
import 'package:siged/screens/sectors/operation/schedule/road/schedule_road_map.dart';
import 'package:siged/screens/sectors/operation/schedule/road/schedule_road_panel.dart';

// Board
import '../../../../../_widgets/schedule/linear/schedule_road_board.dart';

// ✅ Layout unificado (lado a lado vs empilhado)
import 'package:siged/_widgets/layout/responsive_split_view.dart';

// <<< NOVO: ler extensão do DFD >>>
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_repository.dart';

class ScheduleRoadWorkspacePage extends StatefulWidget {
  final ProcessData contractData;
  const ScheduleRoadWorkspacePage({super.key, required this.contractData});

  @override
  State<ScheduleRoadWorkspacePage> createState() =>
      _ScheduleRoadWorkspacePageState();
}

enum _ViewMode { board, map }

class _ScheduleRoadWorkspacePageState
    extends State<ScheduleRoadWorkspacePage> {
  _ViewMode _mode = _ViewMode.board;
  bool _panelOpen = false;

  // sincroniza o painel com o mapa (o mapa só lê este valor)
  final ValueNotifier<bool> _panelVN = ValueNotifier<bool>(false);

  // <<< NOVO: cache local da extensão via DFD >>>
  static final Map<String, Future<double>> _extKmCache = {};
  late final Future<double> _futureExtKm;

  @override
  void initState() {
    super.initState();
    final id = widget.contractData.id ?? '';
    _futureExtKm = _readExtentKmFromDfd(id);
  }

  Future<double> _readExtentKmFromDfd(String contractId) {
    if (contractId.isEmpty) return Future.value(0.0);
    if (_extKmCache.containsKey(contractId)) return _extKmCache[contractId]!;
    final fut = () async {
      try {
        final repo = DfdRepository();
        final res = await repo.readWorkTypeAndExtent(contractId);
        return (res.extensaoKm ?? 0.0).toDouble();
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

  @override
  Widget build(BuildContext context) {
    // Constantes visuais do container responsivo
    const double kRightPanelWidth = 600.0;
    const double kBottomPanelHeight = 420.0;
    const double kBreakpoint = 980.0;
    const double kCardMaxWidth = 520.0;

    final isMap = _mode == _ViewMode.map;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: BlocBuilder<ScheduleRoadBloc, ScheduleRoadState>(
          builder: (ctx, state) {
            // não mostramos spinner no header; overlay central cuida do loading
            const showHeaderSpinner = false;

            return UpBar(
              leading: const Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: BackCircleButton(),
              ),
              actions: [
                // Alternar Board <-> Mapa (sem push)
                IconButton(
                  tooltip: isMap ? 'Ver Board' : 'Ver Mapa',
                  icon: Icon(
                    isMap ? Icons.table_view : Icons.map_outlined,
                    color: Colors.white,
                  ),
                  onPressed: _toggleView,
                ),

                // Botão do painel: SEMPRE visível (para board e mapa)
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

      body: Stack(
        fit: StackFit.expand,
        children: [
          const BackgroundClean(),

          // === conteúdo central (Board/Mapa + Painel responsivo unificado) ===
          Builder(
            builder: (context) {
              final left = IndexedStack(
                index: isMap ? 1 : 0,
                children: [
                  // BOARD — agora recebe extensão via DFD (não usa mais contractData.ext)
                  FutureBuilder<double>(
                    future: _futureExtKm,
                    builder: (context, snap) {
                      final km = (snap.data ?? 0.0);
                      return Stack(
                        children: [
                          ScheduleRoadBoard(
                            contractData: widget.contractData,
                            extensao: km, // <<< AQUI AJUSTADO
                          ),
                          if (!snap.hasData)
                            Positioned.fill(
                              child: IgnorePointer(
                                ignoring: true,
                                child: Container(
                                  color: Colors.transparent,
                                  alignment: Alignment.center,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 12,
                                          color: Colors.black26,
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Carregando extensão (DFD)...',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  // MAPA — mesmo BLoC; recebe o ValueNotifier para refletir o painel
                  ScheduleRoadMap(
                    contractData: widget.contractData,
                    externalPanelController: _panelVN,
                  ),
                ],
              );

              // único painel à direita (INFO)
              final rightPanel =
              ScheduleRoadPanel(contract: widget.contractData);

              // Usa o layout padrão responsivo
              final content = ResponsiveSplitView(
                left: left,
                right: rightPanel,
                showRightPanel: _panelOpen,
                breakpoint: kBreakpoint,
                rightPanelWidth: kRightPanelWidth,
                bottomPanelHeight: kBottomPanelHeight,
                showDividers: true,
              );

              // desloca o seletor quando o painel direito estiver aberto (evitar overlap)
              final isWide =
                  MediaQuery.sizeOf(context).width >= kBreakpoint;
              final double rightOffset =
              isWide && _panelOpen ? (kRightPanelWidth + 16) : 16;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // base
                  Positioned.fill(child: content),

                  // === seletor de serviços flutuante (inferior-direito) ===
                  BlocBuilder<ScheduleRoadBloc, ScheduleRoadState>(
                    builder: (context, state) {
                      if (state.services.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Positioned(
                        right: rightOffset,
                        bottom: 12, // fica acima da FootBar
                        child: ConstrainedBox(
                          constraints:
                          const BoxConstraints(maxWidth: kCardMaxWidth),
                          child: ScheduleMenuButtons(
                            options: state.services,
                            current: state.currentServiceKey,
                            onSelect: (key) => context
                                .read<ScheduleRoadBloc>()
                                .add(ScheduleServiceSelected(key)),
                          ),
                        ),
                      );
                    },
                  ),

                  // === ÚNICO OVERLAY: "Preparando dados..." (apenas enquanto !initialized) ===
                  BlocBuilder<ScheduleRoadBloc, ScheduleRoadState>(
                    buildWhen: (p, c) => p.initialized != c.initialized,
                    builder: (context, state) {
                      if (state.initialized) return const SizedBox.shrink();

                      return Positioned.fill(
                        child: IgnorePointer(
                          ignoring: false, // bloqueia cliques enquanto carrega
                          child: Material(
                            type: MaterialType.transparency,
                            child: Container(
                              // Transparência para deixar o BackgroundClean "vazar"
                              color: Colors.black.withOpacity(0.18),
                              alignment: Alignment.center,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 14,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Preparando dados...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),

      bottomNavigationBar: const FootBar(),
    );
  }
}
