import 'package:flutter/material.dart';

import 'package:siged/_widgets/table/simple/simple_table_changed.dart';
import 'package:siged/_blocs/_process/process_data.dart';

import '../../alerts/alert_validity.dart';

// Somente os DATA (sem BLoCs aqui)
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_blocs/process/hiring/5Edital/edital_data.dart';
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_data.dart';

typedef ContractNavigationCallback = void Function(
    BuildContext context,
    ProcessData contract,
    );

class ListDemandTable extends StatefulWidget {
  final List<ProcessData> listContractData;
  final BoxConstraints constraints;

  /// Rótulo visual exibido no painel (ex.: “EM ANDAMENTO”)
  final String statusLabel;

  /// Chave de filtro (ex.: “EM ANDAMENTO”) — legado, já aplicado a montante
  final String statusFilter;

  final int? sortColumnIndex;
  final bool isAscending;

  final void Function(int, String Function(ProcessData)) onSort;
  final Future<void> Function(ProcessData) onDelete;
  final ContractNavigationCallback onTapItem;

  // 🔥 caches já carregados pela ListDemandPage
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
  String _id(ProcessData c) => c.id ?? '';

  DfdData? _dfd(ProcessData c) {
    final id = c.id;
    if (id == null) return null;
    return widget.dfdByContractId[id];
  }

  EditalData? _edital(ProcessData c) {
    final id = c.id;
    if (id == null) return null;
    return widget.editalByContractId[id];
  }

  PublicacaoExtratoData? _pub(ProcessData c) {
    final id = c.id;
    if (id == null) return null;
    return widget.pubByContractId[id];
  }

  /// Normaliza texto: se vier nulo ou vazio -> "—"
  String _txt(String? v) {
    final s = (v ?? '').trim();
    return s.isEmpty ? '—' : s;
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Nada de IO aqui. Tabela só lê caches prontos.

    // Ordena por nome da obra (descricaoObjeto do DFD)
    final sortedContracts = List<ProcessData>.from(widget.listContractData)
      ..sort((a, b) {
        final an = _txt(_dfd(a)?.descricaoObjeto).toUpperCase();
        final bn = _txt(_dfd(b)?.descricaoObjeto).toUpperCase();
        return an.compareTo(bn);
      });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 12),
          SimpleTableChanged<ProcessData>(
            listData: sortedContracts,
            constraints: widget.constraints,
            sortColumnIndex: widget.sortColumnIndex,
            isAscending: widget.isAscending,

            // Ordenação base (pelo número do contrato mostrado)
            sortField: (d) => _txt(_pub(d)?.numeroContrato),
            onSort: widget.onSort,

            onTapItem: (contractData) =>
                widget.onTapItem(context, contractData),
            onDelete: widget.onDelete,

            // ========== COLUNA EXTRA (“ALERTAS”) ==========
            leadingCellTitle: 'ALERTAS',
            leadingCell: (data) => AlertValidity(contract: data),

            // ========== COLUNAS VISUAIS ==========
            columnTitles: const [
              'CONTRATO',
              'OBRA',
              'REGIÃO',
              'EMPRESA (LÍDER)',
              'Nº PROCESSO',
            ],

            columnGetters: [
              // CONTRATO -> PublicacaoExtratoData.numeroContrato
                  (d) => _txt(_pub(d)?.numeroContrato),

              // OBRA -> DfdData.descricaoObjeto
                  (d) => _txt(_dfd(d)?.descricaoObjeto),

              // REGIÃO -> DfdData.regional
                  (d) => _txt(_dfd(d)?.regional),

              // EMPRESA (LÍDER) -> EditalData.vencedor
                  (d) => _txt(_edital(d)?.vencedor),

              // Nº PROCESSO -> DfdData.processoAdministrativo
                  (d) => _txt(_dfd(d)?.processoAdministrativo),
            ],

            // Larguras: 5 colunas + leading + delete
            columnWidths: const [
              120, // ALERTAS
              130, // CONTRATO
              260, // OBRA
              110, // REGIÃO
              200, // EMPRESA (vencedor)
              170, // Nº PROCESSO
              100, // delete
            ],

            // Alinhamento: somente para colunas de dados
            columnTextAligns: const [
              TextAlign.center, // CONTRATO
              TextAlign.left,   // OBRA
              TextAlign.center, // REGIÃO
              TextAlign.center, // EMPRESA
              TextAlign.center, // Nº PROCESSO
            ],

            // ========== AGRUPAMENTO ==========
            groupLabel: 'SERVIÇO',
            groupBy: (d) {
              final n = _txt(_dfd(d)?.naturezaIntervencao);
              return (n.isEmpty || n == '—')
                  ? 'Sem natureza definida'
                  : n;
            },
          ),
        ],
      ),
    );
  }
}
