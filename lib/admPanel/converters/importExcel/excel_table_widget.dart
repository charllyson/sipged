import 'package:flutter/material.dart';
import 'header_tipo_dropdown.dart';
import 'tipo_dado_enum.dart';

class ExcelTableWidget extends StatelessWidget {
  final List<Map<String, dynamic>> previewLinhas;
  final List<String> colunas;
  final Map<String, bool> colunasSelecionadas;
  final Map<String, TipoDado> tiposPorCampo;
  final Map<int, bool> linhasSelecionadas;
  final void Function(int index, bool? selected) onSelectLinha;
  final void Function(String coluna, bool? selected) onToggleColuna;
  final void Function(String coluna, TipoDado tipo) onChangeTipo;

  final int paginaAtual;
  final int linhasPorPagina;

  const ExcelTableWidget({
    super.key,
    required this.previewLinhas,
    required this.colunas,
    required this.colunasSelecionadas,
    required this.tiposPorCampo,
    required this.linhasSelecionadas,
    required this.onSelectLinha,
    required this.onToggleColuna,
    required this.onChangeTipo,
    required this.paginaAtual,
    required this.linhasPorPagina,
  });

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: colunas.map((coluna) {
        final tipoAtual = tiposPorCampo[coluna] ?? TipoDado.string;

        return DataColumn(
          label: HeaderTipoDropdown(
            coluna: coluna,
            tipoAtual: tipoAtual,
            isSelecionado: colunasSelecionadas[coluna] ?? true,
            onCheckboxChanged: (val) => onToggleColuna(coluna, val),
            onChanged: (tipo) {
              if (tipo != null) {
                onChangeTipo(coluna, tipo);
              }
            },
          ),
        );
      }).toList(),
      rows: List.generate(previewLinhas.length, (indexLocal) {
        final indexGlobal = paginaAtual * linhasPorPagina + indexLocal;
        final linha = previewLinhas[indexLocal];

        return DataRow(
          selected: linhasSelecionadas[indexGlobal] ?? false,
          onSelectChanged: (val) => onSelectLinha(indexGlobal, val),
          cells: colunas.map((coluna) {
            final valor = linha[coluna];
            return DataCell(
              colunasSelecionadas[coluna] == true
                  ? Text(valor?.toString() ?? '')
                  : const Text('-', style: TextStyle(color: Colors.grey)),
            );
          }).toList(),
        );
      }),
    );
  }
}
