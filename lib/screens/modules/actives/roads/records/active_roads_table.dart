import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

typedef RoadTapCallback = void Function(ActiveRoadsData road);
typedef RoadDeleteCallback = void Function(String roadId);
typedef RoadSortCallback = void Function(int columnIndex, bool ascending);

class ListRoadsTable extends StatefulWidget {
  const ListRoadsTable({
    super.key,
    required this.items,
    required this.constraints,
    required this.onTapItem,
    required this.onDelete,
    required this.onSort,
    this.sortColumnIndex,
    this.isAscending = true,
  });

  final List<ActiveRoadsData> items;
  final BoxConstraints constraints;
  final RoadTapCallback onTapItem;
  final RoadDeleteCallback onDelete;

  final RoadSortCallback onSort;
  final int? sortColumnIndex;
  final bool isAscending;

  @override
  State<ListRoadsTable> createState() => _ListRoadsTableState();
}

class _ListRoadsTableState extends State<ListRoadsTable> {
  String? _selectedKey;

  String _txt(dynamic value) {
    if (value == null) return '-';

    final v = value.toString().trim();

    if (v.isEmpty || v.toLowerCase() == 'null') return '-';

    return v;
  }

  String _num(dynamic value) {
    if (value == null) return '-';
    if (value is bool) return '-';

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') return '-';

    return text;
  }

  String _km(dynamic value) {
    if (value == null) return '-';
    if (value is bool) return '-';

    double? number;

    if (value is num) {
      number = value.toDouble();
    } else if (value is String) {
      final raw = value.trim();

      if (raw.isEmpty || raw.toLowerCase() == 'null') return '-';

      var clean = raw
          .replaceAll('km', '')
          .replaceAll('KM', '')
          .replaceAll(RegExp(r'[^\d,.\-]'), '');

      final hasComma = clean.contains(',');
      final hasDot = clean.contains('.');

      if (hasComma && hasDot) {
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      } else if (hasComma) {
        clean = clean.replaceAll(',', '.');
      }

      number = double.tryParse(clean);
    }

    if (number == null) return '-';

    var text = number.toStringAsFixed(3);

    while (text.contains('.') && (text.endsWith('0') || text.endsWith('.'))) {
      text = text.substring(0, text.length - 1);
    }

    return text;
  }

  String _regionalOf(ActiveRoadsData road) {
    return _txt(
      road.regional ?? road.metadata?['regional'],
    );
  }

  String _surfaceOf(ActiveRoadsData road) {
    return _txt(
      road.stateSurface ?? road.surface ?? road.state,
    );
  }

  String _itemKey(ActiveRoadsData road) {
    final id = (road.id ?? '').trim();

    if (id.isNotEmpty) return id;

    return [
      _txt(road.roadCode),
      _txt(road.segmentType),
      _num(road.initialSegment),
      _num(road.finalSegment),
      _regionalOf(road),
      _num(road.extension),
      _surfaceOf(road),
    ].join('|');
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.items;

    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('Nenhuma rodovia encontrada neste grupo.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: PagedTableChanged<ActiveRoadsData>(
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
        minTableWidth: 1046,
        defaultColumnWidth: 150,
        actionsColumnWidth: 56,
        colorHeadTable: const Color(0xFF091D68),
        colorHeadTableText: Colors.white,
        headingRowHeight: 40,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 56,

        // Ajuste principal: PagedTableChanged espera 3 parâmetros.
        onSort: (
            int columnIndex,
            bool ascending,
            String Function(ActiveRoadsData) getter,
            ) {
          widget.onSort(columnIndex, ascending);
        },

        onTapItem: (item) {
          setState(() {
            _selectedKey = _itemKey(item);
          });

          widget.onTapItem(item);
        },
        onDelete: (item) {
          final id = (item.id ?? '').trim();

          if (id.isNotEmpty) {
            widget.onDelete(id);
          }
        },
        columns: [
          PagedColum<ActiveRoadsData>(
            title: 'CÓDIGO',
            getter: (r) => _txt(r.roadCode),
            textAlign: TextAlign.center,
            width: 120,
          ),
          PagedColum<ActiveRoadsData>(
            title: 'COMPONENTE',
            getter: (r) => _txt(r.segmentType),
            textAlign: TextAlign.center,
            width: 120,
          ),
          PagedColum<ActiveRoadsData>(
            title: 'INÍCIO DO TRECHO',
            getter: (r) => _txt(r.initialSegment),
            textAlign: TextAlign.left,
            width: 180,
          ),
          PagedColum<ActiveRoadsData>(
            title: 'FIM DO TRECHO',
            getter: (r) => _txt(r.finalSegment),
            textAlign: TextAlign.left,
            width: 180,
          ),
          PagedColum<ActiveRoadsData>(
            title: 'REGIÃO',
            getter: _regionalOf,
            textAlign: TextAlign.center,
            width: 140,
          ),
          PagedColum<ActiveRoadsData>(
            title: 'EXTENSÃO (km)',
            getter: (r) => _km(r.extension),
            textAlign: TextAlign.center,
            width: 130,
          ),
          PagedColum<ActiveRoadsData>(
            title: 'STATUS',
            getter: _surfaceOf,
            textAlign: TextAlign.center,
            width: 160,
          ),
        ],
      ),
    );
  }
}