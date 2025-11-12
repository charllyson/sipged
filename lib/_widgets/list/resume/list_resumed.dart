// lib/screens/commons/listContracts/list_resumed.dart
import 'package:flutter/material.dart';
import 'package:siged/_blocs/panels/overview-dashboard/demands_dashboard_overview_style.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_utils/formats/format_field.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/screens/process/hiring/tab_bar_hiring_page.dart';

class ListResumed extends StatelessWidget {
  final List<ProcessData> contract;

  /// 🆕 Status do DFD por contrato (contractId -> status)
  /// Ex.: {'abc123': 'EM ANDAMENTO', 'def456': 'CONCLUÍDO'}
  final Map<String, String>? dfdStatusByContractId;

  const ListResumed({
    super.key,
    required this.contract,
    this.dfdStatusByContractId,
  });

  String _statusFor(ProcessData c) {
    final id = c.id ?? '';
    if (id.isEmpty) return '';
    final s = dfdStatusByContractId?[id];
    return (s ?? '').trim();
  }

  Color _statusColor(String status) {
    final key = status.toUpperCase();
    return DemandsDashboardOverviewStyle.statusColors[key] ?? Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    if (contract.isEmpty) return const SizedBox();

    final contratosOrdenados = List<ProcessData>.from(contract)
      ..sort((a, b) {
        final sa = _statusFor(a).toUpperCase();
        final sb = _statusFor(b).toUpperCase();
        final pa = DfdData.priorityStatus[sa] ?? 99;
        final pb = DfdData.priorityStatus[sb] ?? 99;

        if (pa != pb) return pa.compareTo(pb);
        final an = (a.summarySubject ?? '').toUpperCase();
        final bn = (b.summarySubject ?? '').toUpperCase();
        return an.compareTo(bn);
      });

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
              final statusDfd = _statusFor(contrato);
              final statusColor = _statusColor(statusDfd);

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
                      if (statusDfd.isNotEmpty) ...[
                        Row(
                          children: [
                            Text(
                              statusDfd,
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
                        '${contrato.contractNumber ?? '—'} - ${contrato.summarySubject ?? '—'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Empresa: ${contrato.companyLeader ?? '—'}'),
                      const SizedBox(height: 4),
                      Text('Contratado: ${priceToString(contrato.initialValueContract)}'),
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
