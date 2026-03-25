import 'package:flutter/material.dart';

import 'package:sipged/_widgets/schedule/linear/schedule_cells.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_data.dart';
import 'package:sipged/_widgets/schedule/linear/schedule_lane_class.dart';
import 'schedule_grid.dart';

class ScheduleGridRow extends StatelessWidget {
  final int estacaNumero;
  final List<ScheduleLaneClass> faixas;

  /// Mantido para compatibilidade
  final List<ScheduleRoadData> execucoes;

  /// Índice O(1): [estaca][faixa] -> ScheduleData
  final Map<int, Map<int, ScheduleRoadData>> execIndex;

  final String servicoSelecionado;
  final Color Function(ScheduleRoadData) getSquareColor;
  final void Function(ScheduleRoadData) onTapSquare;
  final String Function(String? uid) userLabelResolver;

  final Set<String> selectedKeys;
  final Color highlightColor;
  final double headerHeight;
  final double columnHeight;

  const ScheduleGridRow({
    super.key,
    required this.estacaNumero,
    required this.faixas,
    required this.execucoes,
    required this.execIndex,
    required this.servicoSelecionado,
    required this.getSquareColor,
    required this.onTapSquare,
    required this.userLabelResolver,
    required this.columnHeight,
    this.selectedKeys = const <String>{},
    this.highlightColor = const Color(0xFF1E88E5),
    this.headerHeight = 25,
  });

  TextStyle _numeroStyle(bool isMultiploDe10) {
    return TextStyle(
      fontSize: isMultiploDe10 ? 10 : 7,
      height: 1.0,
      color: isMultiploDe10 ? Colors.red : Colors.grey[600],
      fontWeight: isMultiploDe10 ? FontWeight.bold : FontWeight.normal,
    );
  }

  ScheduleRoadData _buildDefaultExec(int faixaIndex) {
    return ScheduleRoadData(
      numero: estacaNumero,
      faixaIndex: faixaIndex,
      tipo: servicoSelecionado,
      status: 'a iniciar',
      createdAt: null,
      comentario: null,
      key: servicoSelecionado,
      label: servicoSelecionado.toUpperCase(),
      icon: Icons.layers_outlined,
      color: Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMultiploDe10 = estacaNumero % 10 == 0;
    final numeroStyle = _numeroStyle(isMultiploDe10);

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
          ...List.generate(faixas.length, (i) {
            final faixa = faixas[i];

            final ScheduleRoadData exec =
                execIndex[estacaNumero]?[i] ?? _buildDefaultExec(i);

            final bool enabled = faixa.isAllowed(servicoSelecionado);
            final String cellKey = '${exec.numero}_${exec.faixaIndex}';
            final bool isSelected = selectedKeys.contains(cellKey) && enabled;

            return SizedBox(
              height: faixa.altura + ScheduleGrid.kCellVPad * 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: ScheduleGrid.kCellVPad,
                ),
                child: ScheduleCells(
                  scheduleData: exec,
                  height: faixa.altura,
                  cor: getSquareColor(exec),
                  onTap: () => onTapSquare(exec),
                  isSelected: isSelected,
                  highlightColor: highlightColor,
                  userLabelResolver: userLabelResolver,
                  enabled: enabled,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}