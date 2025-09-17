// lib/screens/sectors/planning/projects/schedule_road_workspace_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

import 'package:siged/_widgets/schedule/linear/schedule_header.dart';
import 'package:siged/_widgets/schedule/linear/schedule_sub_header.dart';
import 'package:siged/_widgets/schedule/linear/schedule_menu_buttons.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

// Estado unificado do BOARD
import 'package:siged/_blocs/sectors/operation/road/schedule_road_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_state.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_event.dart';
import 'package:siged/screens/sectors/operation/schedule/road/map/schedule_road_map.dart';

import 'board/schedule_road_board.dart';

// Painéis à direita
import 'schedule_road_panel.dart'; // INFO
import 'package:siged/screens/sectors/operation/schedule/road/schedule_road_edit.dart'; // EDIT

class ScheduleRoadWorkspacePage extends StatefulWidget {
  final ContractData contractData;
  const ScheduleRoadWorkspacePage({super.key, required this.contractData});

  @override
  State<ScheduleRoadWorkspacePage> createState() =>
      _ScheduleRoadWorkspacePageState();
}

enum _ViewMode { board, map }
enum _PanelKind { info, edit }

class _ScheduleRoadWorkspacePageState
    extends State<ScheduleRoadWorkspacePage> {
  _ViewMode _mode = _ViewMode.board;
  bool _panelOpen = false;
  _PanelKind _panelKind = _PanelKind.info;

  // sincroniza o painel com o mapa (o mapa só lê este valor)
  final ValueNotifier<bool> _panelVN = ValueNotifier<bool>(false);

  void _toggleView() {
    setState(() {
      _mode = (_mode == _ViewMode.board) ? _ViewMode.map : _ViewMode.board;
    });
  }

  void _togglePanel() {
    setState(() => _panelOpen = !_panelOpen);
    _panelVN.value = _panelOpen;
  }

  void _openEditPanel() {
    setState(() {
      _panelKind = _PanelKind.edit;
      _panelOpen = true;
    });
    _panelVN.value = true;
  }

  void _openInfoPanel() {
    setState(() {
      _panelKind = _PanelKind.info;
      _panelOpen = true;
    });
    _panelVN.value = true;
  }

  @override
  void dispose() {
    _panelVN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double kRightPanelWidth = 600.0;
    const double kCardMaxWidth = 520.0;
    const double kBottomSafeGap = 76.0; // distância “segura” da FootBar; ajuste se precisar

    final isMap = _mode == _ViewMode.map;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: BlocBuilder<ScheduleRoadBloc, ScheduleRoadState>(
          builder: (ctx, state) {
            final isLoading =
                state.loadingServices || state.loadingLanes || state.loadingExecucoes;

            return UpBar(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 12),
                  const BackCircleButton(),
                  const SizedBox(width: 12),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ScheduleHeader(
                          title: state.titleForHeader.isEmpty
                              ? (widget.contractData.summarySubjectContract ?? 'Cronograma')
                              : state.titleForHeader,
                          colorStripe: state.colorForHeader,
                          leftPadding: 0,
                        ),
                        const SizedBox(height: 6),
                        ScheduleSubHeader(
                          isLoading: isLoading,
                          pctConcluido: state.pctConcluido,
                          pctAndamento: state.pctAndamento,
                          pctAIniciar: state.pctAIniciar,
                          leftPadding: 0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                // Alternar Board <-> Mapa (sem push)
                IconButton(
                  tooltip: isMap ? 'Ver Board' : 'Ver Mapa',
                  icon: Icon(isMap ? Icons.table_view : Icons.map_outlined, color: Colors.white),
                  onPressed: _toggleView,
                ),

                // Botão do painel: SEMPRE visível (para board e mapa)
                IconButton(
                  tooltip: _panelOpen ? 'Ocultar painel' : 'Mostrar painel',
                  icon: Icon(
                    _panelOpen ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                    color: Colors.white,
                  ),
                  onPressed: _togglePanel,
                ),

                // Botão EDITAR — abre o painel no modo edição
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: _openEditPanel,
                ),
              ],
            );
          },
        ),
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;

          final left = IndexedStack(
            index: isMap ? 1 : 0,
            children: [
              // BOARD
              ScheduleRoadBoard(contractData: widget.contractData),
              // MAPA — mesmo BLoC; recebe o ValueNotifier para refletir o painel
              ScheduleRoadMap(
                contractData: widget.contractData,
                externalPanelController: _panelVN,
              ),
            ],
          );

          final rightPanel = _panelKind == _PanelKind.info
              ? const PlanningProjectPanel()
              : PlanningProjectEditPanel(
            contract: widget.contractData,
            onSaved: _openInfoPanel,
          );

          // conteúdo central (board/map + painel opcional)
          final content = isWide
              ? Row(
            children: [
              Expanded(child: left),
              if (_panelOpen) ...[
                const VerticalDivider(width: 1),
                SizedBox(width: kRightPanelWidth, child: rightPanel),
              ],
            ],
          )
              : Column(
            children: [
              Expanded(child: left),
              if (_panelOpen) ...[
                const Divider(height: 1),
                SizedBox(height: 420, child: rightPanel),
              ],
            ],
          );

          // desloca o seletor quando o painel direito estiver aberto (evitar overlap)
          final double rightOffset =
          isWide && _panelOpen ? (kRightPanelWidth + 16) : 16;

          return Stack(
            children: [
              // base
              Positioned.fill(child: content),

              // === seletor de serviços flutuante (inferior-direito) ===
              BlocBuilder<ScheduleRoadBloc, ScheduleRoadState>(
                builder: (context, state) {
                  if (state.services.isEmpty) return const SizedBox.shrink();

                  return Positioned(
                    right: rightOffset,
                    bottom: 12, // fica acima da FootBar
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: kCardMaxWidth),
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
            ],
          );
        },
      ),

      bottomNavigationBar: const FootBar(),
    );
  }
}

