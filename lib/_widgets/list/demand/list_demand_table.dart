// lib/screens/commons/listContracts/list_demand_table.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/table/simple/simple_table_changed.dart';
import 'package:siged/_blocs/_process/process_data.dart';

import '../../alerts/alert_validity.dart';

typedef ContractNavigationCallback = void Function(
    BuildContext context,
    ProcessData contract,
    );

class ListDemandTable extends StatelessWidget {
  final List<ProcessData> listContractData;
  final BoxConstraints constraints;
  final String statusLabel;   // apenas rótulo visual do grupo
  final String statusFilter;  // chave do grupo (status do DFD já aplicado “a montante”)
  final int? sortColumnIndex;
  final bool isAscending;
  final void Function(int, String Function(ProcessData)) onSort;
  final void Function(ProcessData) onDelete;
  final ContractNavigationCallback onTapItem;

  // Mapas opcionais (contractId -> valor vindo do DFD)
  final Map<String, String>? regionByContractId;        // REGIÃO do DFD
  final Map<String, String>? processNumberByContractId; // Nº PROCESSO do DFD

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
    this.regionByContractId,
    this.processNumberByContractId,
  });

  String _regionalFor(ProcessData c) {
    final id = c.id ?? '';
    if (id.isEmpty) return '—';
    final v = regionByContractId?[id];
    if (v == null || v.trim().isEmpty) return '—';
    return v.trim();
  }

  String _processNumberFor(ProcessData c) {
    // 🔒 Somente DFD. Sem fallback para campos antigos do ProcessData.
    final id = c.id ?? '';
    if (id.isEmpty) return '—';
    final v = processNumberByContractId?[id];
    if (v == null || v.trim().isEmpty) return '—';
    return v.trim();
  }

  @override
  Widget build(BuildContext context) {
    // Como os itens já chegam agrupados por status do DFD,
    // não precisamos ordenar por status aqui. Mantemos um sort simples por OBRA.
    final sortedContracts = List<ProcessData>.from(listContractData)
      ..sort((a, b) {
        final an = (a.summarySubject ?? '').toUpperCase();
        final bn = (b.summarySubject ?? '').toUpperCase();
        return an.compareTo(bn);
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
            // A coluna “CONTRATO” pode ser reordenada pelo cabeçalho via onSort
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
                  (d) => _regionalFor(d),      // vem do DFD (mapa)
                  (d) => d.companyLeader ?? '',
                  (d) => _processNumberFor(d), // vem do DFD (mapa) — sem fallback legado
            ],

            // ⚠️ 5 (dados) + 1 (leading) + 1 (delete) = 7 larguras
            columnWidths: const [
              120, // leading: ALERTAS
              130, // CONTRATO
              260, // OBRA
              100, // REGIÃO
              200, // EMPRESA
              190, // Nº PROCESSO
              100, // delete (ícone)
            ],

            // ⚠️ Um alinhamento por título (apenas dados): 5 itens
            columnTextAligns: const [
              TextAlign.center, // CONTRATO
              TextAlign.left,   // OBRA
              TextAlign.center, // REGIÃO
              TextAlign.center, // EMPRESA
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
