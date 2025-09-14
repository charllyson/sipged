// lib/_widgets/schedule/schedule_grid.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:siged/_widgets/schedule/linear/schedule_grid_row.dart';
import 'package:siged/_widgets/schedule/linear/schedule_legend.dart';
import 'package:siged/_blocs/sectors/operation/road/board/schedule_road_board_data.dart';
import 'package:siged/_blocs/sectors/operation/road/board/schedule_road_board_style.dart';
import 'package:siged/_widgets/schedule/linear/schedule_lane_class.dart';

class ScheduleGrid extends StatelessWidget {
  const ScheduleGrid({
    super.key,
    required this.totalEstacas,
    required this.faixas,
    required this.execucoes,
    required this.execIndex, // ✅ índice O(1)
    required this.servicoSelecionado,
    required this.legendWidth,
    required this.estacaWidth,
    required this.getSquareColor,
    required this.onTapSquare,
    this.selectedKeys = const <String>{},
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.highlightColor = const Color(0xFF1E88E5),
    this.headerHeight = 25,
    this.rightGutter = 0,
  });

  final int totalEstacas;
  final List<ScheduleLaneClass> faixas;
  final List<ScheduleRoadBoardData> execucoes;

  /// Índice O(1) por célula: [estaca][faixa] -> ScheduleData
  final Map<int, Map<int, ScheduleRoadBoardData>> execIndex;

  final String servicoSelecionado;

  final double legendWidth;
  final double estacaWidth;

  /// Cor base calculada pelo State (com sombreamento por recência).
  final Color Function(ScheduleRoadBoardData e) getSquareColor;

  /// Handler de toque em célula válida.
  final void Function(ScheduleRoadBoardData e) onTapSquare;

  final Set<String> selectedKeys;
  final void Function(int estaca, int faixaIndex)? onDragStart;
  final void Function(int estaca, int faixaIndex)? onDragUpdate;
  final VoidCallback? onDragEnd;

  final Color highlightColor;
  final double headerHeight;
  final double rightGutter;

  static const double kCellVPad = 0.5;

  String _posLabelForIndex(int i) {
    const pattern = ['LE', 'LE', 'CE', 'LD', 'LD'];
    return pattern[i % pattern.length];
  }

