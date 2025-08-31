import 'package:flutter/material.dart';
import 'package:siged/_widgets/table/simple_table_changed.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_rules.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'list_contracts_validity_icon.dart';

typedef ContractNavigationCallback = void Function(BuildContext context, ContractData contract);

class ContractsTableWidget extends StatelessWidget {
  final List<ContractData> listContractData;
  final BoxConstraints constraints;
  final String statusLabel;
  final String statusFilter;
  final int? sortColumnIndex;
  final bool isAscending;
  final void Function(int, String Function(ContractData)) onSort;
  final void Function(ContractData) onDelete;
  final ContractNavigationCallback onTapItem;

  const ContractsTableWidget({
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
    final sortedContracts = List<ContractData>.from(listContractData)..sort((a, b) {
      final statusA = a.contractStatus?.toUpperCase() ?? '';
      final statusB = b.contractStatus?.toUpperCase() ?? '';
      final prioridadeA = ContractRules.priorityStatus[statusA] ?? 99;
      final prioridadeB = ContractRules.priorityStatus[statusB] ?? 99;
      if (prioridadeA != prioridadeB) return prioridadeA.compareTo(prioridadeB);
      return (a.summarySubjectContract ?? '').compareTo(b.summarySubjectContract ?? '');
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 12),
          SimpleTableChanged<ContractData>(
            listData: sortedContracts,
            constraints: constraints,
            sortColumnIndex: sortColumnIndex,
            isAscending: isAscending,
            sortField: (d) => d.contractNumber ?? '',
            onSort: onSort,
            onTapItem: (contractData) => onTapItem(context, contractData),
            onDelete: onDelete,

            // ---- LEADING (coluna extra à esquerda)
            leadingCellTitle: 'VALIDADE',
            leadingCell: (data) => ContractValidityIcon(contract: data),

            // ---- COLUNAS DE DADOS
            columnTitles: const [
              'CONTRATO', 'OBRA', 'REGIÃO', 'EMPRESA', 'Nº PROCESSO',
            ],
            columnGetters: [
                  (d) => d.contractNumber ?? '',
                  (d) => d.summarySubjectContract ?? '',
                  (d) => d.regionOfState ?? '',
                  (d) => d.companyLeader ?? '',
                  (d) => d.contractNumberProcess ?? '',
            ],

            // ⚠️ 5 (dados) + 1 (leading) + 1 (delete) = 7 larguras
            columnWidths: const [
              120, // leading: VALIDADE
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
            groupBy: (d) => d.contractServices ?? 'Sem serviço definido',
          ),

        ],
      ),
    );
  }
}
