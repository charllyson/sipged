import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'list_demand_table.dart';

// DFD / Edital / Publicação (apenas os DATA)
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/5Edital/edital_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';

typedef DemandNavigationCallback = void Function(
    BuildContext context,
    ProcessData contract,
    );

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

    // caches já carregados
    required this.dfdByContractId,
    required this.editalByContractId,
    required this.pubByContractId,
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

  // 🔥 caches de metadados por contrato
  final Map<String, DfdData?> dfdByContractId;
  final Map<String, EditalData?> editalByContractId;
  final Map<String, PublicacaoExtratoData?> pubByContractId;

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
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.blue.withValues(alpha: 0.10),
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

            // 🔥 passa os caches para a tabela
            dfdByContractId: dfdByContractId,
            editalByContractId: editalByContractId,
            pubByContractId: pubByContractId,
          ),
        ],
      ),
    );
  }
}
