// lib/screens/commons/listContracts/list_resumed.dart

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Progress/progress_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/5Edital/edital_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/5Edital/edital_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';

import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_style.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/screens/modules/contracts/hiring/tab_bar_hiring_page.dart';

class ListResumed extends StatefulWidget {
  final List<ContractData> contract;
  final String tenantId;

  const ListResumed({
    super.key,
    required this.contract,
    required this.tenantId,
  });

  @override
  State<ListResumed> createState() => _ListResumedState();
}

class _ListResumedState extends State<ListResumed> {
  bool _loading = true;
  String? _error;

  int _loadSeq = 0;

  late DfdCubit _dfdCubit;
  late EditalCubit _editalCubit;
  late PublicacaoExtratoCubit _pubCubit;

  String _currentTenantId = '';

  final Map<String, DfdData?> _dfdByContractId = {};
  final Map<String, EditalData?> _editalByContractId = {};
  final Map<String, PublicacaoExtratoData?> _pubByContractId = {};

  @override
  void initState() {
    super.initState();

    _currentTenantId = _validateTenantId(widget.tenantId);

    _dfdCubit = DfdCubit(tenantId: _currentTenantId);
    _editalCubit = EditalCubit(tenantId: _currentTenantId);
    _pubCubit = PublicacaoExtratoCubit(tenantId: _currentTenantId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadAllData());
    });
  }

  @override
  void didUpdateWidget(covariant ListResumed oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldTenantId = oldWidget.tenantId.trim();
    final newTenantId = widget.tenantId.trim();

    final tenantChanged = oldTenantId != newTenantId;

    final oldIds = _extractValidContractIds(oldWidget.contract);
    final newIds = _extractValidContractIds(widget.contract);

    final contractsChanged =
        oldIds.length != newIds.length || !oldIds.containsAll(newIds);

    if (tenantChanged) {
      _disposeInternalCubits();

      _currentTenantId = _validateTenantId(newTenantId);

      _dfdCubit = DfdCubit(tenantId: _currentTenantId);
      _editalCubit = EditalCubit(tenantId: _currentTenantId);
      _pubCubit = PublicacaoExtratoCubit(tenantId: _currentTenantId);

      _dfdByContractId.clear();
      _editalByContractId.clear();
      _pubByContractId.clear();
    }

    if (tenantChanged || contractsChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_loadAllData());
      });
    }
  }

  @override
  void dispose() {
    _disposeInternalCubits();
    super.dispose();
  }

  void _disposeInternalCubits() {
    _dfdCubit.close();
    _editalCubit.close();
    _pubCubit.close();
  }

  String _validateTenantId(String tenantId) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId é obrigatório para ListResumed.');
    }

    return cleanTenantId;
  }

  Set<String> _extractValidContractIds(List<ContractData> contracts) {
    return contracts
        .map((contract) => contract.id?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;

    final seq = ++_loadSeq;

    setState(() {
      _loading = true;
      _error = null;
    });

    final ids = _extractValidContractIds(widget.contract).toList(
      growable: false,
    );

    if (ids.isEmpty) {
      if (!mounted || seq != _loadSeq) return;

      setState(() {
        _dfdByContractId.clear();
        _editalByContractId.clear();
        _pubByContractId.clear();
        _loading = false;
      });

      return;
    }

    try {
      final results = await Future.wait<Object?>([
        _dfdCubit.getSummaryForContracts(ids),
        _editalCubit.getSummaryForContracts(ids),
        _pubCubit.getSummaryForContracts(ids),
      ]);

      final dfdResult = results[0] as Map<String, DfdData?>;
      final editalResult = results[1] as Map<String, EditalData?>;
      final pubResult = results[2] as Map<String, PublicacaoExtratoData?>;

      if (!mounted || seq != _loadSeq) return;

      setState(() {
        _dfdByContractId
          ..clear()
          ..addAll(dfdResult);

        _editalByContractId
          ..clear()
          ..addAll(editalResult);

        _pubByContractId
          ..clear()
          ..addAll(pubResult);

        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || seq != _loadSeq) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Color _statusColor(String status) {
    final key = status.trim().toUpperCase();

    if (key.isEmpty) {
      return Colors.grey.shade700;
    }

    return GeneralDashboardStyle.statusColors[key] ?? Colors.black;
  }

  String _statusFor(ContractData contrato) {
    final id = contrato.id?.trim();

    if (id == null || id.isEmpty) {
      return '';
    }

    final dfd = _dfdByContractId[id];
    return (dfd?.statusDemanda ?? '').trim();
  }

  String _numeroContratoFor(ContractData contrato) {
    final id = contrato.id?.trim();

    if (id == null || id.isEmpty) {
      return '—';
    }

    final pub = _pubByContractId[id];
    final numero = (pub?.numeroContrato ?? '').trim();

    return numero.isEmpty ? '—' : numero;
  }

  String _summaryFor(ContractData contrato) {
    final id = contrato.id?.trim();

    if (id == null || id.isEmpty) {
      return '—';
    }

    final dfd = _dfdByContractId[id];
    final descricao = (dfd?.descricaoObjeto ?? '').trim();

    return descricao.isEmpty ? '—' : descricao;
  }

  String _winnerFor(ContractData contrato) {
    final id = contrato.id?.trim();

    if (id == null || id.isEmpty) {
      return '—';
    }

    final edital = _editalByContractId[id];
    final vencedor = (edital?.vencedor ?? '').trim();

    return vencedor.isEmpty ? '—' : vencedor;
  }

  String _valorDemandaLabelFor(ContractData contrato) {
    final id = contrato.id?.trim();

    if (id == null || id.isEmpty) {
      return '—';
    }

    final dfd = _dfdByContractId[id];
    final valor = dfd?.valorDemanda;

    if (valor == null) {
      return '—';
    }

    return SipGedFormatMoney.doubleToText(valor);
  }

  List<ContractData> _orderedContracts() {
    final list = List<ContractData>.from(widget.contract);

    if (_loading) {
      return list;
    }

    list.sort((a, b) {
      final sa = _statusFor(a).toUpperCase();
      final sb = _statusFor(b).toUpperCase();

      final pa = ProgressData.priorityStatus[sa] ?? 99;
      final pb = ProgressData.priorityStatus[sb] ?? 99;

      if (pa != pb) {
        return pa.compareTo(pb);
      }

      final an = _summaryFor(a).toUpperCase();
      final bn = _summaryFor(b).toUpperCase();

      return an.compareTo(bn);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contract.isEmpty) {
      return const SizedBox.shrink();
    }

    final contratosOrdenados = _orderedContracts();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;

          return Card(
            color: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    _buildErrorBox(_error!),
                  ],
                  const SizedBox(height: 12),
                  ...contratosOrdenados.map((contrato) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildContractCard(
                        context: context,
                        contrato: contrato,
                        width: availableWidth,
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.filter_alt_rounded,
          size: 18,
          color: Color(0xFF334155),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Contratos filtrados (${widget.contract.length})',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        if (_loading) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          const Text(
            'Carregando detalhes...',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ] else
          IconButton(
            tooltip: 'Recarregar dados da lista',
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _loadAllData,
          ),
      ],
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.red.shade100,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.red.shade800,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildContractCard({
    required BuildContext context,
    required ContractData contrato,
    required double width,
  }) {
    final status = _statusFor(contrato);
    final statusColor = _statusColor(status);
    final vencedor = _winnerFor(contrato);
    final numeroContrato = _numeroContratoFor(contrato);
    final resumoObjeto = _summaryFor(contrato);
    final valorDemandaLabel = _valorDemandaLabelFor(contrato);

    final isDetailEmpty = status.isEmpty &&
        numeroContrato == '—' &&
        resumoObjeto == '—' &&
        vencedor == '—' &&
        valorDemandaLabel == '—';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TabBarHiringPage(
              contractData: contrato,
              initialTabIndex: 0,
            ),
          ),
        );
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (status.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else if (_loading) ...[
              const Text(
                'Status carregando...',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              '$numeroContrato - $resumoObjeto',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vencedor: $vencedor',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Valor da demanda: $valorDemandaLabel',
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!_loading && isDetailEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Dados auxiliares não encontrados para este contrato.',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}