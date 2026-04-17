// lib/screens/modules/actives/roads/list_roads_table.dart
import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

typedef RoadTapCallback = void Function(ActiveRoadsData road);
typedef RoadDeleteCallback = void Function(String roadId);

class ListRoadsTable extends StatefulWidget {
  const ListRoadsTable({
    super.key,
    required this.items,
    required this.constraints,
    required this.onTapItem,
    required this.onDelete,
  });

  final List<ActiveRoadsData> items;
  final BoxConstraints constraints;
  final RoadTapCallback onTapItem;
  final RoadDeleteCallback onDelete;

  @override
  State<ListRoadsTable> createState() => _ListRoadsTableState();
}

class _ListRoadsTableState extends State<ListRoadsTable> {
  String? _selectedKey;

  String _txt(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty || v.toLowerCase() == 'null') return '-';
    return v;
  }

  String _num(dynamic value) {
    if (value == null) return '-';
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return '-';
    return text;
  }

  String _regionalOf(ActiveRoadsData road) {
    return _txt(
      road.regional ?? road.metadata?['regional']?.toString(),
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
      _txt(road.stateSurface),
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

    return PagedTableChanged<ActiveRoadsData>(
      listData: data,
      getKey: _itemKey,
      selectedKey: _selectedKey,
      keepSelectionInternally: false,
      enableRowTapSelection: true,
      enablePagination: false,
      initialRowsPerPage: 10,
      rowsPerPageOptions: const [10, 25, 50, 100],
      sortColumnIndex: 0,
      sortAscending: true,
      minTableWidth: 1046,
      defaultColumnWidth: 150,
      actionsColumnWidth: 56,
      colorHeadTable: const Color(0xFF091D68),
      colorHeadTableText: Colors.white,
      headingRowHeight: 40,
      dataRowMinHeight: 40,
      dataRowMaxHeight: 56,
      onTapItem: (item) {
        setState(() => _selectedKey = _itemKey(item));
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
          width: 100,
        ),
        PagedColum<ActiveRoadsData>(
          title: 'INÍCIO DO TRECHO',
          getter: (r) => _num(r.initialSegment),
          textAlign: TextAlign.left,
          width: 180,
        ),
        PagedColum<ActiveRoadsData>(
          title: 'FIM DO TRECHO',
          getter: (r) => _num(r.finalSegment),
          textAlign: TextAlign.left,
          width: 180,
        ),
        PagedColum<ActiveRoadsData>(
          title: 'REGIÃO',
          getter: (r) => _regionalOf(r),
          textAlign: TextAlign.center,
          width: 120,
        ),
        PagedColum<ActiveRoadsData>(
          title: 'EXTENSÃO (km)',
          getter: (r) => _num(r.extension),
          textAlign: TextAlign.center,
          width: 130,
        ),
        PagedColum<ActiveRoadsData>(
          title: 'STATUS',
          getter: (r) => _txt(r.stateSurface),
          textAlign: TextAlign.center,
          width: 160,
        ),
      ],
    );
  }
}