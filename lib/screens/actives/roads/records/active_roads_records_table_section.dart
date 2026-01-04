import 'package:flutter/material.dart';

import 'package:siged/_blocs/actives/roads/active_roads_data.dart';
import 'package:siged/_widgets/table/simple/simple_table_changed.dart';

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
  ActiveRoadsData? _selected;

  @override
  Widget build(BuildContext context) {
    final data = widget.items;
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('Nenhuma rodovia encontrada neste grupo.'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SimpleTableChanged<ActiveRoadsData>(
        listData: data,
        constraints: widget.constraints,

        // linha selecionada
        selectedItem: _selected,

        sortColumnIndex: 0,
        isAscending: true,
        sortField: (r) => (r.acronym ?? '').toUpperCase(),
        onSort: (_, __) {},

        columnTitles: const [
          'CÓDIGO',
          'COMPONENTE',
          'INÍCIO DO TRECHO',
          'FIM DO TRECHO',
          'REGIÃO',
          'EXTENSÃO (km)',
          'STATUS',
        ],
        columnGetters: [
          (r) => r.roadCode ?? '-',
          (r) => r.segmentType ?? '-',
          (r) => r.initialSegment?.toString() ?? '-',
          (r) => r.finalSegment?.toString() ?? '-',
          (r) => r.regional ?? (r.metadata?['regional']?.toString() ?? '-'),
          (r) => r.extension.toString(),
          (r) => r.stateSurface ?? '-',
        ],

        columnWidths: const [
          100, // CÓDIGO
          100, // COMPONENTE
          200, // INÍCIO
          200, // FIM
          120, // REGIÃO
          130, // EXTENSÃO
          140, // STATUS
          56,  // DELETE
        ],

        columnTextAligns: const [
          TextAlign.center, // CÓDIGO
          TextAlign.center, // COMPONENTE
          TextAlign.start, // INÍCIO
          TextAlign.start, // FIM
          TextAlign.center, // REGIÃO
          TextAlign.center, // EXTENSÃO
          TextAlign.center, // STATUS
          TextAlign.center, // DELETE
        ],

        onTapItem: (item) {
          setState(() => _selected = item);
          widget.onTapItem(item);
        },

        onDelete: (item) {
          final id = item.id;
          if (id != null && id.isNotEmpty) {
            widget.onDelete(id);
          }
        },

        groupBy: null,
        groupLabel: null,
      ),
    );
  }
}
