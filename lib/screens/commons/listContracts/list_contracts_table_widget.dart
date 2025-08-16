import 'package:flutter/material.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contract_style.dart';
import '../../../../../_widgets/table/simple_table_changed.dart';
import '../../../_blocs/documents/contracts/validity/validity_bloc.dart';
import '../../../_datas/documents/contracts/contracts/contract_rules.dart';
import '../../../_datas/documents/contracts/contracts/contracts_data.dart';
import 'list_contracts_validity_icon.dart';

typedef ContractNavigationCallback = void Function(BuildContext context, ContractData contract);

class ContractsTableWidget extends StatelessWidget {
  final List<ContractData> listContractData;
  final ValidityBloc validityBloc;
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
    required this.validityBloc,
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

    final _ = listContractData.isEmpty;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 12),
          SimpleTableChanged<ContractData>(
            listData: sortedContracts,
            constraints: constraints,
            status: statusLabel,
            sortColumnIndex: sortColumnIndex,
            isAscending: isAscending,
            sortField: (d) => d.contractNumber ?? '',
            onSort: onSort,
            onTapItem: (contractData) => onTapItem(context, contractData),
            onDelete: onDelete,
            leadingCell: (data) => ContractValidityIcon(
              contract: data,
              validityBloc: validityBloc,
            ),
            columnTitles: const [
              'CONTRATO', 'OBRA', 'REGIÃO', 'EMPRESA', 'Nº PROCESSO',
            ],
            columnWidths: [100, 130, 200, 110, 100, 200],
            columnTextAligns: List.filled(6, TextAlign.center),
            groupLabel: 'SERVIÇO:',
            //statusFilter: statusFilter,
            leadingCellTitle: 'VALIDADE',
            columnGetters: [
                  (d) => d.contractNumber ?? '',
                  (d) => d.summarySubjectContract ?? '',
                  (d) => d.regionOfState ?? '',
                  (d) => d.companyLeader ?? '',
                  (d) => d.contractNumberProcess ?? '',
            ],
            groupBy: (d) => d.contractServices ?? 'Sem serviço definido',
          ),
        ],
      ),
    );
  }
}

