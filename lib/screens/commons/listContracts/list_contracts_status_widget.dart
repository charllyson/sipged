import 'package:flutter/material.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contract_data.dart';
import 'list_contracts_controller.dart';
import 'list_contracts_table_widget.dart';

typedef ContractNavigationCallback = void Function(BuildContext context, ContractData contract);

class ContractStatusExpandable extends StatelessWidget {
  const ContractStatusExpandable({
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

    // compat (não usados p/ estado)
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });

  final String title;
  final String statusKey;
  final List<ContractData> items;

  final BoxConstraints constraints;
  final int? sortColumnIndex;
  final bool isAscending;
  final void Function(int, String Function(ContractData)) onSort;
  final Future<void> Function(ContractData) onDelete;
  final ContractNavigationCallback onTapItem;

  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  Widget build(BuildContext context) {
    final controller = ListContractsController.of(context);
    final k = statusKey.trim().toUpperCase();
    final total = items.length;
    final expandedNow = controller.isExpanded(k);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        // 🔒 key estável (não depende do estado)
        key: ValueKey('tile_$k'),
        controller: controller.tileControllerFor(k), // deve ser estável por k
        initiallyExpanded: expandedNow,
        // mantém subárvore viva mesmo recolhida
        maintainState: true,

        onExpansionChanged: (open) {
          controller.setExpanded(k, open); // não recrie controller aqui
          onExpansionChanged?.call(open);
        },

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
          ContractsTableWidget(
            // ✅ key de PageStorage estável
            key: PageStorageKey<String>('table_scroll_$k'),
            listContractData: items,
            constraints: constraints,
            statusLabel: title,
            statusFilter: k,
            sortColumnIndex: sortColumnIndex,
            isAscending: isAscending,
            onSort: onSort,
            onDelete: (item) async => onDelete(item),
            onTapItem: onTapItem,
          ),
        ],
      ),
    );
  }
}
