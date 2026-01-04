// lib/screens/commons/listContracts/list_resumed.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/panels/general_dashboard/general_dashboard_style.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_cubit.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/screens/process/hiring/tab_bar_hiring_page.dart';

// DFD
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';

// Edital
import 'package:siged/_blocs/process/hiring/5Edital/edital_cubit.dart';
import 'package:siged/_blocs/process/hiring/5Edital/edital_data.dart';

// Publicação
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_cubit.dart';
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_data.dart';

class ListResumed extends StatefulWidget {
  final List<ProcessData> contract;

  const ListResumed({
    super.key,
    required this.contract,
  });

  @override
  State<ListResumed> createState() => _ListResumedState();
}

class _ListResumedState extends State<ListResumed> {
  bool _loading = true;

  /// cache por contrato
  final Map<String, DfdData?> _dfdByContractId = {};
  final Map<String, EditalData?> _editalByContractId = {};
  final Map<String, PublicacaoExtratoData?> _pubByContractId = {};

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void didUpdateWidget(covariant ListResumed oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se a lista de contratos mudar (por id), recarrega
    final oldIds = oldWidget.contract.map((c) => c.id).toSet();
    final newIds = widget.contract.map((c) => c.id).toSet();
    if (oldIds.length != newIds.length || !oldIds.containsAll(newIds)) {
      _loadAllData();
    }
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;

    setState(() => _loading = true);

    final dfdBloc = context.read<DfdCubit>();
    final editalBloc = context.read<EditalCubit>();
    final pubBloc = context.read<PublicacaoExtratoCubit>();

    final Map<String, DfdData?> dfdTmp = {};
    final Map<String, EditalData?> editalTmp = {};
    final Map<String, PublicacaoExtratoData?> pubTmp = {};

    // Carrega DFD + Edital + Publicação para cada contrato (best effort)
    for (final c in widget.contract) {
      final id = c.id;
      if (id == null) continue;

      try {
        dfdTmp[id] = await dfdBloc.getDataForContract(id);
      } catch (_) {
        dfdTmp[id] = null;
      }

      try {
        editalTmp[id] = await editalBloc.getDataForContract(id);
      } catch (_) {
        editalTmp[id] = null;
      }

      try {
        pubTmp[id] = await pubBloc.getDataForContract(id);
      } catch (_) {
        pubTmp[id] = null;
      }
    }

    if (!mounted) return;
    setState(() {
      _dfdByContractId
        ..clear()
        ..addAll(dfdTmp);
      _editalByContractId
        ..clear()
        ..addAll(editalTmp);
      _pubByContractId
        ..clear()
        ..addAll(pubTmp);
      _loading = false;
    });
  }

  Color _statusColor(String status) {
    final key = status.toUpperCase();
    return GeneralDashboardStyle.statusColors[key] ?? Colors.black;
  }

  // --------- Helpers de leitura dos dados “fonte” ----------

  /// Status vem de DfdData.statusDemanda
  String _statusFor(ProcessData contrato) {
    final id = contrato.id;
    if (id == null) return '';
    final dfd = _dfdByContractId[id];
    final s = (dfd?.statusDemanda ?? '').trim();
    return s;
  }

  /// Número do contrato vem EXCLUSIVAMENTE de PublicacaoExtratoData.numeroContrato
  String _numeroContratoFor(ProcessData contrato) {
    final id = contrato.id;
    if (id == null) return '—';

    final pub = _pubByContractId[id];
    final num = (pub?.numeroContrato ?? '').trim();
    return num.isEmpty ? '—' : num;
  }

  /// Resumo/objeto vem EXCLUSIVAMENTE de DfdData.descricaoObjeto
  String _summaryFor(ProcessData contrato) {
    final id = contrato.id;
    if (id == null) return '—';

    final dfd = _dfdByContractId[id];
    final desc = (dfd?.descricaoObjeto ?? '').trim();
    return desc.isEmpty ? '—' : desc;
  }

  /// Vencedor vem de EditalData.vencedor
  String _winnerFor(ProcessData contrato) {
    final id = contrato.id;
    if (id == null) {
      return '—';
    }

    final edital = _editalByContractId[id];
    final fromEdital = (edital?.vencedor ?? '').trim();

    if (fromEdital.isNotEmpty) {
      return fromEdital;
    }

    return '—';
  }

  /// Valor da demanda vem EXCLUSIVAMENTE de DfdData.valorDemanda
  /// Sem fallback para ProcessData.
  String _valorDemandaLabelFor(ProcessData contrato) {
    final id = contrato.id;
    if (id == null) return '—';

    final dfd = _dfdByContractId[id];
    final v = dfd?.valorDemanda;

    if (v == null) return '—';
    return priceToString(v);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contract.isEmpty) return const SizedBox();

    final List<ProcessData> contratosOrdenados;

    if (_loading) {
      contratosOrdenados = List<ProcessData>.from(widget.contract);
    } else {
      contratosOrdenados = List<ProcessData>.from(widget.contract)
        ..sort((a, b) {
          final sa = _statusFor(a).toUpperCase();
          final sb = _statusFor(b).toUpperCase();
          final pa = HiringData.priorityStatus[sa] ?? 99;
          final pb = HiringData.priorityStatus[sb] ?? 99;

          if (pa != pb) return pa.compareTo(pb);

          final an = _summaryFor(a).toUpperCase();
          final bn = _summaryFor(b).toUpperCase();
          return an.compareTo(bn);
        });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Card(
        color: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: contratosOrdenados.map((contrato) {
              final status = _statusFor(contrato);
              final statusColor = _statusColor(status);
              final vencedor = _winnerFor(contrato);
              final numeroContrato = _numeroContratoFor(contrato);
              final resumoObjeto = _summaryFor(contrato);
              final valorDemandaLabel = _valorDemandaLabelFor(contrato);

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TabBarHiringPage(
                        contractData: contrato,
                        initialTabIndex: 0,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  width: MediaQuery.of(context).size.width - 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (status.isNotEmpty) ...[
                        Row(
                          children: [
                            Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        '$numeroContrato - $resumoObjeto',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Vencedor: $vencedor'),
                      const SizedBox(height: 4),
                      Text(
                        'Valor da demanda: $valorDemandaLabel',
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
