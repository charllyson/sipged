import 'package:flutter/material.dart';

import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import '../alerts/alert_validity.dart';

// Somente os DATA (sem BLoCs aqui)
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

  DfdData? _dfd(ContractData c) {
    final id = c.id;
    if (id == null) return null;
    return widget.dfdByContractId[id];
  }

  EditalData? _edital(ContractData c) {
    final id = c.id;
    if (id == null) return null;
    return widget.editalByContractId[id];
  }

  PublicacaoExtratoData? _pub(ContractData c) {
    final id = c.id;
    if (id == null) return null;
    return widget.pubByContractId[id];
  }

  String _txt(String? v) {
    final s = (v ?? '').trim();
    return s.isEmpty ? '—' : s;
  }

  String _group(ContractData d) {
    final n = _txt(_dfd(d)?.naturezaIntervencao);
    return (n.isEmpty || n == '—') ? 'Sem natureza definida' : n;
  }

  String? _selectedKey() => _selected?.id;

  int? _safeSortColumnIndex() {
    final i = widget.sortColumnIndex;
    if (i == null) return null;
    if (i < 0 || i > 5) return null;
    return i;
  }

  Widget _safeAlertCell(ContractData data) {
    try {
      return Center(
        child: AlertValidity(contract: data),
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

  String _safeNumeroContrato(ContractData d) {
    try {
      return _txt(_pub(d)?.numeroContrato);
    } catch (_) {
      return '—';
    }
  }

  String _safeDescricaoObjeto(ContractData d) {
    try {
      return _txt(_dfd(d)?.descricaoObjeto);
    } catch (_) {
      return '—';
    }
  }

  String _safeRegional(ContractData d) {
    try {
      return _txt(_dfd(d)?.regional);
    } catch (_) {
      return '—';
    }
  }

  String _safeVencedor(ContractData d) {
    try {
      return _txt(_edital(d)?.vencedor);
    } catch (_) {
      return '—';
    }
  }

  String _safeProcessoAdministrativo(ContractData d) {
    try {
      return _txt(_dfd(d)?.processoAdministrativo);
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final contracts = widget.listContractData;
    final safeSortIndex = _safeSortColumnIndex();

    return PagedTableChanged<ContractData>(
      listData: contracts,
      getKey: (d) => d.id ?? 'sem-id-${contracts.indexOf(d)}',
      selectedKey: _selectedKey(),
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
        setState(() => _selected = contractData);
        widget.onTapItem(context, contractData);
      },
      onDelete: (contractData) async {
        setState(() => _selected = contractData);
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
        ),
        PagedColum<ContractData>(
          title: 'OBRA',
          width: 300,
          maxWidth: 300,
          textAlign: TextAlign.left,
          getter: _safeDescricaoObjeto,
        ),
        PagedColum<ContractData>(
          title: 'REGIÃO',
          width: 150,
          maxWidth: 150,
          textAlign: TextAlign.center,
          getter: _safeRegional,
        ),
        PagedColum<ContractData>(
          title: 'EMPRESA (LÍDER)',
          width: 160,
          maxWidth: 160,
          textAlign: TextAlign.center,
          getter: _safeVencedor,
        ),
        PagedColum<ContractData>(
          title: 'Nº PROCESSO',
          width: 200,
          maxWidth: 200,
          textAlign: TextAlign.center,
          getter: _safeProcessoAdministrativo,
        ),
      ],
    );
  }
}