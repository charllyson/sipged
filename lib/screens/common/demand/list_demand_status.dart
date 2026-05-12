// lib/screens/modules/contracts/hiring/list/list_demand_status.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/5Edital/edital_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';

import 'list_demand_table.dart';

typedef DemandNavigationCallback = void Function(
    BuildContext context,
    ContractData contract,
    );

class ListDemandStatus extends StatelessWidget {
  const ListDemandStatus({
    super.key,
    required this.title,
    required this.statusKey,
    required this.items,
    required this.constraints,
    required this.sortColumnIndex,
    required this.isAscending,
    required this.onSort,
    required this.onDelete,
    required this.onTapItem,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    required this.dfdByContractId,
    required this.editalByContractId,
    required this.pubByContractId,
  });

  final String title;
  final String statusKey;
  final List<ContractData> items;

  final BoxConstraints constraints;
  final int? sortColumnIndex;
  final bool isAscending;
  final void Function(int, String Function(ContractData)) onSort;
  final Future<void> Function(ContractData) onDelete;
  final DemandNavigationCallback onTapItem;

  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  final Map<String, DfdData?> dfdByContractId;
  final Map<String, EditalData?> editalByContractId;
  final Map<String, PublicacaoExtratoData?> pubByContractId;

  String _norm(String value) {
    return value.trim().toUpperCase();
  }

  Color _badgeColor(String key) {
    switch (_norm(key)) {
      case 'TODOS':
        return Colors.blue;
      case 'A INICIAR':
        return Colors.orange;
      case 'EM ANDAMENTO':
        return Colors.indigo;
      case 'CONCLUÍDO':
      case 'CONCLUIDO':
        return Colors.green;
      case 'SEM STATUS':
        return Colors.grey;
      case 'EM PROJETO':
        return Colors.deepPurple;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _iconForStatus(String key) {
    switch (_norm(key)) {
      case 'TODOS':
        return Icons.list_alt_rounded;
      case 'A INICIAR':
        return Icons.flag_circle_rounded;
      case 'EM ANDAMENTO':
        return Icons.timelapse_rounded;
      case 'CONCLUÍDO':
      case 'CONCLUIDO':
        return Icons.check_circle_rounded;
      case 'SEM STATUS':
        return Icons.help_outline_rounded;
      case 'EM PROJETO':
        return Icons.assignment_outlined;
      default:
        return Icons.folder_copy_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = _norm(statusKey);
    final total = items.length;
    final color = _badgeColor(key);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.86),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: color.withValues(alpha: 0.08),
          highlightColor: color.withValues(alpha: 0.05),
        ),
        child: ExpansionTile(
          key: PageStorageKey<String>('demand_status_tile_$key'),
          initiallyExpanded: initiallyExpanded,
          maintainState: true,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _iconForStatus(key),
              color: color,
              size: 21,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            total == 1 ? '1 demanda' : '$total demandas',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: color.withValues(alpha: 0.12),
              border: Border.all(
                color: color.withValues(alpha: 0.24),
              ),
            ),
            child: Text(
              '$total',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          children: [
            if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: const Text(
                  'Nenhuma demanda nesta seção.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListDemandTable(
                    key: PageStorageKey<String>('table_scroll_$key'),
                    listContractData: items,
                    constraints: constraints,
                    statusLabel: title,
                    statusFilter: key,
                    sortColumnIndex: sortColumnIndex,
                    isAscending: isAscending,
                    onSort: onSort,
                    onDelete: onDelete,
                    onTapItem: onTapItem,
                    dfdByContractId: dfdByContractId,
                    editalByContractId: editalByContractId,
                    pubByContractId: pubByContractId,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}