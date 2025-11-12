// lib/screens/commons/listContracts/list_demand_status.dart
import 'package:flutter/material.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import 'list_demand_table.dart';

typedef DemandNavigationCallback = void Function(BuildContext context, ProcessData contract);

class ListDemandStatus extends StatelessWidget {
  const ListDemandStatus({
    super.key,
    required this.title,
    required this.statusKey,
    required this.items,
    // props da tabela
    required this.constraints,
    required this.sortColumnIndex,
    required this.isAscending,
    required this.onSort,
    required this.onDelete,
    required this.onTapItem,

    // controle de expansão
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });

  final String title;
  final String statusKey;
  final List<ProcessData> items;

  final BoxConstraints constraints;
  final int? sortColumnIndex;
  final bool isAscending;
  final void Function(int, String Function(ProcessData)) onSort;
  final Future<void> Function(ProcessData) onDelete;
  final DemandNavigationCallback onTapItem;

  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  String _norm(String k) => k.trim().toUpperCase();

  @override
  Widget build(BuildContext context) {
    final k = _norm(statusKey);
    final total = items.length;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: ValueKey('tile_$k'),
        initiallyExpanded: initiallyExpanded,
        maintainState: true,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.only(bottom: 12),

        title: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.blue.withOpacity(0.10),
              ),
              child: Text('$total'),
            ),
          ],
        ),

        children: [
          ListDemandTable(
            key: PageStorageKey<String>('table_scroll_$k'),
            listContractData: items,
            constraints: constraints,
            statusLabel: title,
            statusFilter: k,
            sortColumnIndex: sortColumnIndex,
            isAscending: isAscending,
            onSort: onSort,
            onDelete: onDelete,
            onTapItem: onTapItem,
          ),
        ],
      ),
    );
  }
}
