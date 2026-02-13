// lib/screens/modules/actives/oaes/list_oaes_table.dart
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/table/simple/simple_table_changed.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';

import 'list_oaes_page.dart' show OaeScoreHelper;

typedef OaeTapCallback = void Function(ActiveOaesData oae);
typedef OaeDeleteCallback = void Function(String oaeId);

class ListOaesTable extends StatefulWidget {
  const ListOaesTable({
    super.key,
    required this.items,
    required this.constraints,
    required this.onTapItem,
    required this.onDelete,
  });

  final List<ActiveOaesData> items;
  final BoxConstraints constraints;

  final OaeTapCallback onTapItem;
  final OaeDeleteCallback onDelete;

  @override
  State<ListOaesTable> createState() => _ListOaesTableState();
}

class _ListOaesTableState extends State<ListOaesTable> {
  ActiveOaesData? _selected;

  String _txt(String? v) {
    final s = (v ?? '').trim();
    return s.isEmpty ? '-' : s;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.items;
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('Nenhuma OAE encontrada neste grupo.'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SimpleTableChanged<ActiveOaesData>(
        listData: data,
        constraints: widget.constraints,
        // linha selecionada
        selectedItem: _selected,

        // ordenação base (por identificação)
        sortColumnIndex: 0,
        isAscending: true,
        sortField: (o) => (_txt(o.identificationName)).toUpperCase(),
        onSort: (_, _) {},
        leadingCellTitle: 'STATUS',
        leadingCell: (o) {
          final normalized = OaeScoreHelper.normalizeScore(o.score);
          final color = ActiveOaesData.getColorByNota(
            normalized >= 0 ? normalized.toDouble() : -1,
          );
          final label = ActiveOaesData.getLabelByNota(normalized);

          return Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              normalized >= 0 ? label : label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          );
        },

        // ====== COLUNAS DE DADOS ======
        columnTitles: const [
          'IDENTIFICAÇÃO',
          'REGIÃO',
          'RODOVIA',
          'TIPO DE ESTRUTURA',
          'CONTRATOS RELACIONADOS',
        ],
        columnGetters: [
              (o) => _txt(o.identificationName),
              (o) => _txt(o.region),
              (o) => _txt(o.road),
              (o) => _txt(o.estructureType),
              (o) => _txt(o.relatedContracts),
        ],

        // IMPORTANTE: 1 (leading NOTA) + 6 colunas + 1 delete = 8 larguras
        columnWidths: const [
          120, // NOTA (leading)
          260, // IDENTIFICAÇÃO
          140, // REGIÃO
          120, // RODOVIA
          200, // TIPO DE ESTRUTURA
          220, // CONTRATOS RELACIONADOS
          56,  // delete
        ],

        // alinhamentos só das 6 colunas de dados
        columnTextAligns: const [
          TextAlign.left,   // IDENTIFICAÇÃO
          TextAlign.center, // REGIÃO
          TextAlign.center, // RODOVIA
          TextAlign.center, // TIPO DE ESTRUTURA
          TextAlign.left,   // CONTRATOS RELACIONADOS
        ],

        // clique na linha
        onTapItem: (o) {
          setState(() => _selected = o);
          widget.onTapItem(o);
        },

        // deletar
        onDelete: (o) {
          final id = o.id;
          if (id != null && id.isNotEmpty) {
            widget.onDelete(id);
          }
        },

        // sem agrupamento extra aqui
        groupBy: null,
        groupLabel: null,
      ),
    );
  }
}
