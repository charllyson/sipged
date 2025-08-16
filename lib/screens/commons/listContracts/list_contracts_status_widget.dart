import 'package:flutter/material.dart';
import 'package:sisged/_datas/system/user_data.dart';
import '../../../_blocs/documents/contracts/contracts/contracts_bloc.dart';
import '../../../_blocs/documents/contracts/validity/validity_bloc.dart';
import '../../../_datas/documents/contracts/contracts/contracts_data.dart';
import 'list_contracts_table_widget.dart';

class ContractStatusWidget extends StatelessWidget {
  final ContractsBloc contractsBloc;
  final ValidityBloc validityBloc;
  final UserData currentUser;
  final String statusLabel;
  final String statusFilter;
  final BoxConstraints constraints;
  final TextEditingController statusCtrl;
  final TextEditingController searchCtrl;
  final Map<String, List<ContractData>> cachedContracts;

  final int? sortColumnIndex;
  final bool isAscending;
  final void Function(int columnIndex, String Function(ContractData))? onSort;
  final VoidCallback? onRefresh;
  final ContractNavigationCallback? onTapItem;

  const ContractStatusWidget({
    super.key,
    required this.contractsBloc,
    required this.validityBloc,
    required this.currentUser,
    required this.statusLabel,
    required this.statusFilter,
    required this.constraints,
    required this.statusCtrl,
    required this.searchCtrl,
    required this.cachedContracts,
    this.sortColumnIndex,
    this.isAscending = true,
    this.onSort,
    this.onRefresh,
    this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final contratos = cachedContracts[statusFilter] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContractsTableWidget(
          listContractData: contratos,
          validityBloc: validityBloc,
          constraints: constraints,
          statusLabel: statusLabel,
          statusFilter: statusFilter,
          sortColumnIndex: sortColumnIndex,
          isAscending: isAscending,
          onSort: onSort ?? (int _, String Function(ContractData) __) {},
          onDelete: (item) {
            contractsBloc.deleteContract(item.id!);
            onRefresh?.call();
          },
          onTapItem: onTapItem!, // ✅ aqui é o ponto mais importante
        ),

      ],
    );
  }
}