  int _faixaIndexFromDy(double dy) {
    // dy relativo à área do grid (não ao ListView inteiro)
    dy -= headerHeight;
    if (dy < 0) return 0;
    double acc = 0;
    for (int i = 0; i < faixas.length; i++) {
      final seg = faixas[i].altura + kCellVPad * 2;
      acc += seg;
      if (dy < acc) return i;
    }
    return faixas.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    const double gapLegendGrid = 8.0;
    const double itemHPad = 10.0;
    const double itemVPad = 12.0;

    final double columnHeight = (headerHeight +
        faixas.fold<double>(0, (acc, f) => acc + f.altura + kCellVPad * 2))
        .roundToDouble();

    // wrappers para respeitar allowedByService SEM mudar o resto dos widgets
    bool laneEnabledFor(int faixaIndex) {
      if (faixaIndex < 0 || faixaIndex >= faixas.length) return true;
      return faixas[faixaIndex].isAllowed(servicoSelecionado);
    }

    Color safeSquareColor(ScheduleRoadBoardData e) {
      return laneEnabledFor(e.faixaIndex)
          ? getSquareColor(e)
          : Colors.grey.shade200; // visual desabilitado
    }

    void safeOnTapSquare(ScheduleRoadBoardData e) {
      if (!laneEnabledFor(e.faixaIndex)) return; // ignora toques
      onTapSquare(e);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double larguraTotal = constraints.maxWidth;
        final double larguraInterna =
        (larguraTotal - itemHPad * 2).clamp(0.0, double.infinity);
        final double larguraUtilGrid =
        (larguraInterna - legendWidth - gapLegendGrid - rightGutter)
            .clamp(0.0, double.infinity);

        final int colsTotal =
        (larguraUtilGrid / estacaWidth).floor().clamp(2, 100000);
        final int reaisPorLinha =
        (colsTotal - 1).clamp(1, 100000); // -1 ghost
        final double cellWidth =
        colsTotal > 0 ? larguraUtilGrid / colsTotal : estacaWidth;
        final int linhas = (totalEstacas / reaisPorLinha).ceil();

        // dx -> número da estaca naquela linha (considerando a 1ª coluna fantasma)
        int estacaFromDx(double dx, int start, int reaisPorLinha) {
          int col = (dx / cellWidth).floor(); // 0 = ghost, 1..N = reais
          if (col <= 0) return (start + 1).clamp(1, totalEstacas);
          final estaca = start + col; // col 1 -> start+1
          final maxEstacaLinha = (start + reaisPorLinha);
          return estaca.clamp(start + 1, math.min(maxEstacaLinha, totalEstacas));
        }

        Widget ghostColumn(double w) {
          double top = headerHeight;
          final List<Widget> children = [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: headerHeight,
              child: const SizedBox.shrink(),
            ),
          ];

          for (int i = 0; i < faixas.length; i++) {
            final double segHeight = faixas[i].altura + kCellVPad * 2;
            children.add(
              Positioned(
                left: 0,
                right: 0,
                top: top,
                height: segHeight,
                child: IgnorePointer(
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: ScheduleGrid.kCellVPad),
                    child: Container(
                      decoration: BoxDecoration(
                        color: ScheduleRoadBoardStyle.colorForFaixa(faixas[i].label),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Text(
                          _posLabelForIndex(i),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            top += segHeight;
          }

          return SizedBox(width: w, height: columnHeight, child: Stack(children: children));
        }

        return Stack(
          children: [
            ListView.builder(
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              addSemanticIndexes: false,
              cacheExtent: 800,
              itemCount: linhas,
              itemBuilder: (context, linhaIndex) {
                final start = linhaIndex * reaisPorLinha;
                final endExclusive =
                math.min(start + reaisPorLinha, totalEstacas);
                final count = endExclusive - start;

                final reais = List.generate(count, (i) {
                  final estacaNumero = start + i + 1;
                  return SizedBox(
                    width: cellWidth,
                    height: columnHeight,
                    child: RepaintBoundary(
                      child: ScheduleGridRow(
                        estacaNumero: estacaNumero,
                        faixas: faixas,
                        execucoes: execucoes,     // compat / fallback
                        execIndex: execIndex,     // ✅ O(1)
                        servicoSelecionado: servicoSelecionado,
                        // wrappers que blindam cor e toque quando faixa não é aplicável
                        getSquareColor: safeSquareColor,
                        onTapSquare: safeOnTapSquare,
                        selectedKeys: selectedKeys,
                        highlightColor: highlightColor,
                        headerHeight: headerHeight,
                        columnHeight: columnHeight,
                      ),
                    ),
                  );
                });

                final gridArea = SizedBox(
                  width: larguraUtilGrid,
                  height: columnHeight,
                  child: Row(
                    children: [
                      ghostColumn(cellWidth),
                      ...reais,
                    ],
                  ),
                );

                // captura arrasto sem bloquear os taps das células
                final gridWithDrag = Listener(
                  behavior: HitTestBehavior.deferToChild,
                  onPointerDown: (ev) {
                    if (onDragStart == null) return;
                    final p = ev.localPosition;
                    if (p.dy <= headerHeight) return; // ignora cabeçalho
                    final faixa = _faixaIndexFromDy(p.dy);
                    if (!laneEnabledFor(faixa)) return; // não inicia seleção em faixa bloqueada
                    final estaca = estacaFromDx(p.dx, start, reaisPorLinha);
                    onDragStart!(estaca, faixa);
                  },
                  onPointerMove: (ev) {
                    if (onDragUpdate == null) return;
                    final p = ev.localPosition;
                    if (p.dy <= headerHeight) return;
                    final faixa = _faixaIndexFromDy(p.dy);
                    if (!laneEnabledFor(faixa)) return; // ignora movimento sobre faixa bloqueada
                    final estaca = estacaFromDx(p.dx, start, reaisPorLinha);
                    onDragUpdate!(estaca, faixa);
                  },
                  onPointerUp: (_) => onDragEnd?.call(),
                  onPointerCancel: (_) => onDragEnd?.call(),
                  child: gridArea,
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: itemVPad, horizontal: itemHPad),
                  child: SizedBox(
                    width: larguraInterna,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: legendWidth,
                          height: columnHeight,
                          child: ScheduleLegend(
                            faixas: faixas,
                            legendWidth: legendWidth,
                            headerHeight: headerHeight,
                            columnHeight: columnHeight,
                          ),
                        ),
                        const SizedBox(width: gapLegendGrid),
                        gridWithDrag,
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
