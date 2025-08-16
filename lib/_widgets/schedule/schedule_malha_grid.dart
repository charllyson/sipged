// malha_grid.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sisged/_widgets/schedule/schedule_estaca.dart';
import 'package:sisged/_widgets/schedule/schedule_legend.dart';
import '../../../../_datas/sectors/operation/calculationMemory/calculation_memory_data.dart';
import 'highway_class.dart';

class MalhaGrid extends StatelessWidget {
  const MalhaGrid({
    super.key,
    required this.totalEstacas,
    required this.faixas,
    required this.execucoes,
    required this.servicoSelecionado,
    required this.legendWidth,
    required this.estacaWidth,
    required this.getSquareColor,
    required this.onTapSquare,
    // seleção múltipla
    this.selectedKeys = const <String>{},
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.highlightColor = const Color(0xFF1E88E5),
    this.headerHeight = 25, // altura do número da estaca no topo da coluna
  });

  final int totalEstacas;
  final List<HighwayClass> faixas;
  final List<CalculationMemoryData> execucoes;
  final String servicoSelecionado;
  final double legendWidth;
  final double estacaWidth;
  final Color Function(CalculationMemoryData e) getSquareColor;
  final void Function(CalculationMemoryData e) onTapSquare;

  // === NOVO: seleção múltipla por arrasto ===
  final Set<String> selectedKeys;
  final void Function(int estaca, int faixaIndex)? onDragStart;
  final void Function(int estaca, int faixaIndex)? onDragUpdate;
  final VoidCallback? onDragEnd;
  final Color highlightColor;
  final double headerHeight;

  int _faixaIndexFromDy(double dy) {
    // dy começa no topo da área de colunas (o GestureDetector envolve só a grade)
    dy -= headerHeight; // pula o “número” da estaca
    if (dy < 0) return 0;
    double acc = 0;
    for (int i = 0; i < faixas.length; i++) {
      acc += faixas[i].altura;
      if (dy < acc) return i;
    }
    return faixas.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width - 32;
    final estacasPorLinha = ((largura - legendWidth) / estacaWidth).floor().clamp(1, 100000);
    final linhas = (totalEstacas / estacasPorLinha).ceil();

    final cellWidth = estacaWidth - 2.0; // o que você já usa na coluna

    return ListView.builder(
      itemCount: linhas,
      itemBuilder: (context, linhaIndex) {
        final start = linhaIndex * estacasPorLinha;           // índice base (0-based)
        final endExclusive = math.min(start + estacasPorLinha, totalEstacas);
        final count = endExclusive - start;

        final blocos = List.generate(count, (i) {
          final estacaNumero = start + i + 1; // estaca é 1-based
          return SizedBox(
            width: cellWidth,
            child: EstacaColumn(
              estacaNumero: estacaNumero,
              faixas: faixas,
              execucoes: execucoes,
              servicoSelecionado: servicoSelecionado,
              getSquareColor: getSquareColor,
              onTapSquare: onTapSquare,
              // NOVO: destaca se está no conjunto selecionado
              selectedKeys: selectedKeys,
              highlightColor: highlightColor,
            ),
          );
        });

        // área “pura” da grade (sem a legenda da esquerda),
        // onde vamos capturar o gesto de arrastar
        final gridArea = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            final dx = details.localPosition.dx; // relativo ao gridArea
            final dy = details.localPosition.dy;
            int col = (dx / cellWidth).floor();
            col = col.clamp(0, count - 1);
            final estaca = start + col + 1; // volta pra 1-based
            final faixa = _faixaIndexFromDy(dy);
            onDragStart?.call(estaca, faixa);
          },
          onPanUpdate: (details) {
            final dx = details.localPosition.dx;
            final dy = details.localPosition.dy;
            int col = (dx / cellWidth).floor();
            col = col.clamp(0, count - 1);
            final estaca = start + col + 1;
            final faixa = _faixaIndexFromDy(dy);
            onDragUpdate?.call(estaca, faixa);
          },
          onPanEnd: (_) => onDragEnd?.call(),
          child: Wrap(spacing: 0, runSpacing: 0, children: blocos),
        );

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Legend(faixas: faixas),
              const SizedBox(width: 8),
              Expanded(child: gridArea),
            ],
          ),
        );
      },
    );
  }
}
