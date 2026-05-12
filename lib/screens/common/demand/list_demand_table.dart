import 'package:flutter/material.dart';

import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import '../alerts/alert_validity.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/5Edital/edital_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';

typedef ContractNavigationCallback = void Function(
    BuildContext context,
    ContractData contract,
    );

class ListDemandTable extends StatefulWidget {
  final List<ContractData> listContractData;
  final BoxConstraints constraints;

  final String statusLabel;
  final String statusFilter;

  final int? sortColumnIndex;
  final bool isAscending;

  final void Function(int, String Function(ContractData)) onSort;
  final Future<void> Function(ContractData) onDelete;
  final ContractNavigationCallback onTapItem;

  final Map<String, DfdData?> dfdByContractId;
  final Map<String, EditalData?> editalByContractId;
  final Map<String, PublicacaoExtratoData?> pubByContractId;

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
    required this.dfdByContractId,
    required this.editalByContractId,
    required this.pubByContractId,
  });

  @override
  State<ListDemandTable> createState() => _ListDemandTableState();
}

class _ListDemandTableState extends State<ListDemandTable> {
  ContractData? _selected;

  String? _contractId(ContractData contract) {
    final id = contract.id?.trim();

    if (id == null || id.isEmpty) {
      return null;
    }

    return id;
  }

  DfdData? _dfd(ContractData contract) {
    final id = _contractId(contract);

    if (id == null) return null;

    return widget.dfdByContractId[id];
  }

  EditalData? _edital(ContractData contract) {
    final id = _contractId(contract);

    if (id == null) return null;

    return widget.editalByContractId[id];
  }

  PublicacaoExtratoData? _pub(ContractData contract) {
    final id = _contractId(contract);

    if (id == null) return null;

    return widget.pubByContractId[id];
  }

  bool _isDfdLoading(ContractData contract) {
    final id = _contractId(contract);

    if (id == null) return false;

    return !widget.dfdByContractId.containsKey(id);
  }

  bool _isEditalLoading(ContractData contract) {
    final id = _contractId(contract);

    if (id == null) return false;

    return !widget.editalByContractId.containsKey(id);
  }

  bool _isPublicacaoLoading(ContractData contract) {
    final id = _contractId(contract);

    if (id == null) return false;

    return !widget.pubByContractId.containsKey(id);
  }

  String _txt(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) {
      return '—';
    }

    return text;
  }

  String _group(ContractData contract) {
    final natureza = _txt(_dfd(contract)?.naturezaIntervencao);

    return natureza == '—' ? 'Sem natureza definida' : natureza;
  }

  int? _safeSortColumnIndex() {
    final index = widget.sortColumnIndex;

    if (index == null) return null;
    if (index < 0 || index > 5) return null;

    return index;
  }

  Widget _safeAlertCell(ContractData data) {
    try {
      final id = _contractId(data);

      return Center(
        child: AlertValidity(
          contract: data,
          dfdData: id == null ? null : widget.dfdByContractId[id],
          publicacaoData: id == null ? null : widget.pubByContractId[id],
        ),
      );
    } catch (_) {
      return const Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 18,
        ),
      );
    }
  }

  String _safeNumeroContrato(ContractData data) {
    try {
      return _txt(_pub(data)?.numeroContrato);
    } catch (_) {
      return '—';
    }
  }

  String _safeDescricaoObjeto(ContractData data) {
    try {
      return _txt(_dfd(data)?.descricaoObjeto);
    } catch (_) {
      return '—';
    }
  }

  String _safeRegional(ContractData data) {
    try {
      return _txt(_dfd(data)?.regional);
    } catch (_) {
      return '—';
    }
  }

  String _safeVencedor(ContractData data) {
    try {
      return _txt(_edital(data)?.vencedor);
    } catch (_) {
      return '—';
    }
  }

  String _safeProcessoAdministrativo(ContractData data) {
    try {
      return _txt(_dfd(data)?.processoAdministrativo);
    } catch (_) {
      return '—';
    }
  }

  String _tableKey(ContractData data) {
    final id = _contractId(data);

    if (id != null) {
      return id;
    }

    return 'sem-id-${identityHashCode(data)}';
  }

  @override
  Widget build(BuildContext context) {
    final contracts = widget.listContractData;
    final safeSortIndex = _safeSortColumnIndex();

    return PagedTableChanged<ContractData>(
      listData: contracts,
      getKey: _tableKey,
      selectedKey: _selected == null ? null : _tableKey(_selected!),
      keepSelectionInternally: false,
      enableRowTapSelection: true,
      sortColumnIndex: safeSortIndex,
      sortAscending: widget.isAscending,
      minTableWidth: 1100,
      defaultColumnWidth: 160,
      actionsColumnWidth: 88,
      initialRowsPerPage: 25,
      rowsPerPageOptions: const [10, 25, 50, 100],
      enablePagination: false,
      onSort: (columnIndex, ascending, getter) {
        widget.onSort(columnIndex, getter);
      },
      onTapItem: (contractData) {
        setState(() {
          _selected = contractData;
        });

        widget.onTapItem(
          context,
          contractData,
        );
      },
      onDelete: (contractData) async {
        setState(() {
          _selected = contractData;
        });

        await widget.onDelete(contractData);
      },
      groupLabel: 'SERVIÇO',
      groupBy: _group,
      columns: [
        PagedColum<ContractData>(
          title: 'ALERTAS',
          width: 100,
          maxWidth: 100,
          textAlign: TextAlign.center,
          cellBuilder: (data) => _safeAlertCell(data),
        ),
        PagedColum<ContractData>(
          title: 'CONTRATO',
          width: 110,
          maxWidth: 110,
          textAlign: TextAlign.center,
          getter: _safeNumeroContrato,
          loadingWhen: _isPublicacaoLoading,
        ),
        PagedColum<ContractData>(
          title: 'OBRA',
          width: 300,
          maxWidth: 300,
          textAlign: TextAlign.left,
          getter: _safeDescricaoObjeto,
          loadingWhen: _isDfdLoading,
        ),
        PagedColum<ContractData>(
          title: 'REGIÃO',
          width: 150,
          maxWidth: 150,
          textAlign: TextAlign.center,
          getter: _safeRegional,
          loadingWhen: _isDfdLoading,
        ),
        PagedColum<ContractData>(
          title: 'EMPRESA (LÍDER)',
          width: 160,
          maxWidth: 160,
          textAlign: TextAlign.center,
          getter: _safeVencedor,
          loadingWhen: _isEditalLoading,
        ),
        PagedColum<ContractData>(
          title: 'Nº PROCESSO',
          width: 200,
          maxWidth: 200,
          textAlign: TextAlign.center,
          getter: _safeProcessoAdministrativo,
          loadingWhen: _isDfdLoading,
        ),
      ],
    );
  }
}