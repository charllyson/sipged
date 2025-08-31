import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/schedule/schedule_cells.dart';
import 'package:siged/_blocs/sectors/operation/schedule_data.dart';
import 'package:siged/_widgets/schedule/schedule_lane_class.dart';
import 'schedule_grid.dart';

// Bloc de Usuário
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_event.dart';
import 'package:siged/_blocs/system/user/user_state.dart';

class ScheduleUpLegendColumn extends StatelessWidget {
  final int estacaNumero;
  final List<ScheduleLaneClass> faixas;
  final List<ScheduleData> execucoes;
  final String servicoSelecionado;
  final Color Function(ScheduleData) getSquareColor;
  final void Function(ScheduleData) onTapSquare;

  final Set<String> selectedKeys;
  final Color highlightColor;
  final double headerHeight;
  final double columnHeight;

  const ScheduleUpLegendColumn({
    super.key,
    required this.estacaNumero,
    required this.faixas,
    required this.execucoes,
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
          context.read<UserBloc>().add(const UsersEnsureLoadedRequested(listenRealtime: true));
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
          SizedBox(
            height: headerHeight,
            child: Center(
              child: isMultiploDe10
                  ? RotatedBox(
                quarterTurns: 3,
                child: Text('$estacaNumero', style: numeroStyle, overflow: TextOverflow.ellipsis),
              )
                  : Text('$estacaNumero', style: numeroStyle, overflow: TextOverflow.ellipsis),
            ),
          ),
          ...List.generate(faixas.length, (i) {
            final faixa = faixas[i];

            final exec = execucoes.firstWhere(
                  (e) => e.numero == estacaNumero && e.faixaIndex == i,
              orElse: () => ScheduleData(
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
              ),
            );

            final cellKey = '${exec.numero}_${exec.faixaIndex}';
            final isSelected = selectedKeys.contains(cellKey);

            return SizedBox(
              height: faixa.altura + ScheduleGrid.kCellVPad * 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: ScheduleGrid.kCellVPad),
                child: ScheduleCells(
                  execucao: exec,
                  altura: faixa.altura,
                  cor: getSquareColor(exec),
                  onTap: () => onTapSquare(exec),
                  isSelected: isSelected,
                  highlightColor: highlightColor,
                  userLabelResolver: _resolveUser,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
