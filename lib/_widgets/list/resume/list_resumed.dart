import 'package:flutter/material.dart';
import 'package:siged/_blocs/panels/overview-dashboard/demands_dashboard_overview_style.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_utils/formats/format_field.dart';

import 'package:siged/_blocs/process/hiring/5Edital/company_data.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/screens/process/hiring/tab_bar_hiring_page.dart';

class ListResumed extends StatelessWidget {
  final List<ProcessData> contract;

  const ListResumed({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    if (contract.isEmpty) return const SizedBox();

    final contratosOrdenados = List<ProcessData>.from(contract)
      ..sort((a, b) {
        final statusA = a.status?.toUpperCase() ?? '';
        final statusB = b.status?.toUpperCase() ?? '';
        final prioridadeA = DfdData.priorityStatus[statusA] ?? 99;
        final prioridadeB = DfdData.priorityStatus[statusB] ?? 99;

        if (prioridadeA != prioridadeB) {
          return prioridadeA.compareTo(prioridadeB);
        }

        return (a.summarySubject ?? '').compareTo(b.summarySubject ?? '');
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
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TabBarHiringPage(
                        contractData: contrato,
                        initialTabIndex: 0, // Abre direto na aba de Medições
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
                      Row(
                        children: [
                          Text(
                            contrato.status ?? '',
                            style: TextStyle(
                              color: DemandsDashboardOverviewStyle.statusColors[contrato.status?.toUpperCase()] ?? Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${contrato.contractNumber} - ${contrato.summarySubject}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Empresa: ${contrato.companyLeader ?? '---'}'),
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
