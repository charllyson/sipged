import 'package:flutter/material.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_style.dart';
import 'package:siged/_utils/formats/format_field.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_rules.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/screens/documents/contract/tab_bar_contract_page.dart';

class ListResumed extends StatelessWidget {
  final List<ContractData> contract;

  const ListResumed({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    if (contract.isEmpty) return const SizedBox();

    final contratosOrdenados = List<ContractData>.from(contract)
      ..sort((a, b) {
        final statusA = a.contractStatus?.toUpperCase() ?? '';
        final statusB = b.contractStatus?.toUpperCase() ?? '';
        final prioridadeA = ContractRules.priorityStatus[statusA] ?? 99;
        final prioridadeB = ContractRules.priorityStatus[statusB] ?? 99;

        if (prioridadeA != prioridadeB) {
          return prioridadeA.compareTo(prioridadeB);
        }

        return (a.summarySubjectContract ?? '').compareTo(b.summarySubjectContract ?? '');
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
                      builder: (context) => TabBarContractPage(
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
                            contrato.contractStatus ?? '',
                            style: TextStyle(
                              color: ContractStyle.statusColors[contrato.contractStatus?.toUpperCase()] ?? Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${contrato.contractNumber} - ${contrato.summarySubjectContract}',
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
