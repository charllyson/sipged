import 'package:flutter/material.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_widgets/table/simple/simple_table_changed.dart';
import 'package:siged/_blocs/process/hiring/5Edital/company_data.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import '../../alerts/alert_validity.dart';

typedef ContractNavigationCallback = void Function(BuildContext context, ProcessData contract);

class ListDemandTable extends StatelessWidget {
  final List<ProcessData> listContractData;
  final BoxConstraints constraints;
  final String statusLabel;
  final String statusFilter;
  final int? sortColumnIndex;
  final bool isAscending;
  final void Function(int, String Function(ProcessData)) onSort;
  final void Function(ProcessData) onDelete;
  final ContractNavigationCallback onTapItem;

  const ListDemandTable({
    super.key,
    required this.listContractData,
    required this.constraints,
    required this.statusLabel,
    required this.statusFilter,
    required this.sortColumnIndex,
    required this.isAscending,
    required this.onSort,
    required this.onDelete,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final sortedContracts = List<ProcessData>.from(listContractData)..sort((a, b) {
      final statusA = a.status?.toUpperCase() ?? '';
      final statusB = b.status?.toUpperCase() ?? '';
      final prioridadeA = DfdData.priorityStatus[statusA] ?? 99;
      final prioridadeB = DfdData.priorityStatus[statusB] ?? 99;
      if (prioridadeA != prioridadeB) return prioridadeA.compareTo(prioridadeB);
      return (a.summarySubject ?? '').compareTo(b.summarySubject ?? '');
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 12),
          SimpleTableChanged<ProcessData>(
            listData: sortedContracts,
            constraints: constraints,
            sortColumnIndex: sortColumnIndex,
            isAscending: isAscending,
            sortField: (d) => d.contractNumber ?? '',
            onSort: onSort,
            onTapItem: (contractData) => onTapItem(context, contractData),
            onDelete: onDelete,

            // ---- LEADING (coluna extra à esquerda)
            leadingCellTitle: 'ALERTAS',
            leadingCell: (data) => AlertValidity(contract: data),

            // ---- COLUNAS DE DADOS
            columnTitles: const [
              'CONTRATO', 'OBRA', 'REGIÃO', 'EMPRESA', 'Nº PROCESSO',
            ],
            columnGetters: [
                  (d) => d.contractNumber ?? '',
                  (d) => d.summarySubject ?? '',
                  (d) => d.region ?? '',
                  (d) => d.companyLeader ?? '',
                  (d) => d.numberProcess ?? '',
            ],

            // ⚠️ 5 (dados) + 1 (leading) + 1 (delete) = 7 larguras
            columnWidths: const [
              120, // leading: ALERTAS
              130, // CONTRATO
              260, // OBRA
              100, // REGIÃO
              200, // EMPRESA
              190, // Nº PROCESSO
              100,  // delete (ícone)
            ],

            // ⚠️ Um alinhamento por título (apenas dados): 5 itens
            columnTextAligns: const [
              TextAlign.center, // CONTRATO
              TextAlign.left,   // OBRA
              TextAlign.center, // REGIÃO
              TextAlign.center,   // EMPRESA
              TextAlign.center, // Nº PROCESSO
            ],

            groupLabel: 'SERVIÇO',
            groupBy: (d) => d.services ?? 'Sem serviço definido',
          ),

        ],
      ),
    );
  }
}
