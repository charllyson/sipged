import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_store.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/report/report_measurement_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_data.dart';

import 'package:sipged/_widgets/cards/chip/chip_card.dart';
import 'package:sipged/screens/modules/contracts/hiring/tab_bar_hiring_page.dart';

class GeneralDashboardList extends StatelessWidget {
  final List<ReportMeasurementData> currentFiltered;
  final int? selectedPointIndex;
  final String? selectedContractSummary;

  final List<AdjustmentMeasurementData> allAdjustments;
  final List<RevisionMeasurementData> allRevisions;

  const GeneralDashboardList({
    super.key,
    required this.currentFiltered,
    required this.selectedPointIndex,
    required this.selectedContractSummary,
    required this.allAdjustments,
    required this.allRevisions,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedPointIndex == null ||
        selectedPointIndex! >= currentFiltered.length ||
        selectedContractSummary == null) {
      return const SizedBox.shrink();
    }

    final selected = currentFiltered[selectedPointIndex!];
    final String? contractId = selected.contractId;
    final int? order = selected.order;

    double readAdjustmentValue() {
      if (contractId == null) return 0.0;

      AdjustmentMeasurementData item = allAdjustments.firstWhere(
            (e) => e.contractId == contractId && e.order != null && e.order == order,
        orElse: () => AdjustmentMeasurementData(),
      );

      if (item.contractId == null) {
        item = allAdjustments.firstWhere(
              (e) => e.contractId == contractId,
          orElse: () => AdjustmentMeasurementData(),
        );
      }
      return item.value ?? 0.0;
    }

    double readRevisionValue() {
      if (contractId == null) return 0.0;

      RevisionMeasurementData item = allRevisions.firstWhere(
            (e) => e.contractId == contractId && e.order != null && e.order == order,
        orElse: () => RevisionMeasurementData(),
      );

      if (item.contractId == null) {
        item = allRevisions.firstWhere(
              (e) => e.contractId == contractId,
          orElse: () => RevisionMeasurementData(),
        );
      }
      return item.value ?? 0.0;
    }

    final double valorReport = selected.value ?? 0.0;
    final double valorAdjustment = readAdjustmentValue();
    final double valorRevision = readRevisionValue();

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

                final store = context.read<ProcessStore>();
                final ProcessData? contrato = await store.getById(contractId);

                if (!context.mounted) return;
                if (contrato == null) return;

                store.select(contrato);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TabBarHiringPage(
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
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(Icons.description, color: Colors.blueAccent),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.5,
                        ),
                        child: Text(
                          selectedContractSummary!,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Chip(
                            label: Text(
                              'Número: ${order ?? selected.order ?? '-'}',
                            ),
                            avatar: const Icon(
                              Icons.onetwothree_rounded,
                              size: 18,
                            ),
                            backgroundColor: Colors.grey.shade100,
                          ),
                          ChipCard('Medição', valorReport, Icons.bar_chart),
                          ChipCard('Reajuste', valorAdjustment, Icons.trending_up),
                          ChipCard('Revisão', valorRevision, Icons.change_circle),
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