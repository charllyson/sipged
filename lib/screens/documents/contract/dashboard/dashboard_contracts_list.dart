import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_store.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/documents/measurement/adjustment/adjustment_measurement_data.dart';
import 'package:siged/_blocs/documents/measurement/adjustment/adjustment_measurement_store.dart';

// REPORT (lista base do gráfico)
import 'package:siged/_blocs/documents/measurement/report/report_measurement_data.dart';

// ADJUSTMENT / REVISION (novas stores separadas)
import 'package:siged/_blocs/documents/measurement/revision/revision_measurement_data.dart';
import 'package:siged/_blocs/documents/measurement/revision/revision_measurement_store.dart';

import 'package:siged/_widgets/chip/build_value_chip.dart';
import 'package:siged/screens/documents/contract/tab_bar_contract_page.dart';

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
    final contractId = selected.contractId;
    final measurementId = selected.id;

    // Lê as stores separadas
    final adjStore = context.watch<AdjustmentsMeasurementStore>();
    final revStore = context.watch<RevisionsMeasurementStore>();

    // Busca valores no cache das stores
    double _readAdjustment() {
      if (contractId == null || measurementId == null) return 0.0;
      final entry = adjStore.all.firstWhere(
            (e) => e.measurementId == measurementId,
        orElse: () => AdjustmentEntry(measurementId: '', order: 0, data: AdjustmentMeasurementData()),
      );
      if (entry.measurementId.isEmpty) {
        // dispara carregamento assíncrono (lazy) sem bloquear o build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          adjStore.getById(contractId: contractId, measurementId: measurementId);
        });
        return 0.0;
      }
      return entry.data.value ?? 0.0;
    }

    double _readRevision() {
      if (contractId == null || measurementId == null) return 0.0;
      final entry = revStore.all.firstWhere(
            (e) => e.measurementId == measurementId,
        orElse: () => RevisionEntry(measurementId: '', order: 0, data: RevisionMeasurementData()),
      );
      if (entry.measurementId.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          revStore.getById(contractId: contractId, measurementId: measurementId);
        });
        return 0.0;
      }
      return entry.data.value ?? 0.0;
    }

    final valorReport     = selected.value ?? 0.0; // do próprio ReportMeasurementData
    final valorAdjustment = _readAdjustment();
    final valorRevision   = _readRevision();

    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: () async {
                if (contractId == null) return;

                final store = context.read<ContractsStore>();

                // Busca com cache do store
                final ContractData? contrato = await store.getById(contractId);
                if (contrato == null) return;

                store.select(contrato);

                // Navega (se TabBarContractPage já lê do store, 'contractData' é opcional)
                // Troque a aba inicial conforme sua UI (4 era a aba de medições antes)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TabBarContractPage(
                      contractData: contrato,
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
                            label: Text('Número: ${selected.order}'),
                            avatar: const Icon(Icons.onetwothree_rounded, size: 18),
                            backgroundColor: Colors.grey.shade100,
                          ),
                          BuildValueChip('Medição',  valorReport,     Icons.bar_chart),
                          BuildValueChip('Reajuste', valorAdjustment, Icons.trending_up),
                          BuildValueChip('Revisão',  valorRevision,   Icons.change_circle),
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