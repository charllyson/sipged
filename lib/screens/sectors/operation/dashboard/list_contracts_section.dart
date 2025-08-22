import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_datas/documents/contracts/contracts/contract_store.dart';
import 'package:sisged/_datas/documents/measurement/reports/report_measurement_data.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contract_data.dart';
import 'package:sisged/_widgets/chip/build_value_chip.dart';
import 'package:sisged/screens/documents/contract/tab_bar_contract_page.dart';

class ListContractsSection extends StatelessWidget {
  final List<ReportMeasurementData> currentFiltered;
  final int? selectedPointIndex;
  final String? selectedContractSummary;

  const ListContractsSection({
    super.key,
    required this.currentFiltered,
    required this.selectedPointIndex,
    required this.selectedContractSummary,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedPointIndex == null ||
        selectedPointIndex! >= currentFiltered.length ||
        selectedContractSummary == null) {
      return const SizedBox();
    }

    final selected = currentFiltered[selectedPointIndex!];

    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: () async {
                final contractId = selected.contractId;
                if (contractId == null) return;

                final store = context.read<ContractsStore>();

                // Busca com cache do store
                final ContractData? contrato = await store.getById(contractId);
                if (contrato == null) return;

                // Deixa o selecionado disponível para telas que leem do store
                store.select(contrato);

                // Navega. Se sua TabBarContractPage já lê do store, dá pra tirar o contractData aqui.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TabBarContractPage(
                      contractData: contrato,   // opcional se já migrou pro store
                      initialTabIndex: 4,
                    ),
                  ),
                );
              },
              child: Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      const Icon(Icons.description, color: Colors.blueAccent),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.5,
                        ),
                        child: Text(
                          selectedContractSummary!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          Chip(
                            label: Text('Número: ${selected.orderReportMeasurement}'),
                            avatar: const Icon(Icons.onetwothree_rounded, size: 18),
                            backgroundColor: Colors.grey.shade100,
                          ),
                          BuildValueChip('Medição',  selected.valueReportMeasurement ?? 0.0, Icons.bar_chart),
                          BuildValueChip('Reajuste', selected.valueAdjustmentMeasurement ?? 0.0, Icons.trending_up),
                          BuildValueChip('Revisão',  selected.valueRevisionMeasurement ?? 0.0, Icons.change_circle),

                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
