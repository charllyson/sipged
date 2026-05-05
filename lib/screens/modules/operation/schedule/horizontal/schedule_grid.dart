import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_grid_row.dart';
import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_ghost_column.dart';
import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_legend.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_data.dart';
import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_road_debug.dart';

class ScheduleGrid extends StatelessWidget {
  const ScheduleGrid({
    super.key,
    required this.totalEstacas,
    required this.faixas,
    required this.execIndex,
    required this.servicoSelecionado,
    required this.legendWidth,
    required this.estacaWidth,
    required this.getSquareColor,
    required this.onTapSquare,
    required this.userLabelResolver,
    this.selectedByEstaca = const <int, Set<int>>{},
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.highlightColor = const Color(0xFF1E88E5),
    this.headerHeight = 25,
    this.rightGutter = 0,
  });

  final int totalEstacas;
  final List<ScheduleRoadData> faixas;
  final Map<int, Map<int, ScheduleRoadData>> execIndex;
  final String servicoSelecionado;
  final double legendWidth;
  final double estacaWidth;

  final Color Function(ScheduleRoadData e) getSquareColor;
  final void Function(ScheduleRoadData e) onTapSquare;
  final String Function(String? uid) userLabelResolver;

  final Map<int, Set<int>> selectedByEstaca;

  final void Function(int estaca, int faixaIndex)? onDragStart;
  final void Function(int estaca, int faixaIndex)? onDragUpdate;
  final VoidCallback? onDragEnd;

  final Color highlightColor;
  final double headerHeight;
  final double rightGutter;

  static const double kCellVPad = 0.5;

  int _faixaIndexFromDy(double dy) {
    dy -= headerHeight;
    if (dy < 0) return 0;

    double acc = 0;
    for (int i = 0; i < faixas.length; i++) {
      final seg = (faixas[i].altura ?? 20.0) + kCellVPad * 2;
      acc += seg;
      if (dy < acc) return i;
    }
    return faixas.length - 1;
  }

  bool _laneEnabledFor(int faixaIndex) {
    if (faixaIndex < 0 || faixaIndex >= faixas.length) return true;
    return faixas[faixaIndex].isAllowed(servicoSelecionado);
  }

  @override
  Widget build(BuildContext context) {
    ScheduleRoadDebug.rebuild(
      'Grid',
      'totalEstacas=$totalEstacas, faixas=${faixas.length}, execRows=${execIndex.length}',
    );

    const double gapLegendGrid = 8.0;
    const double itemHPad = 10.0;
    const double itemVPad = 12.0;

    final double columnHeight = (headerHeight +
        faixas.fold<double>(
          0,
              (acc, f) => acc + (f.altura ?? 20.0) + kCellVPad * 2,
        ))
        .roundToDouble();

    final double itemExtent = columnHeight + (itemVPad * 2);

    Color safeSquareColor(ScheduleRoadData e) {
      return _laneEnabledFor(e.faixaIndex)
          ? getSquareColor(e)
          : Colors.grey.shade200;
    }

    void safeOnTapSquare(ScheduleRoadData e) {
      if (!_laneEnabledFor(e.faixaIndex)) return;
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
        final int reaisPorLinha = (colsTotal - 1).clamp(1, 100000);
        final double cellWidth =
        colsTotal > 0 ? larguraUtilGrid / colsTotal : estacaWidth;
        final int linhas = (totalEstacas / reaisPorLinha).ceil();

        int estacaFromDx(double dx, int start) {
          final int col = (dx / cellWidth).floor();
          if (col <= 0) {
            return (start + 1).clamp(1, totalEstacas);
          }

          final estaca = start + col;
          final maxEstacaLinha = start + reaisPorLinha;
          return estaca.clamp(
            start + 1,
            math.min(maxEstacaLinha, totalEstacas),
          );
        }

        return ListView.builder(
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          addSemanticIndexes: false,
          cacheExtent: itemExtent * 6,
          itemCount: linhas,
          itemExtent: itemExtent,
          itemBuilder: (context, linhaIndex) {
            final start = linhaIndex * reaisPorLinha;
            final endExclusive = math.min(start + reaisPorLinha, totalEstacas);
            final count = endExclusive - start;

            final reais = List<Widget>.generate(count, (i) {
              final estacaNumero = start + i + 1;

              return SizedBox(
                width: cellWidth,
                height: columnHeight,
                child: RepaintBoundary(
                  child: ScheduleGridRow(
                    key: ValueKey(
                      'row_$estacaNumero'
                          '_sel:${selectedByEstaca[estacaNumero]?.join(",") ?? ""}'
                          '_exec:${execIndex[estacaNumero]?.length ?? 0}'
                          '_srv:$servicoSelecionado',
                    ),
                    estacaNumero: estacaNumero,
                    faixas: faixas,
                    execIndex: execIndex,
                    servicoSelecionado: servicoSelecionado,
                    getSquareColor: safeSquareColor,
                    onTapSquare: safeOnTapSquare,
                    userLabelResolver: userLabelResolver,
                    selectedFaixas: selectedByEstaca[estacaNumero] ?? const <int>{},
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
                  ScheduleGhostColumn(
                    w: cellWidth,
                    columnHeight: columnHeight,
                    headerHeight: headerHeight,
                    kCellVPad: kCellVPad,
                    faixas: faixas,
                  ),
                  ...reais,
                ],
              ),
            );

            final gridWithDrag = Listener(
              behavior: HitTestBehavior.deferToChild,
              onPointerDown: (ev) {
                if (onDragStart == null) return;
                final p = ev.localPosition;
                if (p.dy <= headerHeight) return;

                final faixa = _faixaIndexFromDy(p.dy);
                if (!_laneEnabledFor(faixa)) return;

                final estaca = estacaFromDx(p.dx, start);
                onDragStart!(estaca, faixa);
              },
              onPointerMove: (ev) {
                if (onDragUpdate == null) return;
                final p = ev.localPosition;
                if (p.dy <= headerHeight) return;

                final faixa = _faixaIndexFromDy(p.dy);
                if (!_laneEnabledFor(faixa)) return;

                final estaca = estacaFromDx(p.dx, start);
                onDragUpdate!(estaca, faixa);
              },
              onPointerUp: (_) => onDragEnd?.call(),
              onPointerCancel: (_) => onDragEnd?.call(),
              child: gridArea,
            );

            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: itemVPad,
                horizontal: itemHPad,
              ),
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
        );
      },
    );
  }
}