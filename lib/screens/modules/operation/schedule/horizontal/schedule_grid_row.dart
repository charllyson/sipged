import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_data.dart';
import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_road_debug.dart';
import 'schedule_grid.dart';
import 'schedule_cells.dart';

class ScheduleGridRow extends StatelessWidget {
  final int estacaNumero;
  final List<ScheduleRoadData> faixas;
  final Map<int, Map<int, ScheduleRoadData>> execIndex;
  final String servicoSelecionado;
  final Color Function(ScheduleRoadData) getSquareColor;
  final void Function(ScheduleRoadData) onTapSquare;
  final String Function(String? uid) userLabelResolver;
  final Set<int> selectedFaixas;
  final Color highlightColor;
  final double headerHeight;
  final double columnHeight;

  const ScheduleGridRow({
    super.key,
    required this.estacaNumero,
    required this.faixas,
    required this.execIndex,
    required this.servicoSelecionado,
    required this.getSquareColor,
    required this.onTapSquare,
    required this.userLabelResolver,
    required this.columnHeight,
    this.selectedFaixas = const <int>{},
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
    ScheduleRoadDebug.rebuild(
      'GridRow',
      'estaca=$estacaNumero, faixas=${faixas.length}, selected=${selectedFaixas.length}',
    );

    final isMultiploDe10 = estacaNumero % 10 == 0;
    final numeroStyle = _numeroStyle(isMultiploDe10);
    final rowExecIndex = execIndex[estacaNumero];

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
            final exec = rowExecIndex?[i] ?? _buildDefaultExec(i);
            final enabled = faixa.isAllowed(servicoSelecionado);
            final alturaFaixa = faixa.altura ?? 20.0;
            final isSelected = selectedFaixas.contains(i) && enabled;

            return SizedBox(
              height: alturaFaixa + ScheduleGrid.kCellVPad * 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: ScheduleGrid.kCellVPad,
                ),
                child: RepaintBoundary(
                  child: ScheduleCells(
                    scheduleData: exec,
                    height: alturaFaixa,
                    cor: getSquareColor(exec),
                    onTap: () => onTapSquare(exec),
                    isSelected: isSelected,
                    highlightColor: highlightColor,
                    userLabelResolver: userLabelResolver,
                    enabled: enabled,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}