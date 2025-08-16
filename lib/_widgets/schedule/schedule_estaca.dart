// schedule_estaca.dart
import 'package:flutter/material.dart';
import 'package:sisged/_widgets/schedule/schedule_malha_cells.dart';
import '../../../../_datas/sectors/operation/calculationMemory/calculation_memory_data.dart';
import 'highway_class.dart';

class EstacaColumn extends StatelessWidget {
  final int estacaNumero;
  final List<HighwayClass> faixas;
  final List<CalculationMemoryData> execucoes;
  final String servicoSelecionado;
  final Color Function(CalculationMemoryData) getSquareColor;
  final void Function(CalculationMemoryData) onTapSquare;

  // NOVO
  final Set<String> selectedKeys;
  final Color highlightColor;

  const EstacaColumn({
    super.key,
    required this.estacaNumero,
    required this.faixas,
    required this.execucoes,
    required this.servicoSelecionado,
    required this.getSquareColor,
    required this.onTapSquare,
    this.selectedKeys = const <String>{},
    this.highlightColor = const Color(0xFF1E88E5),
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

    return Column(
      children: [
        SizedBox(
          height: 25,
          child: Center(
            child: isMultiploDe10
                ? RotatedBox(quarterTurns: 3, child: Text('$estacaNumero', style: numeroStyle))
                : Text('$estacaNumero', style: numeroStyle),
          ),
        ),
        ...List.generate(faixas.length, (i) {
          final faixa = faixas[i];

          final exec = execucoes.firstWhere(
                (e) => e.numero == estacaNumero && e.faixaIndex == i,
            orElse: () => CalculationMemoryData(
              numero: estacaNumero,
              faixaIndex: i,
              tipo: servicoSelecionado,
              status: '',
            ),
          );

          final key = '${exec.numero}_${exec.faixaIndex}';
          final isSelected = selectedKeys.contains(key);

          return MalhaCell(
            execucao: exec,
            altura: faixa.altura,
            cor: getSquareColor(exec),
            onTap: () => onTapSquare(exec),
            isSelected: isSelected,
            highlightColor: highlightColor,
          );
        }),
      ],
    );
  }
}
