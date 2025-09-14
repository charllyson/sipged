// lib/_widgets/schedule/schedule_grid_row.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/schedule/linear/schedule_cells.dart';
import 'package:siged/_blocs/sectors/operation/road/board/schedule_road_board_data.dart';
import 'package:siged/_widgets/schedule/linear/schedule_lane_class.dart';
import 'schedule_grid.dart';

// Bloc de Usuário
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_event.dart';

class ScheduleGridRow extends StatelessWidget {
  final int estacaNumero;
  final List<ScheduleLaneClass> faixas;

  /// Mantido para compat, mas buscamos O(1) via `execIndex`
  final List<ScheduleRoadBoardData> execucoes;

  /// Índice O(1): [estaca][faixa] -> ScheduleData
  final Map<int, Map<int, ScheduleRoadBoardData>> execIndex;

  final String servicoSelecionado;
  final Color Function(ScheduleRoadBoardData) getSquareColor;
  final void Function(ScheduleRoadBoardData) onTapSquare;

  final Set<String> selectedKeys;
  final Color highlightColor;
  final double headerHeight;
  final double columnHeight;

  const ScheduleGridRow({
    super.key,
    required this.estacaNumero,
    required this.faixas,
    required this.execucoes,
    required this.execIndex, // ✅ novo param
    required this.servicoSelecionado,
    required this.getSquareColor,
    required this.onTapSquare,
    required this.columnHeight,
    this.selectedKeys = const <String>{},
    this.highlightColor = const Color(0xFF1E88E5),
    this.headerHeight = 25,
  });

  @override
  Widget build(BuildContext context) {
    final isMultiploDe10 = estacaNumero % 10 == 0;
    final numeroStyle = TextStyle(
      fontSize: isMultiploDe10 ? 10 : 7,
      height: 1.0,
      color: isMultiploDe10 ? Colors.red : Colors.grey[600],
      fontWeight: isMultiploDe10 ? FontWeight.bold : FontWeight.normal,
    );

    // Estado atual do UserBloc
    final userState = context.watch<UserBloc>().state;

    // Se ainda não carregamos a lista de usuários, pedimos pós-frame.
    if (!userState.initialized && userState.all.isEmpty) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context
              .read<UserBloc>()
              .add(const UsersEnsureLoadedRequested(listenRealtime: true));
        }
      });
    }

    // Resolver: UID -> rótulo legível (usa helper do estado)
    String _resolveUser(String? uid) => userState.labelFor(uid);

    return SizedBox(
      height: columnHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabeçalho da coluna (número da estaca)
          SizedBox(
            height: headerHeight,
            child: Center(
              child: isMultiploDe10
                  ? RotatedBox(
                quarterTurns: 3,
                child: Text(
                  '$estacaNumero',
                  style: numeroStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              )
                  : Text(
                '$estacaNumero',
                style: numeroStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Corpo: uma célula por faixa
          ...List.generate(faixas.length, (i) {
            final faixa = faixas[i];

            // O(1): pega direto do índice; se não houver, usa default
            final ScheduleRoadBoardData exec = execIndex[estacaNumero]?[i] ??
                ScheduleRoadBoardData(
                  numero: estacaNumero,
                  faixaIndex: i,
                  tipo: servicoSelecionado,
                  status: 'a iniciar',
                  createdAt: null,
                  comentario: null,
                  key: servicoSelecionado,
                  label: servicoSelecionado.toUpperCase(),
                  icon: Icons.layers_outlined,
                  color: Colors.grey,
                );

            // Esta faixa aceita o serviço atual?
            final bool enabled = faixa.isAllowed(servicoSelecionado);

            final cellKey = '${exec.numero}_${exec.faixaIndex}';
            final isSelected = selectedKeys.contains(cellKey) && enabled;

            return SizedBox(
              height: faixa.altura + ScheduleGrid.kCellVPad * 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: ScheduleGrid.kCellVPad),
                child: ScheduleCells(
                  scheduleData: exec,
                  height: faixa.altura,
                  cor: getSquareColor(exec),
                  onTap: () => onTapSquare(exec),
                  isSelected: isSelected,
                  highlightColor: highlightColor,
                  userLabelResolver: _resolveUser,
                  enabled: enabled, // ← controla tooltip/click e overlay listrado
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
