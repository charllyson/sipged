// lib/screens/modules/actives/oaes/records/list_oaes_table.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

import 'list_oaes_page.dart' show OaeScoreHelper;

typedef OaeTapCallback = void Function(ActiveOaesData oae);
typedef OaeDeleteCallback = void Function(String oaeId);
typedef OaeSortCallback = void Function(int columnIndex, bool ascending);

class ListOaesTable extends StatefulWidget {
  const ListOaesTable({
    super.key,
    required this.items,
    required this.constraints,
    required this.onTapItem,
    required this.onDelete,
    required this.onSort,
    this.sortColumnIndex,
    this.isAscending = true,
  });

  final List<ActiveOaesData> items;
  final BoxConstraints constraints;
  final OaeTapCallback onTapItem;
  final OaeDeleteCallback onDelete;

  final OaeSortCallback onSort;
  final int? sortColumnIndex;
  final bool isAscending;

  @override
  State<ListOaesTable> createState() => _ListOaesTableState();
}

class _ListOaesTableState extends State<ListOaesTable> {
  String? _selectedKey;

  String _txt(dynamic value) {
    if (value == null) return '-';

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') return '-';

    return text;
  }

  String _scoreText(ActiveOaesData oae) {
    final score = oae.score;

    if (score == null) return '-';

    final normalized = OaeScoreHelper.normalizeScore(score);

    return ActiveOaesData.getLabelByNota(normalized);
  }

  String _itemKey(ActiveOaesData oae) {
    final id = (oae.id ?? '').trim();

    if (id.isNotEmpty) return id;

    return [
      _txt(oae.identificationName),
      _txt(oae.region),
      _txt(oae.road),
      _txt(oae.structureType),
      _txt(oae.relatedContracts),
    ].join('|');
  }

  Widget _buildStatusCell(ActiveOaesData oae) {
    final normalized = OaeScoreHelper.normalizeScore(oae.score);

    final color = ActiveOaesData.getColorByNota(
      normalized >= 0 ? normalized.toDouble() : -1,
    );

    final label = ActiveOaesData.getLabelByNota(normalized);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 88,
          maxWidth: 160,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: PagedTableChanged<ActiveOaesData>(
        listData: data,
        getKey: _itemKey,
        selectedKey: _selectedKey,
        keepSelectionInternally: false,
        enableRowTapSelection: true,
        enablePagination: false,
        initialRowsPerPage: 10,
        rowsPerPageOptions: const [10, 25, 50, 100],
        sortColumnIndex: widget.sortColumnIndex,
        sortAscending: widget.isAscending,
        minTableWidth: 1116,
        defaultColumnWidth: 150,
        actionsColumnWidth: 56,
        colorHeadTable: const Color(0xFF091D68),
        colorHeadTableText: Colors.white,
        headingRowHeight: 40,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 56,

        // PagedTableChanged espera 3 parâmetros.
        onSort: (
            int columnIndex,
            bool ascending,
            String Function(ActiveOaesData) getter,
            ) {
          widget.onSort(columnIndex, ascending);
        },

        onTapItem: (oae) {
          setState(() {
            _selectedKey = _itemKey(oae);
          });

          widget.onTapItem(oae);
        },
        onDelete: (oae) {
          final id = (oae.id ?? '').trim();

          if (id.isNotEmpty) {
            widget.onDelete(id);
          }
        },
        columns: [
          PagedColum<ActiveOaesData>(
            title: 'STATUS',
            getter: _scoreText,
            cellBuilder: _buildStatusCell,
            textAlign: TextAlign.left,
            width: 150,
          ),
          PagedColum<ActiveOaesData>(
            title: 'IDENTIFICAÇÃO',
            getter: (oae) => _txt(oae.identificationName),
            textAlign: TextAlign.left,
            width: 260,
          ),
          PagedColum<ActiveOaesData>(
            title: 'REGIÃO',
            getter: (oae) => _txt(oae.region),
            textAlign: TextAlign.left,
            width: 120,
          ),
          PagedColum<ActiveOaesData>(
            title: 'RODOVIA',
            getter: (oae) => _txt(oae.road),
            textAlign: TextAlign.left,
            width: 100,
          ),
          PagedColum<ActiveOaesData>(
            title: 'TIPO DE ESTRUTURA',
            getter: (oae) => _txt(oae.structureType),
            textAlign: TextAlign.left,
            width: 250,
          ),
          PagedColum<ActiveOaesData>(
            title: 'CONTRATOS RELACIONADOS',
            getter: (oae) => _txt(oae.relatedContracts),
            textAlign: TextAlign.left,
            width: 250,
          ),
        ],
      ),
    );
  }
}